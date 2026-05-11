import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../firebase_options.dart';
import 'notification_channels.dart';
import 'notification_builders.dart';
import 'notification_storage.dart';

/// Handlers para mensagens Firebase
class FirebaseHandlers {
  static final List<_DedupeEntry> _recentForeground = [];
  static const _dedupeWindow = Duration(seconds: 4);

  /// Handler para mensagens em foreground
  static void handleForegroundMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin localNotifications,
  ) {
    if (_isDuplicateForegroundDelivery(message)) return;

    _showLocalNotification(
      localNotifications,
      message.notification?.title ?? 'Oryon Health',
      message.notification?.body ?? 'notif_new_message'.tr,
      message.data,
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

  /// Handler para mensagens em background (app minimizado)
  static void handleBackgroundMessage(RemoteMessage message) {
    // Mensagem recebida em background
  }

  /// Handler para quando o app é aberto via notificação
  static void handleNotificationTap(NotificationResponse response) {
    // Notificação foi tocada
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

    await plugin.show(
      nid == 0 ? 1 : nid,
      title,
      body,
      NotificationBuilders.createGeneralNotification(),
      payload: data.toString(),
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
  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    message.notification?.title ?? 'Oryon Health',
    message.notification?.body ?? 'Nova mensagem',
    NotificationBuilders.createBackgroundMessageNotification(),
    payload: message.data.toString(),
  );

  final notificationId =
      message.data['notificationId']?.toString() ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';
  final type = message.data['type']?.toString() ?? 'updates';
  final link = message.data['link']?.toString();

  await NotificationStorage.addNotification(
    id: notificationId,
    title: message.notification?.title ?? 'Oryon Health',
    message: message.notification?.body ?? 'Nova mensagem',
    type: type,
    link: link,
  );
}

