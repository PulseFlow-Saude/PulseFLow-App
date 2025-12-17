class EventoClinico {
  final String? id;
  final String paciente;
  final String titulo;
  final DateTime dataHora;
  final String tipoEvento;
  final String especialidade;
  final String intensidadeDor;
  final String alivio;
  final String descricao;
  final String sintomas;

  EventoClinico({
    this.id,
    required this.paciente,
    required this.titulo,
    required this.dataHora,
    required this.tipoEvento,
    required this.especialidade,
    required this.intensidadeDor,
    required this.alivio,
    required this.descricao,
    required this.sintomas,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'paciente': paciente,
      'titulo': titulo,
      'dataHora': dataHora.toIso8601String(),
      'tipoEvento': tipoEvento,
      'especialidade': especialidade,
      'intensidadeDor': intensidadeDor,
      'alivio': alivio,
      'descricao': descricao,
      'sintomas': sintomas,
    };
  }

  factory EventoClinico.fromMap(Map<String, dynamic> map) {
    return EventoClinico(
      id: map['_id']?.toString(),
      paciente: map['paciente']?.toString() ?? '',
      titulo: map['titulo'] ?? '',
      dataHora: DateTime.tryParse(map['dataHora']?.toString() ?? '') ?? DateTime.now(),
      tipoEvento: map['tipoEvento'] ?? '',
      especialidade: map['especialidade'] ?? '',
      intensidadeDor: map['intensidadeDor']?.toString() ?? '0',
      alivio: map['alivio'] ?? '',
      descricao: map['descricao'] ?? '',
      sintomas: map['sintomas'] ?? '',
    );
  }
}


