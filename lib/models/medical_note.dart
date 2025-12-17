class MedicalNote {
  final String id;
  final String patientId;
  final String titulo;
  final String categoria;
  final String medico;
  final DateTime data;

  MedicalNote({
    required this.id,
    required this.patientId,
    required this.titulo,
    required this.categoria,
    required this.medico,
    required this.data,
  });

  factory MedicalNote.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['data'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is Map && rawDate['date'] != null) {
      parsedDate = DateTime.tryParse(rawDate['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
    }

    return MedicalNote(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      // Tolerante a chaves alternativas
      titulo: (json['titulo'] ?? json['motivoConsulta'])?.toString() ?? '',
      categoria: (json['categoria'] ?? json['especialidade'])?.toString() ?? '',
      medico: (json['medico'] ?? json['medicoResponsavel'])?.toString() ?? '',
      data: parsedDate,
    );
  }
}


