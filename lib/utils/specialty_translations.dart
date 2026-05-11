import 'dart:ui' show Locale;

import 'package:get/get.dart';

import '../screens/institutional/settings_controller.dart';

/// Mapeamento de especialidades médicas PT ↔ EN para exibição no idioma do app.
/// A API pode enviar nomes em português ou em inglês; o texto exibido segue
/// [SettingsController.effectiveLocale] (alinhado ao [GetMaterialApp.locale]).
class SpecialtyTranslations {
  static const Map<String, String> _ptToEn = {
    'Acupuntura': 'Acupuncture',
    'Alergia e imunologia': 'Allergy and immunology',
    'Alergia e Imunologia': 'Allergy and immunology',
    'Anestesiologia': 'Anesthesiology',
    'Angiologia': 'Angiology',
    'Cardiologia': 'Cardiology',
    'Cirurgia cardiovascular': 'Cardiovascular surgery',
    'Cirurgia Cardiovascular': 'Cardiovascular surgery',
    'Cirurgia da mão': 'Hand surgery',
    'Cirurgia da Mão': 'Hand surgery',
    'Cirurgia de cabeça e pescoço': 'Head and neck surgery',
    'Cirurgia de Cabeça e Pescoço': 'Head and neck surgery',
    'Cirurgia do aparelho digestivo': 'Digestive system surgery',
    'Cirurgia do Aparelho Digestivo': 'Digestive system surgery',
    'Cirurgia geral': 'General surgery',
    'Cirurgia Geral': 'General surgery',
    'Cirurgia oncológica': 'Surgical oncology',
    'Cirurgia Oncológica': 'Surgical oncology',
    'Cirurgia pediátrica': 'Pediatric surgery',
    'Cirurgia Pediátrica': 'Pediatric surgery',
    'Cirurgia plástica': 'Plastic surgery',
    'Cirurgia Plástica': 'Plastic surgery',
    'Cirurgia torácica': 'Thoracic surgery',
    'Cirurgia Torácica': 'Thoracic surgery',
    'Cirurgia vascular': 'Vascular surgery',
    'Cirurgia Vascular': 'Vascular surgery',
    'Clínica médica': 'Internal medicine',
    'Clínica Médica': 'Internal medicine',
    'Clínica geral': 'Internal medicine',
    'Medicina geral': 'General medicine',
    'Coloproctologia': 'Coloproctology',
    'Dermatologia': 'Dermatology',
    'Diagnóstico por imagem': 'Diagnostic imaging',
    'Endocrinologia e metabologia': 'Endocrinology and metabolism',
    'Endocrinologia e Metabologia': 'Endocrinology and metabolism',
    'Endoscopia': 'Endoscopy',
    'Gastroenterologia': 'Gastroenterology',
    'Genética médica': 'Medical genetics',
    'Genética Médica': 'Medical genetics',
    'Geriatria': 'Geriatrics',
    'Ginecologia e obstetrícia': 'Gynecology and obstetrics',
    'Ginecologia e Obstetrícia': 'Gynecology and obstetrics',
    'Ginecologia': 'Gynecology',
    'Obstetrícia': 'Obstetrics',
    'Hematologia e hemoterapia': 'Hematology and hemotherapy',
    'Hematologia e Hemoterapia': 'Hematology and hemotherapy',
    'Homeopatia': 'Homeopathy',
    'Infectologia': 'Infectious diseases',
    'Mastologia': 'Mastology',
    'Medicina de emergência': 'Emergency medicine',
    'Medicina de Emergência': 'Emergency medicine',
    'Medicina de família e comunidade': 'Family and community medicine',
    'Medicina de Família e Comunidade': 'Family and community medicine',
    'Medicina do trabalho': 'Occupational medicine',
    'Medicina do Trabalho': 'Occupational medicine',
    'Medicina do tráfego': 'Traffic medicine',
    'Medicina do Tráfego': 'Traffic medicine',
    'Medicina esportiva': 'Sports medicine',
    'Medicina Esportiva': 'Sports medicine',
    'Medicina física e reabilitação': 'Physical medicine and rehabilitation',
    'Medicina Física e Reabilitação': 'Physical medicine and rehabilitation',
    'Fisiatria': 'Physical medicine and rehabilitation',
    'Medicina intensiva': 'Intensive care medicine',
    'Medicina Intensiva': 'Intensive care medicine',
    'Medicina legal e perícia médica': 'Legal medicine and medical expertise',
    'Medicina Legal e Perícia Médica': 'Legal medicine and medical expertise',
    'Medicina nuclear': 'Nuclear medicine',
    'Medicina Nuclear': 'Nuclear medicine',
    'Medicina preventiva e social': 'Preventive and social medicine',
    'Medicina Preventiva e Social': 'Preventive and social medicine',
    'Nefrologia': 'Nephrology',
    'Neurocirurgia': 'Neurosurgery',
    'Neurologia': 'Neurology',
    'Nutrologia': 'Nutrology',
    'Oftalmologia': 'Ophthalmology',
    'Oncologia clínica': 'Clinical oncology',
    'Oncologia Clínica': 'Clinical oncology',
    'Oncogenética': 'Oncogenetics',
    'Ortopedia e traumatologia': 'Orthopedics and traumatology',
    'Ortopedia e Traumatologia': 'Orthopedics and traumatology',
    'Ortopedia': 'Orthopedics',
    'Traumatologia': 'Traumatology',
    'Otorrinolaringologia': 'Otorhinolaryngology',
    'Patologia': 'Pathology',
    'Patologia clínica': 'Clinical pathology',
    'Patologia Clínica': 'Clinical pathology',
    'Patologia clínica/medicina laboratorial': 'Clinical pathology/laboratory medicine',
    'Medicina laboratorial': 'Laboratory medicine',
    'Pediatria': 'Pediatrics',
    'Pneumologia': 'Pulmonology',
    'Psiquiatria': 'Psychiatry',
    'Radiologia e diagnóstico por imagem': 'Radiology and diagnostic imaging',
    'Radiologia e Diagnóstico por Imagem': 'Radiology and diagnostic imaging',
    'Radiologia': 'Radiology',
    'Radioterapia': 'Radiation therapy',
    'Reumatologia': 'Rheumatology',
    'Urologia': 'Urology',
    'Outros': 'Other',
    'Fisioterapia': 'Physical therapy',
    'Enfermagem': 'Nursing',
    'Fonoaudiologia': 'Speech therapy',
    'Terapia ocupacional': 'Occupational therapy',
    'Psicologia': 'Psychology',
    'Nutrição': 'Nutrition',
    'Farmácia': 'Pharmacy',
    'Biomedicina': 'Biomedicine',
  };

