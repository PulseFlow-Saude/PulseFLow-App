import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configurações de canais de notificação
class NotificationChannels {
  // IDs dos canais
  static const String doctorAccessChannelId = 'doctor_access_channel';
  static const String importantChannelId = 'important_channel';
  static const String medicationChannelId = 'medication_channel';
  static const String appointmentChannelId = 'appointment_channel';
  static const String generalChannelId = 'pulseflow_channel';

  /// Canal para solicitações de acesso médico
  static const AndroidNotificationChannel doctorAccessChannel = AndroidNotificationChannel(
    doctorAccessChannelId,
    'Solicitações de Acesso Médico',
    description: 'Notificações quando um médico solicita acesso ao prontuário',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  /// Canal para notificações importantes
  static const AndroidNotificationChannel importantChannel = AndroidNotificationChannel(
    importantChannelId,
    'Notificações Importantes',
    description: 'Notificações importantes do PulseFlow',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  /// Canal para lembretes de medicação
  static const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
    medicationChannelId,
    'Lembretes de Medicação',
    description: 'Lembretes para tomar medicamentos',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Canal para lembretes de consultas
  static const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
    appointmentChannelId,
    'Lembretes de Consultas',
    description: 'Lembretes para consultas médicas',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Canal geral
  static const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
    generalChannelId,
    'PulseFlow Notifications',
    description: 'Canal de notificações do PulseFlow',
    importance: Importance.high,
    playSound: true,
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

