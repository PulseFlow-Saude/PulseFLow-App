import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Configurações de canais de notificação
class NotificationChannels {
  // IDs dos canais
  static const String doctorAccessChannelId = 'doctor_access_channel';
  static const String importantChannelId = 'important_channel';
  static const String medicationChannelId = 'medication_channel';
  static const String appointmentChannelId = 'appointment_channel';
  static const String generalChannelId = 'pulseflow_channel';

  /// Canal para solicitações de acesso médico (traduzido)
  static AndroidNotificationChannel get doctorAccessChannel =>
      AndroidNotificationChannel(
        doctorAccessChannelId,
        'notif_channel_doctor'.tr,
        description: 'notif_channel_doctor_desc'.tr,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

  /// Canal para notificações importantes (traduzido)
  static AndroidNotificationChannel get importantChannel =>
      AndroidNotificationChannel(
        importantChannelId,
        'notif_channel_important'.tr,
        description: 'notif_channel_important_desc'.tr,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

  /// Canal para lembretes de medicação (traduzido)
  static AndroidNotificationChannel get medicationChannel =>
      AndroidNotificationChannel(
        medicationChannelId,
        'notif_channel_medication'.tr,
        description: 'notif_channel_medication_desc'.tr,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Canal para lembretes de consultas (traduzido)
  static AndroidNotificationChannel get appointmentChannel =>
      AndroidNotificationChannel(
        appointmentChannelId,
        'notif_channel_appointment'.tr,
        description: 'notif_channel_appointment_desc'.tr,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Canal geral (traduzido)
  static AndroidNotificationChannel get generalChannel =>
      AndroidNotificationChannel(
        generalChannelId,
        'notif_channel_general'.tr,
        description: 'notif_channel_general_desc'.tr,
        importance: Importance.high,
        playSound: true,
      );

  /// Canais para uso em background isolate (sem Get disponível)
  static const AndroidNotificationChannel generalChannelForBackground =
      AndroidNotificationChannel(
    generalChannelId,
    'PulseFlow Notifications',
    description: 'Canal de notificações do PulseFlow',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Registrar todos os canais
  static Future<void> registerAllChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidImplementation = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(doctorAccessChannel);
      await androidImplementation.createNotificationChannel(importantChannel);
      await androidImplementation.createNotificationChannel(medicationChannel);
      await androidImplementation.createNotificationChannel(appointmentChannel);
      await androidImplementation.createNotificationChannel(generalChannel);
    }
  }
}

