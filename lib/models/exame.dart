class Exame {
  final String? id;
  final String nome;
  final String categoria;
  final DateTime data;
  final String filePath;
  final String paciente; // referencia ao paciente (ObjectId em string)

  Exame({
    this.id,
    required this.nome,
    required this.categoria,
    required this.data,
    required this.filePath,
    required this.paciente,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'nome': nome,
      'categoria': categoria,
      'data': data.toIso8601String(),
      'filePath': filePath,
      'paciente': paciente,
    };
  }

  factory Exame.fromMap(Map<String, dynamic> map) {
    String? extractId(dynamic idValue) {
      if (idValue == null) return null;
      if (idValue is String) return idValue;
      if (idValue is Map && idValue['\$oid'] != null) {
        return idValue['\$oid'].toString();
      }
      return idValue.toString();
    }

    String extractPaciente(dynamic pacienteValue) {
      if (pacienteValue == null) return '';
      if (pacienteValue is String) return pacienteValue;
      if (pacienteValue is Map && pacienteValue['\$oid'] != null) {
        return pacienteValue['\$oid'].toString();
      }
      return pacienteValue.toString();
    }

    return Exame(
      id: extractId(map['_id']),
      nome: map['nome']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? '',
      data: DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
      filePath: map['filePath']?.toString() ?? '',
      paciente: extractPaciente(map['paciente']),
    );
  }
}


