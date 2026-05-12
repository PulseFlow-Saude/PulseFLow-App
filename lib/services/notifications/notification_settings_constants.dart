import 'package:shared_preferences/shared_preferences.dart';

/// Chaves [SharedPreferences] e tópicos FCM alinhados com o ecrã de definições.
abstract final class NotificationSettingsPrefs {
  static const criticalAlertsKey = 'settings_critical_alerts';
  static const dailySummaryKey = 'settings_daily_summary';
  static const smartRemindersKey = 'settings_smart_reminders';

  static const criticalTopic = 'alerts_critical';
  static const dailyTopic = 'alerts_daily_summary';
  static const smartTopic = 'alerts_smart_reminders';

  /// Campo opcional no `data` do FCM para filtrar no cliente (defesa em profundidade).
  /// Valores: [criticalTopic], [dailyTopic], [smartTopic]. Se ausente, a mensagem é exibida.
  static const fcmDataTopicKey = 'pf_topic';

  static Future<Map<String, bool>> loadTopicEnabledMap() async {
    final p = await SharedPreferences.getInstance();
    return {
      criticalTopic: p.getBool(criticalAlertsKey) ?? true,
      dailyTopic: p.getBool(dailySummaryKey) ?? true,
      smartTopic: p.getBool(smartRemindersKey) ?? false,
    };
  }

  /// Lê [pf_topic] do payload FCM (se existir).
  static String? parseTopicFromData(Map<String, dynamic> data) {
    final v = data[fcmDataTopicKey]?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Se o payload indica um tópico de preferência e o utilizador desligou essa categoria, não entregar.
  /// Mensagens sem [fcmDataTopicKey] mantêm o comportamento anterior (sempre entregar no cliente).
  static Future<bool> shouldDeliverForFcmData(Map<String, dynamic> data) async {
    final topic = parseTopicFromData(data);
    if (topic == null) return true;
    final map = await loadTopicEnabledMap();
    return map[topic] ?? true;
  }
}
