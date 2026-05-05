/// Normaliza valores de catálogo vindos do MongoDB.
///
/// Registos antigos gravavam chaves i18n (`reg_gender_male`, `macro_prof_*`, …).
/// O painel web precisa do texto legível; ao ler, convertemos essas chaves para PT-BR.
/// Valores já human-readable (cadastro novo ou idioma EN) permanecem inalterados.
class PatientCatalogNormalize {
  PatientCatalogNormalize._();

  static const Map<String, String> _genderLegacyPt = {
    'reg_gender_male': 'Masculino',
    'reg_gender_female': 'Feminino',
    'reg_gender_non_binary': 'Não binário',
    'reg_gender_prefer_not': 'Prefiro não informar',
  };

  static const Map<String, String> _maritalLegacyPt = {
    'reg_marital_single': 'Solteiro(a)',
    'reg_marital_married': 'Casado(a)',
    'reg_marital_divorced': 'Divorciado(a)',
    'reg_marital_widowed': 'Viúvo(a)',
    'reg_marital_stable_union': 'União estável',
    'reg_marital_separated': 'Separado(a)',
  };

  static const Map<String, String> _professionLegacyPt = {
    'macro_prof_health': 'Saúde e bem-estar',
    'macro_prof_education': 'Educação',
    'macro_prof_it': 'Tecnologia da informação',
    'macro_prof_engineering': 'Engenharia',
    'macro_prof_legal': 'Direito e serviços jurídicos',
    'macro_prof_business': 'Negócios e gestão',
    'macro_prof_sales': 'Vendas e marketing',
    'macro_prof_finance': 'Finanças e contabilidade',
    'macro_prof_construction': 'Construção civil',
    'macro_prof_industry': 'Indústria e produção',
    'macro_prof_agriculture': 'Agricultura e pecuária',
    'macro_prof_transport': 'Transporte e logística',
    'macro_prof_hospitality': 'Hotelaria e turismo',
    'macro_prof_arts': 'Arte, cultura e design',
    'macro_prof_media': 'Comunicação e mídia',
    'macro_prof_public': 'Serviço público',
    'macro_prof_security': 'Segurança e defesa',
    'macro_prof_science': 'Ciência e pesquisa',
    'macro_prof_services': 'Serviços gerais',
    'macro_prof_student': 'Estudante',
    'macro_prof_retired': 'Aposentado(a)',
    'macro_prof_other': 'Outro',
  };

  static String gender(String raw) => _mapOrSame(raw, _genderLegacyPt);

  static String marital(String raw) => _mapOrSame(raw, _maritalLegacyPt);

  static String? profession(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    final t = raw.trim();
    return _professionLegacyPt[t] ?? t;
  }

  static String _mapOrSame(String raw, Map<String, String> legacyPt) {
    final t = raw.trim();
    return legacyPt[t] ?? t;
  }

  /// Gravação no MongoDB: texto da UI (`translated`) ou, se ainda for chave i18n, rótulo PT conhecido.
  static String persistGender(String key, String translatedFromUi) {
    final k = key.trim();
    final t = translatedFromUi.trim();
    if (t.isNotEmpty && t != k) return t;
    return _genderLegacyPt[k] ?? k;
  }

  static String persistMarital(String key, String translatedFromUi) {
    final k = key.trim();
    final t = translatedFromUi.trim();
    if (t.isNotEmpty && t != k) return t;
    return _maritalLegacyPt[k] ?? k;
  }

  static String persistProfession(String key, String translatedFromUi) {
    final k = key.trim();
    final t = translatedFromUi.trim();
    if (t.isNotEmpty && t != k) return t;
    return _professionLegacyPt[k] ?? k;
  }
}
