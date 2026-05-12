import 'dart:async';
import 'dart:ui' as ui;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/notifications/notification_settings_constants.dart';
import '../../services/patient_notification_prefs.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final criticalAlerts = true.obs;
  final dailySummary = true.obs;
  final smartReminders = false.obs;

  final dataVisibility = true.obs;
  final accessLogsEmail = false.obs;

  final darkTheme = false.obs;
  final language = 'system'.obs;

  static const _dataVisibilityKey = 'settings_data_visibility';

  static const _darkThemeKey = 'settings_dark_theme';
  static const _languageKey = 'settings_language';

  Future<void>? _loadFuture;

  /// Idiomas suportados pelo dropdown de configurações.
  static const supportedLanguages = ['system', 'pt_BR', 'en_US'];

  final AuthService _authService = Get.find<AuthService>();
  final isDeletingAccount = false.obs;

  Completer<void>? _prefsLoadedCompleter;

  /// Use em main() antes de runApp() para aplicar o idioma salvo já no primeiro frame.
  static Future<void> ensureLoaded() async {
    final c = Get.find<SettingsController>();
    if (c._prefsLoadedCompleter != null) {
      await c._prefsLoadedCompleter!.future;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _prefsLoadedCompleter = Completer<void>();
    // Preferências: [ensurePreferencesLoaded] em main() (evita corrida / duplo load).
  }

  /// Garante que as preferências foram carregadas (para uso em main antes de runApp).
  Future<void> ensurePreferencesLoaded() async {
    _loadFuture ??= _loadPreferences();
    await _loadFuture;
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      criticalAlerts.value =
          prefs.getBool(NotificationSettingsPrefs.criticalAlertsKey) ?? true;
      dailySummary.value =
          prefs.getBool(NotificationSettingsPrefs.dailySummaryKey) ?? true;
      smartReminders.value =
          prefs.getBool(NotificationSettingsPrefs.smartRemindersKey) ?? false;
      dataVisibility.value = prefs.getBool(_dataVisibilityKey) ?? true;
      accessLogsEmail.value =
          prefs.getBool(PatientNotificationPrefs.accessLogsEmailKey) ?? false;
      darkTheme.value = prefs.getBool(_darkThemeKey) ?? false;
      final savedLang = prefs.getString(_languageKey) ?? 'system';
      language.value =
          supportedLanguages.contains(savedLang) ? savedLang : 'system';
      if (!supportedLanguages.contains(savedLang)) {
        await prefs.setString(_languageKey, 'system');
      }
    } finally {
      if (_prefsLoadedCompleter != null &&
          !_prefsLoadedCompleter!.isCompleted) {
        _prefsLoadedCompleter!.complete();
      }
    }
  }

  /// Retorna o locale efetivo: idioma do dispositivo quando 'system', senão o salvo.
  Locale get effectiveLocale {
    if (language.value == 'system') {
      return _deviceLocaleToSupported();
    }
    final parts = language.value.split('_');
    return Locale(parts.first, parts.length > 1 ? parts[1] : '');
  }

  /// Mapeia o locale do dispositivo para um dos suportados (pt_BR ou en_US).
  static Locale _deviceLocaleToSupported() {
    final device = ui.PlatformDispatcher.instance.locale;
    final lang = device.languageCode.toLowerCase();
    if (lang.startsWith('pt')) return const Locale('pt', 'BR');
    if (lang.startsWith('en')) return const Locale('en', 'US');
    return const Locale('pt', 'BR');
  }

  Future<void> toggleCriticalAlerts(bool value) async {
    criticalAlerts.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationSettingsPrefs.criticalAlertsKey, value);
    await _updateTopic(NotificationSettingsPrefs.criticalTopic, value);
  }

  Future<void> toggleDailySummary(bool value) async {
    dailySummary.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationSettingsPrefs.dailySummaryKey, value);
    await _updateTopic(NotificationSettingsPrefs.dailyTopic, value);
  }

  Future<void> toggleSmartReminders(bool value) async {
    smartReminders.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationSettingsPrefs.smartRemindersKey, value);
    await _updateTopic(NotificationSettingsPrefs.smartTopic, value);
  }

  Future<void> toggleDataVisibility(bool value) async {
    dataVisibility.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataVisibilityKey, value);
  }

  Future<void> toggleAccessLogsEmail(bool value) async {
    accessLogsEmail.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PatientNotificationPrefs.accessLogsEmailKey, value);
  }

  Future<void> toggleDarkTheme(bool value) async {
    darkTheme.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, value);
  }

  Future<void> changeLanguage(String value) async {
    language.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    final locale = value == 'system'
        ? _deviceLocaleToSupported()
        : Locale(
            value.split('_').first,
            value.split('_').length > 1 ? value.split('_')[1] : '',
          );
    Get.locale = locale;
    Get.updateLocale(locale);
    try {
      await NotificationService.instance.reregisterChannelsForCurrentLocale();
    } catch (_) {}
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

