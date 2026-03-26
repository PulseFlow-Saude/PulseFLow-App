import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_translations.dart';
import '../screens/institutional/settings_controller.dart';

/// Helper para obter traduções de e-mail conforme o idioma do usuário.
/// Usa preferência do usuário (Configurações) ou idioma nativo do dispositivo.
class EmailTranslationsHelper {
  static const _languageKey = 'settings_language';

  /// Retorna o locale efetivo: preferência do usuário ou idioma do dispositivo.
  static Future<Locale> getEffectiveLocale() async {
    try {
      final settings = Get.find<SettingsController>();
      return settings.effectiveLocale;
    } catch (_) {
      return _deviceLocaleToSupported();
    }
  }

  /// Versão síncrona - usa Get.locale se disponível, senão dispositivo.
  static Locale getEffectiveLocaleSync() {
    try {
      final settings = Get.find<SettingsController>();
      return settings.effectiveLocale;
    } catch (_) {
      return _deviceLocaleToSupported();
    }
  }

  static Locale _deviceLocaleToSupported() {
    final device = ui.PlatformDispatcher.instance.locale;
    final lang = device.languageCode.toLowerCase();
    if (lang.startsWith('pt')) return const Locale('pt', 'BR');
    if (lang.startsWith('en')) return const Locale('en', 'US');
    return const Locale('pt', 'BR');
  }

  /// Obtém a tradução de uma chave para o locale efetivo.
  static String tr(String key, {Locale? locale}) {
    final loc = locale ?? getEffectiveLocaleSync();
    final trMap = AppTranslations().keys;
    final localeKey = '${loc.languageCode}_${loc.countryCode}';
    final fallbackKey = loc.languageCode.startsWith('pt') ? 'pt_BR' : 'en_US';
    final map = trMap[localeKey] ?? trMap[fallbackKey] ?? trMap['pt_BR']!;
    return map[key] ?? key;
  }

  /// Obtém traduções de e-mail para o locale efetivo (assinatura assíncrona).
  static Future<Map<String, String>> getEmailTranslations() async {
    final locale = await getEffectiveLocale();
    return _getEmailTranslationsForLocale(locale);
  }

  /// Obtém traduções de e-mail para o locale efetivo (síncrono).
  static Map<String, String> getEmailTranslationsSync() {
    final locale = getEffectiveLocaleSync();
    return _getEmailTranslationsForLocale(locale);
  }

  static Map<String, String> _getEmailTranslationsForLocale(Locale locale) {
    final keys = [
      'email_2fa_subject', 'email_2fa_heading', 'email_2fa_subheading',
      'email_2fa_hello', 'email_2fa_body', 'email_2fa_code_label',
      'email_2fa_important', 'email_2fa_ignore', 'email_2fa_footer',
      'email_reset_subject', 'email_reset_heading', 'email_reset_body',
      'email_reset_code_usage', 'email_reset_expiry', 'email_reset_ignore',
      'email_reset_footer',       'email_test_subject', 'email_test_body', 'email_test_suffix',
      'email_from_name',
    ];
    final result = <String, String>{};
    for (final k in keys) {
      result[k] = tr(k, locale: locale);
    }
    return result;
  }
}
