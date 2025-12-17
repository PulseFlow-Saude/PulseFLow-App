import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_channels.dart';

class NotificationBuilders {
  static const Color primaryColor = Color(0xFF00324A);
  static final Int64List defaultVibrationPattern = Int64List.fromList([0, 600, 200, 600]);

  static NotificationDetails createDoctorAccessNotification({
    required String doctorName,
    required String specialty,
  }) {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.doctorAccessChannelId,
      'Solicitações de Acesso Médico',
      channelDescription: 'Notificações quando um médico solicita acesso ao prontuário',
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
        'Dr(a). $doctorName ${specialty.isNotEmpty ? "($specialty)" : ""} solicitou acesso ao seu prontuário médico. Gere o código direto no PulseFlow.',
        htmlFormatBigText: true,
        contentTitle: '🩺 Solicitação de acesso',
        htmlFormatContentTitle: true,
        summaryText: 'PulseFlow',
      ),
      ticker: 'PulseFlow',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notification,
      vibrationPattern: defaultVibrationPattern,
      autoCancel: true,
      actions: const [
        AndroidNotificationAction(
          'pulseflow_open_request',
          'Ver Solicitação',
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
      'Notificações Importantes',
      channelDescription: 'Notificações importantes do PulseFlow',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: primaryColor,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'PulseFlow',
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
      'Lembretes de Medicação',
      channelDescription: 'Lembretes para tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'PulseFlow',
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
      'Lembretes de Consultas',
      channelDescription: 'Lembretes para consultas médicas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.event,
      visibility: NotificationVisibility.public,
      ticker: 'PulseFlow',
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
      'PulseFlow Notifications',
      channelDescription: 'Canal de notificações do PulseFlow',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: 'PulseFlow',
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

  static NotificationDetails createBackgroundMessageNotification() {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.generalChannelId,
      'PulseFlow Notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: 'PulseFlow',
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

