import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

/// Formato de data conforme o país de residência do paciente (não o idioma da UI).
class ResidenceDateFormat {
  ResidenceDateFormat._();

  static bool useUsDateOrder(String? residenceCountry) =>
      (residenceCountry ?? '').toUpperCase() == 'US';

  /// Ex.: EUA `MM/dd/yyyy`; demais `dd/MM/yyyy`.
  static String formatDate(DateTime? date, String? residenceCountry) {
    if (date == null) return '';
    if (useUsDateOrder(residenceCountry)) {
      return DateFormat('MM/dd/yyyy').format(date);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Locale do [showDatePicker] para alinhar ordem/cabeçalhos ao formato local.
  static Locale datePickerLocale({
    required String? residenceCountry,
    required Locale appLocale,
  }) {
    if (useUsDateOrder(residenceCountry)) {
      return const Locale('en', 'US');
    }
    return appLocale;
  }
}
