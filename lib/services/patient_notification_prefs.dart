import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do paciente ligadas a e-mail / alertas (chaves partilhadas com [SettingsController]).
abstract final class PatientNotificationPrefs {
  /// Igual à chave usada em definições — «Alertas de acesso» por e-mail.
  static const accessLogsEmailKey = 'settings_access_logs_email';

  static Future<bool> isAccessLogEmailEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(accessLogsEmailKey) ?? false;
  }
}
