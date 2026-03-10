DateTime _nowInBrazil(DateTime reference) {
  final utc = reference.toUtc();
  return utc.subtract(const Duration(hours: 3));
}

/// Retorna a chave de tradução da saudação (ex: 'greeting_dawn').
/// Use .tr no resultado para obter o texto traduzido.
String buildGreetingMessage({DateTime? reference}) {
  final base = reference ?? DateTime.now();
  final brazilNow = _nowInBrazil(base);
  final hour = brazilNow.hour;
  if (hour < 6) return 'greeting_dawn';
  if (hour < 12) return 'greeting_morning';
  if (hour < 18) return 'greeting_afternoon';
  return 'greeting_evening';
}
