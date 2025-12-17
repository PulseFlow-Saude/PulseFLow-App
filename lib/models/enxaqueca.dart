class Enxaqueca {
  final String? id;
  final String pacienteId;
  final DateTime data;
  final String intensidade;
  final int duracao;

  Enxaqueca({
    this.id,
    required this.pacienteId,
    required this.data,
    required this.intensidade,
    required this.duracao,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'pacienteId': pacienteId,
      'data': data.toIso8601String(),
      'intensidade': intensidade,
      'duracao': duracao,
    };
  }

  factory Enxaqueca.fromMap(Map<String, dynamic> map) {
    DateTime data;
    if (map['data'] is DateTime) {
      data = map['data'] as DateTime;
    } else if (map['data'] is Map) {
      final dateValue = map['data']['\$date'] ?? map['data'];
      if (dateValue is int) {
        data = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        data = DateTime.parse(dateValue.toString());
      }
    } else if (map['data'] is int) {
      data = DateTime.fromMillisecondsSinceEpoch(map['data'] as int);
    } else {
      data = DateTime.parse(map['data'].toString());
    }
    
    return Enxaqueca(
      id: map['_id']?.toString(),
      pacienteId: map['pacienteId']?.toString() ?? '',
      data: data,
      intensidade: map['intensidade']?.toString() ?? '',
      duracao: (map['duracao'] is int)
          ? map['duracao'] as int
          : (map['duracao'] as num?)?.toInt() ?? 0,
    );
  }
}
