class PressaoArterial {
  final String? id;
  final String pacienteId;
  final DateTime data;
  final double sistolica; // mmHg
  final double diastolica; // mmHg

  PressaoArterial({
    this.id,
    required this.pacienteId,
    required this.data,
    required this.sistolica,
    required this.diastolica,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'pacienteId': pacienteId,
      'data': data.toIso8601String(),
      'sistolica': sistolica,
      'diastolica': diastolica,
    };
  }

  factory PressaoArterial.fromMap(Map<String, dynamic> map) {
    return PressaoArterial(
      id: map['_id']?.toString(),
      pacienteId: map['pacienteId']?.toString() ?? '',
      data: DateTime.parse(map['data'].toString()),
      sistolica: (map['sistolica'] is num) ? (map['sistolica'] as num).toDouble() : double.tryParse(map['sistolica'].toString()) ?? 0,
      diastolica: (map['diastolica'] is num) ? (map['diastolica'] as num).toDouble() : double.tryParse(map['diastolica'].toString()) ?? 0,
    );
  }
}


