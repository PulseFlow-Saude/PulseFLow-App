import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import 'firebase_bootstrap.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications/notification_channels.dart';
import 'notifications/notification_builders.dart';
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

  // Notificações locais
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Verificador de solicitações de acesso
  final AccessRequestChecker _accessRequestChecker = AccessRequestChecker();

  @override
  Future<void> onInit() async {
    super.onInit();

         try {
           await _initializeLocalNotifications();
         } catch (e) {
           // Erro ao inicializar notificações locais
         }

         try {
           await _initializeFirebaseMessaging();
         } catch (e) {
           // Firebase não disponível
         }

    _accessRequestChecker.startPeriodicCheck();
  }

  /// Inicializar notificações locais
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
    await _requestPermissions();
  }

  /// Inicializar Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    if (!AppConfig.useFirebase) return;
    await FirebaseBootstrap.ensureInitialized();
    if (!FirebaseBootstrap.isReady) return;
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

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        await _waitForApnsToken();
      }

      await _obtainAndPersistFcmToken();
      _firebaseMessaging!.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
      });

      FirebaseMessaging.onMessage.listen(
        (message) => FirebaseHandlers.handleForegroundMessage(message, _localNotifications),
      );
      
      FirebaseMessaging.onMessageOpenedApp.listen(FirebaseHandlers.handleBackgroundMessage);

      RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        FirebaseHandlers.handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      _firebaseAvailable = false;
    }
  }

  Future<void> _obtainAndPersistFcmToken() async {
    if (_firebaseMessaging == null) return;
    final token = await _firebaseMessaging!.getToken();
    if (token == null || token.isEmpty) return;
    _fcmToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<void> _waitForApnsToken() async {
    if (_firebaseMessaging == null || !Platform.isIOS) return;
    for (var i = 0; i < 8; i++) {
      final apnsToken = await _firebaseMessaging!.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

         /// Solicitar permissões
         Future<void> _requestPermissions() async {
           final androidResult = await _localNotifications
               .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
               ?.requestNotificationsPermission();

           final iosResult = await _localNotifications
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
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

  /// Inscrever-se em tópico
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  /// Desinscrever-se de tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;
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
    _accessRequestChecker.dispose();
    super.onClose();
  }
}
