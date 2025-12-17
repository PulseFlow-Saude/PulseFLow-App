DateTime _nowInBrazil(DateTime reference) {
  final utc = reference.toUtc();
  return utc.subtract(const Duration(hours: 3));
}

String buildGreetingMessage({DateTime? reference}) {
  final base = reference ?? DateTime.now();
  final brazilNow = _nowInBrazil(base);
  final hour = brazilNow.hour;
  if (hour < 6) return 'Boa madrugada,';
  if (hour < 12) return 'Bom dia,';
  if (hour < 18) return 'Boa tarde,';
  return 'Boa noite,';
}
