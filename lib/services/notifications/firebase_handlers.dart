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
  /// Handler para mensagens em foreground
  static void handleForegroundMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin localNotifications,
  ) {
    _showLocalNotification(
      localNotifications,
      message.notification?.title ?? 'Oryon Health',
      message.notification?.body ?? 'notif_new_message'.tr,
      message.data,
    );
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
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
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

