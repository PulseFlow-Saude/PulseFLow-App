import 'dart:async';

import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../config/app_config.dart';
import 'firebase_bootstrap.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications/notification_channels.dart';
import 'notifications/notification_builders.dart';
import 'notifications/notification_settings_constants.dart';
import 'notifications/firebase_handlers.dart';
import 'notifications/access_request_checker.dart';
import 'notifications/notification_storage.dart';

/// Serviço principal de notificações
class NotificationService extends GetxService {
  static NotificationService get instance => Get.find<NotificationService>();

  // Firebase
  FirebaseMessaging? _firebaseMessaging;
  bool _firebaseAvailable = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  bool _fcmListenersAttached = false;
  Future<void>? _fcmSetupInFlight;

  // Notificações locais
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Verificador de solicitações de acesso
  final AccessRequestChecker _accessRequestChecker = AccessRequestChecker();

  @override
  Future<void> onInit() async {
    super.onInit();
    // Não awaits longos aqui — evita jank quando o Isolate principal já está a pintar/login.
    unawaited(_bootstrapDeferredNotificationStack());
  }

  Future<void> _bootstrapDeferredNotificationStack() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    try {
      await _initializeLocalNotificationsCore();
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      await _requestPermissions();
    } catch (_) {}

    try {
      await _initializeFirebaseMessaging();
    } catch (_) {}

    try {
      await syncPreferenceTopicsWithPrefs();
    } catch (_) {}

