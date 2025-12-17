class Hormonal {
  final String? id;
  final String paciente; // ObjectId em string
  final String hormonio;
  final double valor;
  final DateTime data;

  Hormonal({
    this.id,
    required this.paciente,
    required this.hormonio,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'paciente': paciente,
      'hormonio': hormonio,
      'valor': valor,
      'data': data.toIso8601String(),
    };
  }

  factory Hormonal.fromMap(Map<String, dynamic> map) {
    return Hormonal(
      id: map['_id']?.toString(),
      paciente: map['paciente']?.toString() ?? '',
      hormonio: map['hormonio']?.toString() ?? '',
      valor: (map['valor'] is int)
          ? (map['valor'] as int).toDouble()
          : (map['valor'] as num).toDouble(),
      data: DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}


