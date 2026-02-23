import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Integra o pacote [intl] ao idioma selecionado no app (Get.locale).
/// Use estes formatadores em vez de DateFormat/NumberFormat direto com locale fixo,
/// para que datas e números sigam o idioma escolhido em Configurações.
///
/// Exemplo:
///   AppDateFormat.shortDate.format(date)  // dd/MM/yyyy ou MM/dd/yyyy conforme idioma
///   AppDateFormat.medium.format(date)
///   AppDateFormat.time.format(date)
class AppDateFormat {
  AppDateFormat._();

  static String _localeString() {
    final locale = Get.locale;
    if (locale == null) return 'pt_BR';
    final lang = locale.languageCode;
    final country = locale.countryCode?.isNotEmpty == true ? locale.countryCode! : '';
    if (country.isNotEmpty) return '${lang}_$country';
    return lang == 'en' ? 'en_US' : lang == 'pt' ? 'pt_BR' : lang;
  }

  /// Data curta (ex: 22/02/2025 ou 02/22/2025)
  static DateFormat get shortDate =>
      DateFormat.yMd(_localeString());

  /// Data média (ex: 22 de fev. de 2025 / Feb 22, 2025)
  static DateFormat get medium =>
      DateFormat.MMMd(_localeString());

  /// Data longa (ex: 22 de fevereiro de 2025 / February 22, 2025)
  static DateFormat get long =>
      DateFormat.yMMMMd(_localeString());

  /// Só hora (ex: 14:30)
  static DateFormat get time =>
      DateFormat.Hm(_localeString());

  /// Data e hora (ex: 22/02/2025 14:30)
  static DateFormat get shortDateTime =>
      DateFormat.yMd(_localeString()).add_Hm();

  /// Padrão customizado usando o locale do app
  static DateFormat custom(String pattern) =>
      DateFormat(pattern, _localeString());

  /// Para chaves que precisam de formato fixo (ex: yyyy-MM-dd) o locale não muda o resultado,
  /// mas pode ser usado para consistência.
  static DateFormat get dateIso =>
      DateFormat('yyyy-MM-dd');

  /// Nome do mês + ano no idioma do app (ex: "February 2025" / "fevereiro de 2025")
  static String monthYear(DateTime d) =>
      DateFormat.yMMMM(_localeString()).format(d);

  /// Nome curto do mês no idioma do app (ex: "Feb" / "Fev")
  static String monthShort(int month) =>
      DateFormat.MMM(_localeString()).format(DateTime(2000, month, 1));
}

/// Números no locale do app (separador decimal, etc.)
class AppNumberFormat {
  AppNumberFormat._();

  static String _localeString() {
    final locale = Get.locale;
    if (locale == null) return 'pt_BR';
    final lang = locale.languageCode;
    final country = locale.countryCode?.isNotEmpty == true ? locale.countryCode! : '';
    if (country.isNotEmpty) return '${lang}_$country';
    return lang == 'en' ? 'en_US' : lang == 'pt' ? 'pt_BR' : lang;
  }

  static NumberFormat decimal([int? decimalDigits]) =>
      NumberFormat.decimalPattern(_localeString());
}