    _accessRequestChecker.startPeriodicCheck();
  }

  /// Sem pedir permissão no próprio Darwin init (combinado com atrasos evita avalanche no arranque).
  Future<void> _initializeLocalNotificationsCore() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: FirebaseHandlers.handleNotificationTap,
    );

    await NotificationChannels.registerAllChannels(_localNotifications);
  }

  /// Inicializar Firebase Messaging (uma instalação em voo; chamadas paralelas aguardam a mesma).
  Future<void> _initializeFirebaseMessaging() async {
    if (!AppConfig.useFirebase) return;
    await FirebaseBootstrap.ensureInitialized();
    if (!FirebaseBootstrap.isReady) return;
    if (_fcmListenersAttached) return;

    if (_fcmSetupInFlight != null) {
      await _fcmSetupInFlight;
      if (_fcmListenersAttached) return;
      // Falha anterior: permite nova tentativa.
    }

    _fcmSetupInFlight = _attachFirebaseMessaging();
    try {
      await _fcmSetupInFlight;
    } finally {
      _fcmSetupInFlight = null;
    }
  }

  Future<void> _attachFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;

      await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // iOS em foreground: com alert=true o sistema **e** [onMessage] mostravam notificação = duplicado.
      // Só a notificação local (som/alerta vêm do [NotificationBuilders]).
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      await _onTokenRefreshSubscription?.cancel();
      _onTokenRefreshSubscription = _firebaseMessaging!.onTokenRefresh.listen(
        (newToken) async {
          try {
            _fcmToken = newToken;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fcm_token', newToken);
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('[Oryon][FCM] onTokenRefresh: $e\n$st');
            }
          }
        },
      );

      await _onMessageSubscription?.cancel();
      _onMessageSubscription = FirebaseMessaging.onMessage.listen(
        (message) {
          unawaited(
            FirebaseHandlers.handleForegroundMessage(
              message,
              _localNotifications,
            ),
          );
        },
      );

      await _onOpenedSubscription?.cancel();
      _onOpenedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(FirebaseHandlers.handleBackgroundMessage);

      final RemoteMessage? initialMessage =
          await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        FirebaseHandlers.handleBackgroundMessage(initialMessage);
      }

      _fcmListenersAttached = true;

      // APNS + getToken podem falhar ou demorar — nunca deixar exceção solta (unawaited).
      unawaited(_iosApnsAndFcmTokenWorkSafe());
    } catch (e) {
      _detachFcmListeners();
      _firebaseAvailable = false;
      _firebaseMessaging = null;
    }
  }

  void _detachFcmListeners() {
    _onMessageSubscription?.cancel();
    _onOpenedSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _onOpenedSubscription = null;
    _onTokenRefreshSubscription = null;
    _fcmListenersAttached = false;
  }

  Future<void> _iosApnsAndFcmTokenWorkSafe() async {
    try {
      await _iosApnsAndFcmTokenWork();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Oryon][FCM] _iosApnsAndFcmTokenWork: $e\n$st');
      }
    }
  }

  Future<void> _iosApnsAndFcmTokenWork() async {
    if (_firebaseMessaging == null) return;
    if (Platform.isIOS) {
      for (var i = 0; i < 8; i++) {
        final apnsToken = await _firebaseMessaging!.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    await _obtainAndPersistFcmToken();
    // Segunda tentativa após rede/APNS (erro "unknown" costuma ser timing no simulador).
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await _obtainAndPersistFcmToken();
    }
  }

  Future<void> _obtainAndPersistFcmToken() async {
    if (_firebaseMessaging == null) return;
    try {
      final token = await _firebaseMessaging!.getToken();
      if (token == null || token.isEmpty) return;
      _fcmToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Oryon][FCM] getToken FirebaseException: ${e.code} ${e.message}',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Oryon][FCM] getToken: $e\n$st');
      }
    }
  }

  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // ==================== NOTIFICAÇÕES PÚBLICAS ====================

  /// Exibir notificação de solicitação de acesso médico
  Future<void> showDoctorAccessRequestNotification({
    required String doctorName,
    required String specialty,
    String? requestId,
  }) async {
    final specialtyPart = specialty.isNotEmpty ? ' ($specialty)' : '';
    final bodyMsg = 'notif_access_body'.trParams({'name': doctorName, 'specialty': specialtyPart});
    final bodyFull = 'notif_access_body_full'.trParams({'name': doctorName, 'specialty': specialtyPart});
    final contentTitle = '🩺 ${'notif_access_title'.tr}';
    final viewRequest = 'notif_view_request'.tr;

    final notificationDetails = NotificationBuilders.createDoctorAccessNotification(
      doctorName: doctorName,
      specialty: specialty,
      contentTitle: contentTitle,
      bodyFull: bodyFull,
      viewRequestLabel: viewRequest,
    );

    // Id estável por pedido — nova chamada substitui a mesma notificação em vez de empilhar.
    final notifId = (requestId ?? doctorName + specialty).hashCode & 0x7fffffff;

    await _localNotifications.show(
      notifId == 0 ? 1 : notifId,
      '🩺 ${'notif_access_title_upper'.tr}',
      bodyMsg,
      notificationDetails,
      payload: 'doctor_access_request|$doctorName|$specialty',
    );

    await NotificationStorage.addNotification(
      id: requestId ?? 'doctor_access_${DateTime.now().millisecondsSinceEpoch}',
      title: 'notif_access_title'.tr,
      message: bodyMsg,
      type: 'pulse_key',
      link: 'pulse_key',
    );
  }

  /// Exibir notificação importante
  Future<void> showImportantNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      NotificationBuilders.createImportantNotification(),
      payload: data?.toString(),
    );
  }

  /// Agendar lembrete de medicação
  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      NotificationBuilders.createMedicationReminder(),
      payload: 'medication_reminder',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Agendar lembrete de consulta
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      NotificationBuilders.createAppointmentReminder(),
      payload: 'appointment_reminder',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ==================== GERENCIAMENTO ====================

  /// Cancelar notificação específica
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancelar lembretes de medicação
  Future<void> cancelMedicationReminders() async {}

  /// Cancelar lembretes de consultas
  Future<void> cancelAppointmentReminders() async {}

  /// Re-registra os canais com base no locale atual (chamar ao mudar idioma)
  Future<void> reregisterChannelsForCurrentLocale() async {
    await NotificationChannels.registerAllChannels(_localNotifications);
  }


  // ==================== FIREBASE ====================

  /// Obter token FCM
  Future<String?> getToken() async {
    if (!_firebaseAvailable || _firebaseMessaging == null) {
      return null;
    }
    try {
      return await _firebaseMessaging!.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Alinha subscrições FCM com [SharedPreferences] (alertas críticos, resumo diário, lembretes).
  ///
  /// Chamar após login ou arranque; o ecrã de definições continua a atualizar tópico a tópico.
  Future<void> syncPreferenceTopicsWithPrefs() async {
    if (!AppConfig.useFirebase) return;
    await _initializeFirebaseMessaging();
    final messaging = _firebaseMessaging;
    if (messaging == null || !_firebaseAvailable) return;

    final prefs = await SharedPreferences.getInstance();
    Future<void> row(String prefsKey, String topic, bool defaultOn) async {
      final on = prefs.getBool(prefsKey) ?? defaultOn;
      if (on) {
        await messaging.subscribeToTopic(topic);
      } else {
        await messaging.unsubscribeFromTopic(topic);
      }
    }

    await row(
      NotificationSettingsPrefs.criticalAlertsKey,
      NotificationSettingsPrefs.criticalTopic,
      true,
    );
    await row(
      NotificationSettingsPrefs.dailySummaryKey,
      NotificationSettingsPrefs.dailyTopic,
      true,
    );
    await row(
      NotificationSettingsPrefs.smartRemindersKey,
      NotificationSettingsPrefs.smartTopic,
      false,
    );
  }

  /// Inscrever-se em tópico
  Future<void> subscribeToTopic(String topic) async {
    if (!AppConfig.useFirebase) return;
    await _initializeFirebaseMessaging();
    if (_firebaseMessaging == null || !_firebaseAvailable) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  /// Desinscrever-se de tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!AppConfig.useFirebase) return;
    await _initializeFirebaseMessaging();
    if (_firebaseMessaging == null || !_firebaseAvailable) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
  }

  // ==================== TESTES ====================

  /// Testar notificação de acesso médico
  Future<void> testDoctorAccessNotification() async {
    await showDoctorAccessRequestNotification(
      doctorName: 'Dr. João Silva',
      specialty: 'Cardiologia',
      requestId: 'test_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Verificar solicitações manualmente
  Future<void> verificarSolicitacoesManual() async {
    await _accessRequestChecker.checkManually();
  }

  // ==================== HELPERS ====================

  dynamic _convertToTZDateTime(DateTime dateTime) {
    return dateTime;
  }

  @override
  void onClose() {
    _detachFcmListeners();
    _accessRequestChecker.dispose();
    super.onClose();
  }
}
