import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final criticalAlerts = true.obs;
  final dailySummary = true.obs;
  final smartReminders = false.obs;

  final dataVisibility = true.obs;
  final accessLogsEmail = false.obs;

  final darkTheme = false.obs;
  final language = 'pt_BR'.obs;

  static const _criticalAlertsKey = 'settings_critical_alerts';
  static const _dailySummaryKey = 'settings_daily_summary';
  static const _smartRemindersKey = 'settings_smart_reminders';

  static const _dataVisibilityKey = 'settings_data_visibility';
  static const _accessLogsEmailKey = 'settings_access_logs_email';

  static const _darkThemeKey = 'settings_dark_theme';
  static const _languageKey = 'settings_language';

  final AuthService _authService = Get.find<AuthService>();
  final isDeletingAccount = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    criticalAlerts.value = prefs.getBool(_criticalAlertsKey) ?? true;
    dailySummary.value = prefs.getBool(_dailySummaryKey) ?? true;
    smartReminders.value = prefs.getBool(_smartRemindersKey) ?? false;
    dataVisibility.value = prefs.getBool(_dataVisibilityKey) ?? true;
    accessLogsEmail.value = prefs.getBool(_accessLogsEmailKey) ?? false;
    darkTheme.value = prefs.getBool(_darkThemeKey) ?? false;
    language.value = prefs.getString(_languageKey) ?? 'pt_BR';
  }

  Future<void> toggleCriticalAlerts(bool value) async {
    criticalAlerts.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_criticalAlertsKey, value);
    await _updateTopic('alerts_critical', value);
  }

  Future<void> toggleDailySummary(bool value) async {
    dailySummary.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailySummaryKey, value);
    await _updateTopic('alerts_daily_summary', value);
  }

  Future<void> toggleSmartReminders(bool value) async {
    smartReminders.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smartRemindersKey, value);
    await _updateTopic('alerts_smart_reminders', value);
  }

  Future<void> toggleDataVisibility(bool value) async {
    dataVisibility.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataVisibilityKey, value);
  }

  Future<void> toggleAccessLogsEmail(bool value) async {
    accessLogsEmail.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accessLogsEmailKey, value);
  }

  Future<void> toggleDarkTheme(bool value) async {
    darkTheme.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> changeLanguage(String value) async {
    language.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    final localeParts = value.split('_');
    Get.updateLocale(Locale(localeParts.first, localeParts.length > 1 ? localeParts[1] : ''));
  }

  Future<void> _updateTopic(String topic, bool enable) async {
    try {
      final notificationService = NotificationService.instance;
      if (enable) {
        await notificationService.subscribeToTopic(topic);
      } else {
        await notificationService.unsubscribeFromTopic(topic);
      }
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) {
      return;
    }
    try {
      isDeletingAccount.value = true;
      await _authService.deleteCurrentAccount();
      Get.offAllNamed(Routes.LOGIN);
      Get.snackbar(
        'inst_settings_delete_success_title'.tr,
        'inst_settings_delete_success_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      final message = e is String && e.isNotEmpty ? e : 'inst_settings_delete_error_message'.tr;
      Get.snackbar(
        'inst_settings_delete_error_title'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }
}

