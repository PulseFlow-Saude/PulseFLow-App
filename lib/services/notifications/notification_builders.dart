import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'notification_channels.dart';

class NotificationBuilders {
  static const Color primaryColor = Color(0xFF00324A);
  static final Int64List defaultVibrationPattern = Int64List.fromList([0, 600, 200, 600]);

  static NotificationDetails createDoctorAccessNotification({
    required String doctorName,
    required String specialty,
    String? contentTitle,
    String? bodyFull,
    String? viewRequestLabel,
  }) {
    final title = contentTitle ?? 'Nova solicitação de acesso';
    final body = bodyFull ??
        'Dr(a). $doctorName ${specialty.isNotEmpty ? "($specialty)" : ""} solicitou acesso ao seu prontuário pela Chave Oryon. Gere o código no Oryon Health.';
    final actionLabel = viewRequestLabel ?? 'Ver Solicitação';

    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.doctorAccessChannelId,
      'notif_channel_doctor'.tr,
      channelDescription: 'notif_channel_doctor_desc'.tr,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: primaryColor,
      ledColor: primaryColor,
      ledOnMs: 800,
      ledOffMs: 400,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: 'Oryon Health',
      ),
      ticker: 'Oryon Health',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notification,
      vibrationPattern: defaultVibrationPattern,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          'pulseflow_open_request',
          actionLabel,
          showsUserInterface: true,
          cancelNotification: true,
        )
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      threadIdentifier: 'doctor_access',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static NotificationDetails createImportantNotification() {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.importantChannelId,
      'notif_channel_important'.tr,
      channelDescription: 'notif_channel_important_desc'.tr,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: primaryColor,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'Oryon Health',
      audioAttributesUsage: AudioAttributesUsage.notification,
      vibrationPattern: defaultVibrationPattern,
      autoCancel: true,
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static NotificationDetails createMedicationReminder() {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.medicationChannelId,
      'notif_channel_medication'.tr,
      channelDescription: 'notif_channel_medication_desc'.tr,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Oryon Health',
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: defaultVibrationPattern,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static NotificationDetails createAppointmentReminder() {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.appointmentChannelId,
      'notif_channel_appointment'.tr,
      channelDescription: 'notif_channel_appointment_desc'.tr,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.event,
      visibility: NotificationVisibility.public,
      ticker: 'Oryon Health',
      vibrationPattern: defaultVibrationPattern,
      audioAttributesUsage: AudioAttributesUsage.notification,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static NotificationDetails createGeneralNotification() {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.generalChannelId,
      'notif_channel_general'.tr,
      channelDescription: 'notif_channel_general_desc'.tr,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: 'Oryon Health',
      vibrationPattern: defaultVibrationPattern,
      icon: '@mipmap/ic_launcher',
      audioAttributesUsage: AudioAttributesUsage.notification,
      autoCancel: true,
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Para uso em background isolate (Get não disponível)
  static NotificationDetails createBackgroundMessageNotification() {
    const channelName = 'Oryon Health Notifications';
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.generalChannelId,
      channelName,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: 'Oryon Health',
      vibrationPattern: defaultVibrationPattern,
      audioAttributesUsage: AudioAttributesUsage.notification,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }
}

