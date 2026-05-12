/// Leitura de datas/números vindos do Mongo (mongo_dart) e filtro por intervalo para gráficos de saúde.

/// Limite inferior do [showDateRangePicker] (HealthKit pode sincronizar anos antigos).
DateTime metricChartPickerFirstDate() => DateTime(1980, 1, 1);

DateTime metricChartDefaultEndDay() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Período inicial amplo: todo o histórico até hoje (evita excluir dados de 2016, 2020, etc.).
DateTime metricChartDefaultWideStartDay() => metricChartPickerFirstDate();

/// Últimos [inclusiveDays] dias de calendário terminando em [endDay] (início do dia).
DateTime metricChartDefaultStartDay(DateTime endDay, int inclusiveDays) {
  return endDay.subtract(Duration(days: inclusiveDays - 1));
}

DateTime? coerceMongoDateField(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
  }
  if (raw is Map) {
    // Extended JSON / export Compass: { "\$date": "..." } ou milissegundos
    final nested = raw[r'$date'] ?? raw['\$date'];
    if (nested != null) return coerceMongoDateField(nested);
    // Alguns payloads aninham número longo
    final longVal = raw[r'$numberLong'] ?? raw['\$numberLong'];
    if (longVal != null) {
      final ms = int.tryParse(longVal.toString());
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
    }
  }
  return DateTime.tryParse(raw.toString());
}

double coerceMongoNumber(dynamic raw) {
  if (raw == null) return 0.0;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString()) ?? 0.0;
}

/// Inclusivo por dia civil (hora do documento é ignorada na comparação de limites).
bool metricDocInSelectedRange(
  DateTime docDateTime,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final d = DateTime(docDateTime.year, docDateTime.month, docDateTime.day);
  final s = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final e = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  return !d.isBefore(s) && !d.isAfter(e);
}

double chartMaxYFromValues(
  Iterable<double> values, {
  required double minWhenEmptyOrZero,
}) {
  final list = values.where((v) => v.isFinite).toList();
  if (list.isEmpty) return minWhenEmptyOrZero;
  final m = list.reduce((a, b) => a > b ? a : b);
  if (m <= 0) return minWhenEmptyOrZero;
  return m * 1.2;
}
