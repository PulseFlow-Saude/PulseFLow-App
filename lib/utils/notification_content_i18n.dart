import 'dart:ui' as ui;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_translations.dart';

/// Traduz título e corpo de notificações criadas no backend (tipicamente em PT)
/// para o idioma atual da app ([pt_BR] / [en_US]).
abstract final class NotificationContentI18n {
  static const _prefsLanguageKey = 'settings_language';

  static String _normalizeLocale(String? code) {
    if (code == null || code.isEmpty) return 'pt_BR';
    if (code == 'en_US' || code == 'en') return 'en_US';
    return 'pt_BR';
  }

  /// Locale efetivo quando [Get] já está inicializado (foreground / UI).
  static String effectiveLocaleCodeSync() {
    try {
      final l = Get.locale;
      if (l != null) {
        final c = '${l.languageCode}_${l.countryCode}';
        return _normalizeLocale(c);
      }
    } catch (_) {}
    return 'pt_BR';
  }

  /// Locale guardado nas definições (útil em isolate de background, sem [Get]).
  static Future<String> effectiveLocaleCodeAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_prefsLanguageKey) ?? 'system';
      if (v == 'en_US') return 'en_US';
      if (v == 'pt_BR') return 'pt_BR';
      final d = ui.PlatformDispatcher.instance.locale;
      if (d.languageCode.toLowerCase().startsWith('en')) return 'en_US';
      return 'pt_BR';
    } catch (_) {
      return 'pt_BR';
    }
  }

  static String _t(String locale, String key) {
    final all = AppTranslations().keys;
    final map = all[locale] ?? all['pt_BR']!;
    return map[key] ?? map['notif_default'] ?? key;
  }

  static String _applyParams(String template, Map<String, String> values) {
    var s = template;
    for (final e in values.entries) {
      s = s.replaceAll('@${e.key}', e.value);
    }
    return s;
  }

  static String? _titleTrKey(String titleRaw) {
    final t = titleRaw.trim().toLowerCase();
    const m = {
      'nova solicitação de acesso': 'notif_srv_title_pulse_request',
      'new access request': 'notif_srv_title_pulse_request',
      'nova consulta agendada': 'notif_srv_title_new_appt_doctor',
      'new appointment scheduled': 'notif_srv_title_new_appt_doctor',
      'consulta confirmada': 'notif_srv_title_appt_confirmed',
      'appointment confirmed': 'notif_srv_title_appt_confirmed',
      'consulta cancelada': 'notif_srv_title_appt_cancelled',
      'appointment cancelled': 'notif_srv_title_appt_cancelled',
      'appointment canceled': 'notif_srv_title_appt_cancelled',
      'consulta remarcada': 'notif_srv_title_appt_rescheduled',
      'appointment rescheduled': 'notif_srv_title_appt_rescheduled',
      'consulta agendada': 'notif_srv_title_appt_scheduled',
      'appointment scheduled': 'notif_srv_title_appt_scheduled',
      'novo agendamento': 'notif_srv_title_new_booking',
      'new booking': 'notif_srv_title_new_booking',
      'agendamento cancelado pelo paciente': 'notif_srv_title_cancel_by_patient',
      'appointment cancelled by patient': 'notif_srv_title_cancel_by_patient',
      'appointment canceled by patient': 'notif_srv_title_cancel_by_patient',
      'dados do perfil alterados': 'notif_srv_title_profile_changed',
      'profile data changed': 'notif_srv_title_profile_changed',
      'perfil atualizado': 'notif_srv_title_profile_updated',
      'profile updated': 'notif_srv_title_profile_updated',
      'foto de perfil atualizada': 'notif_srv_title_photo_updated',
      'profile photo updated': 'notif_srv_title_photo_updated',
      'cadastro aprovado': 'notif_srv_title_reg_approved',
      'registration approved': 'notif_srv_title_reg_approved',
      'cadastro não aprovado': 'notif_srv_title_reg_rejected',
      'cadastro nao aprovado': 'notif_srv_title_reg_rejected',
      'registration not approved': 'notif_srv_title_reg_rejected',
    };
    return m[t];
  }

  static String? _translateBody(String titleLower, String body, String loc) {
    final b = body.trim();
    if (b.isEmpty) return b;

    RegExpMatch? m;

    final pulse = RegExp(
      r'^(.+?)\s+\((.+?)\)\s+está solicitando acesso aos seus dados de saúde\s+(?:por meio da Chave Oryon|através do Pulse Key)\.?\s*$',
      caseSensitive: false,
    );
    m = pulse.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_pulse_desc'), {
        'name': m.group(1)!.trim(),
        'specialty': m.group(2)!.trim(),
      });
    }

    final newForYou = RegExp(
      r'^Uma consulta foi agendada para você com\s+(.+?)\s+em\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = newForYou.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_new_appt_you'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final confirmed = RegExp(
      r'^Sua consulta com\s+(.+?)\s+em\s+(.+?)\s+foi confirmada\s*$',
      caseSensitive: false,
    );
    m = confirmed.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_appt_confirmed_body'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final resched = RegExp(
      r'^Sua consulta com\s+(.+?)\s+foi remarcada para\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = resched.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_appt_rescheduled_body'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final selfBook = RegExp(
      r'^Sua consulta com\s+(.+?)\s+foi agendada para\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = selfBook.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_you_scheduled'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final patientBooked = RegExp(
      r'^(.+?)\s+agendou uma consulta para\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = patientBooked.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_patient_booked'), {
        'patient': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final cancel = RegExp(
      r'^Sua consulta com\s+(.+?)\s+agendada para\s+(.+?)\s+foi cancelada(?:\.\s*Motivo:\s*(.+))?\s*$',
      caseSensitive: false,
    );
    m = cancel.firstMatch(b);
    if (m != null) {
      final reason = (m.group(3) ?? '').trim();
      final reasonSuffix = reason.isEmpty
          ? ''
          : _applyParams(_t(loc, 'notif_srv_reason_line'), {'reason': reason});
      return _applyParams(_t(loc, 'notif_srv_appt_cancelled_body'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
        'reasonSuffix': reasonSuffix,
      });
    }

    final docCancel = RegExp(
      r'^(.+?)\s+cancelou a consulta agendada para\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = docCancel.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_patient_cancelled_doctor'), {
        'patient': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final profileBy = RegExp(
      r'^Seus dados de perfil foram atualizados por\s+(.+?)\.\s*Verifique as alterações em seu perfil\.?\s*$',
      caseSensitive: false,
    );
    m = profileBy.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_profile_changed_body'), {
        'by': m.group(1)!.trim(),
      });
    }

    if (titleLower == 'perfil atualizado' &&
        RegExp(r'seus dados do perfil foram atualizados com sucesso', caseSensitive: false)
            .hasMatch(b)) {
      return _t(loc, 'notif_srv_profile_updated_body');
    }

    if (titleLower == 'foto de perfil atualizada' &&
        RegExp(r'foto de perfil', caseSensitive: false).hasMatch(b)) {
      return _t(loc, 'notif_srv_photo_updated_body');
    }

    if (titleLower == 'cadastro aprovado') {
      return _t(loc, 'notif_srv_reg_approved_body');
    }

    if (titleLower.contains('cadastro') &&
        (titleLower.contains('não aprovado') || titleLower.contains('nao aprovado'))) {
      final rej = RegExp(r'^Motivo informado pela equipe:\s*(.+)\s*$', caseSensitive: false);
      final rm = rej.firstMatch(b);
      if (rm != null) {
        return _applyParams(_t(loc, 'notif_srv_reg_rejected_body'), {
          'reason': rm.group(1)!.trim(),
        });
      }
    }

    // Mensagens já em inglês (se o servidor enviar)
    final enYourScheduled = RegExp(
      r'^Your appointment with\s+(.+?)\s+was scheduled for\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = enYourScheduled.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_you_scheduled'), {
        'doctor': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    final enPatientBooked = RegExp(
      r'^(.+?)\s+scheduled an appointment for\s+(.+?)\s*$',
      caseSensitive: false,
    );
    m = enPatientBooked.firstMatch(b);
    if (m != null) {
      return _applyParams(_t(loc, 'notif_srv_patient_booked'), {
        'patient': m.group(1)!.trim(),
        'date': m.group(2)!.trim(),
      });
    }

    return null;
  }

  /// [rawTitle] e [rawMessage] são os textos crus (ex.: API ou FCM).
  static ({String title, String message}) localize(
    String rawTitle,
    String rawMessage, {
    String? localeCode,
  }) {
    final loc = _normalizeLocale(localeCode ?? effectiveLocaleCodeSync());
    final nt = rawTitle.trim();
    final nb = rawMessage.trim();

    final tk = _titleTrKey(nt);
    final title = tk != null ? _t(loc, tk) : nt;

    final titleLower = nt.toLowerCase();
    final translatedBody = _translateBody(titleLower, nb, loc);
    final message = translatedBody ?? nb;

    return (title: title, message: message);
  }
}