  static Map<String, String>? _normalizedLookup;

  static Map<String, String> get _normalizedMap {
    _normalizedLookup ??= () {
      final map = <String, String>{};
      for (final e in _ptToEn.entries) {
        final key = _normalizeKey(e.key);
        if (!map.containsKey(key)) map[key] = e.value;
      }
      return map;
    }();
    return _normalizedLookup!;
  }

  /// PT normalizado → forma canônica PT (primeira chave do mapa).
  static Map<String, String>? _ptNormToCanonCache;

  static Map<String, String> get _ptNormToCanon {
    _ptNormToCanonCache ??= () {
      final m = <String, String>{};
      for (final key in _ptToEn.keys) {
        final nk = _normalizeKey(key);
        m.putIfAbsent(nk, () => key);
      }
      return m;
    }();
    return _ptNormToCanonCache!;
  }

  /// EN normalizado → inglês canônico (valor do mapa).
  static Map<String, String>? _enNormToEnCache;

  static Map<String, String> get _enNormToEn {
    _enNormToEnCache ??= () {
      final m = <String, String>{};
      for (final e in _ptToEn.entries) {
        final nk = _normalizeKey(e.value);
        m.putIfAbsent(nk, () => e.value);
      }
      return m;
    }();
    return _enNormToEnCache!;
  }

  /// EN normalizado → PT canônico (chave do mapa).
  static Map<String, String>? _enNormToPtCache;

  static Map<String, String> get _enNormToPt {
    _enNormToPtCache ??= () {
      final m = <String, String>{};
      for (final e in _ptToEn.entries) {
        final nk = _normalizeKey(e.value);
        m.putIfAbsent(nk, () => e.key);
      }
      return m;
    }();
    return _enNormToPtCache!;
  }

  static String _normalizeKey(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static Locale _effectiveAppLocale() {
    try {
      if (Get.isRegistered<SettingsController>()) {
        return Get.find<SettingsController>().effectiveLocale;
      }
    } catch (_) {}
    return Get.locale ?? const Locale('pt', 'BR');
  }

  /// Retorna o nome da especialidade no idioma atual do app (pt / en).
  static String translate(String? specialtyName) {
    if (specialtyName == null || specialtyName.isEmpty) return specialtyName ?? '';
    final locale = _effectiveAppLocale();
    final lang = locale.languageCode.toLowerCase();
    final trimmed = specialtyName.trim();
    final nk = _normalizeKey(trimmed);

    if (lang == 'en') {
      final fromPt = _ptToEn[trimmed] ?? _normalizedMap[nk];
      if (fromPt != null) return fromPt;
      return _enNormToEn[nk] ?? trimmed;
    }
    if (lang == 'pt') {
      if (_ptToEn.containsKey(trimmed)) return trimmed;
      final canonPt = _ptNormToCanon[nk];
      if (canonPt != null) return canonPt;
      return _enNormToPt[nk] ?? trimmed;
    }
    return trimmed;
  }
}
