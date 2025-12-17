class Diabetes {
  final String? id;
  final String pacienteId;
  final DateTime data;
  final double glicemia;
  final String unidade; // mg/dL ou mmol/L

  Diabetes({
    this.id,
    required this.pacienteId,
    required this.data,
    required this.glicemia,
    required this.unidade,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'pacienteId': pacienteId,
      'data': data.toIso8601String(),
      'glicemia': glicemia,
      'unidade': unidade,
    };
  }

  factory Diabetes.fromMap(Map<String, dynamic> map) {
    final pacienteId = map['pacienteId']?.toString() ?? 
                       map['paciente']?.toString() ?? '';
    
    final glicemiaValue = map['glicemia'] ?? map['nivelGlicemia'];
    final glicemia = (glicemiaValue is int)
        ? glicemiaValue.toDouble()
        : (glicemiaValue as num?)?.toDouble() ?? 0.0;
    
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
    
    return Diabetes(
      id: map['_id']?.toString(),
      pacienteId: pacienteId,
      data: data,
      glicemia: glicemia,
      unidade: map['unidade']?.toString() ?? 'mg/dL',
    );
  }
}
