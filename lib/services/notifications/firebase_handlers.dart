import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../firebase_options.dart';
import '../../routes/app_routes.dart';
import '../../utils/notification_content_i18n.dart';
import 'notification_channels.dart';
import 'notification_builders.dart';
import 'notification_settings_constants.dart';
import 'notification_storage.dart';

/// Handlers para mensagens Firebase
class FirebaseHandlers {
  static final List<_DedupeEntry> _recentForeground = [];
  static const _dedupeWindow = Duration(seconds: 4);

  static Map<String, dynamic> _stringKeyedData(RemoteMessage message) {
    return Map<String, dynamic>.from(message.data);
  }

  /// Handler para mensagens em foreground
  static Future<void> handleForegroundMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin localNotifications,
  ) async {
    if (_isDuplicateForegroundDelivery(message)) return;

    final data = _stringKeyedData(message);
    if (!await NotificationSettingsPrefs.shouldDeliverForFcmData(data)) {
      return;
    }

    final loc = NotificationContentI18n.effectiveLocaleCodeSync();
    final rawTitle = message.notification?.title ?? 'Oryon Health';
    final rawBody = message.notification?.body ?? 'notif_new_message'.tr;
    final localized =
        NotificationContentI18n.localize(rawTitle, rawBody, localeCode: loc);

    await _showLocalNotification(
      localNotifications,
      localized.title,
      localized.message,
      data,
    );
  }

  static bool _isDuplicateForegroundDelivery(RemoteMessage message) {
    final id = message.messageId ??
        '${message.sentTime?.millisecondsSinceEpoch}_${message.notification?.title}_${message.notification?.body}';
    final now = DateTime.now();
    _recentForeground.removeWhere(
      (e) => now.difference(e.at) > _dedupeWindow,
    );
    if (_recentForeground.any((e) => e.id == id)) return true;
    _recentForeground.add(_DedupeEntry(id, now));
    while (_recentForeground.length > 32) {
      _recentForeground.removeAt(0);
    }
    return false;
  }

  /// Handler para quando o app é aberto via notificação
  static void handleNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;

    if (p == 'appointment_reminder') {
      _deferNavigateToUpcomingAppointments();
      return;
    }

    try {
      final decoded = jsonDecode(p);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (_isAppointmentNotificationData(map)) {
          _deferNavigateToUpcomingAppointments();
        }
      }
    } catch (_) {
      // Payload antigo (ex.: Map.toString) ou texto livre
      if (p.contains('appointment') &&
          (p.contains('type:') || p.contains('"type"'))) {
        _deferNavigateToUpcomingAppointments();
      }
    }
  }

  static bool _isAppointmentNotificationData(Map<String, dynamic> data) {
    final t = (data['type'] ?? '').toString().toLowerCase();
    if (t == 'appointment' || t == 'appointments') return true;
    final link = (data['link'] ?? '').toString().toLowerCase();
    return link.contains('/appointments') || link.contains('/agendamentos');
  }

  static void _deferNavigateToUpcomingAppointments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        try {
          Get.toNamed(Routes.UPCOMING_APPOINTMENTS);
        } catch (_) {}
      });
    });
  }

  /// Abrir ecrã adequado quando o utilizador abre o app a partir de uma mensagem FCM.
  static void handleFcmNotificationOpened(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (_isAppointmentNotificationData(data)) {
      _deferNavigateToUpcomingAppointments();
    }
  }

  /// Exibir notificação local
  static Future<void> _showLocalNotification(
    FlutterLocalNotificationsPlugin plugin,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final stableKey = data['notificationId']?.toString() ?? '${title}_$body';
    final nid = stableKey.hashCode & 0x7fffffff;

    final payloadForTap = jsonEncode(
      Map<String, String>.fromEntries(
        data.entries.map(
          (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
        ),
      ),
    );

    await plugin.show(
      nid == 0 ? 1 : nid,
      title,
      body,
      NotificationBuilders.createGeneralNotification(),
      payload: payloadForTap,
    );

    final notificationId =
        data['notificationId']?.toString() ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';
    final type = data['type']?.toString() ?? 'updates';
    final link = data['link']?.toString();

    await NotificationStorage.addNotification(
      id: notificationId,
      title: title,
      message: body,
      type: type,
      link: link,
    );
  }
}

class _DedupeEntry {
  _DedupeEntry(this.id, this.at);
  final String id;
  final DateTime at;
}

/// Handler global para mensagens em background (app fechado)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.useFirebase) return;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') return;
  } catch (_) {
    return;
  }

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Criar o canal de notificação (usa fallback - Get não disponível em background)
  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(NotificationChannels.generalChannelForBackground);

  // Exibir notificação
  final data = Map<String, dynamic>.from(message.data);
  if (!await NotificationSettingsPrefs.shouldDeliverForFcmData(data)) {
    return;
  }

  final payloadForTap = jsonEncode(
    Map<String, String>.fromEntries(
      data.entries.map(
        (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
      ),
    ),
  );

  final loc = await NotificationContentI18n.effectiveLocaleCodeAsync();
  final rawTitle = message.notification?.title ?? 'Oryon Health';
  final rawBody = message.notification?.body ?? 'Nova mensagem';
  final localized =
      NotificationContentI18n.localize(rawTitle, rawBody, localeCode: loc);

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    localized.title,
    localized.message,
    NotificationBuilders.createBackgroundMessageNotification(),
    payload: payloadForTap,
  );

  final notificationId =
      data['notificationId']?.toString() ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';
  final type = data['type']?.toString() ?? 'updates';
  final link = data['link']?.toString();

  await NotificationStorage.addNotification(
    id: notificationId,
    title: localized.title,
    message: localized.message,
    type: type,
    link: link,
  );
}

