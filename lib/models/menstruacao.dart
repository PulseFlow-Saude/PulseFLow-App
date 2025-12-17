import 'package:mongo_dart/mongo_dart.dart';

class DiaMenstruacao {
  final String fluxo; // "Intenso", "Moderado", "Leve"
  final bool teveColica;
  final String humor; // "Ansioso", "Raiva", "Cansado", "Triste", "Feliz", etc.

  DiaMenstruacao({
    required this.fluxo,
    required this.teveColica,
    required this.humor,
  });

  factory DiaMenstruacao.fromJson(Map<String, dynamic> json) {
    return DiaMenstruacao(
      fluxo: json['fluxo'] as String,
      teveColica: json['teveColica'] as bool,
      humor: json['humor'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fluxo': fluxo,
      'teveColica': teveColica,
      'humor': humor,
    };
  }
}

class Menstruacao {
  final String? id;
  final String? pacienteId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Map<String, DiaMenstruacao>? diasPorData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menstruacao({
    this.id,
    this.pacienteId,
    required this.dataInicio,
    required this.dataFim,
    this.diasPorData,
    this.createdAt,
    this.updatedAt,
  });

  factory Menstruacao.fromJson(Map<String, dynamic> json) {
    Map<String, DiaMenstruacao>? diasPorData;
    if (json['diasPorData'] != null) {
      diasPorData = <String, DiaMenstruacao>{};
      final diasData = json['diasPorData'] as Map<String, dynamic>;
      diasData.forEach((data, dados) {
        diasPorData![data] = DiaMenstruacao.fromJson(dados as Map<String, dynamic>);
      });
    }

    return Menstruacao(
      id: json['_id'] is ObjectId ? json['_id'].toHexString() : json['_id'] as String?,
      pacienteId: json['pacienteId'] is ObjectId ? json['pacienteId'].toHexString() : json['pacienteId'] as String?,
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      diasPorData: diasPorData,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? diasPorDataJson;
    if (diasPorData != null) {
      diasPorDataJson = <String, dynamic>{};
      diasPorData!.forEach((data, dia) {
        diasPorDataJson![data] = dia.toJson();
      });
    }

    return {
      if (id != null) '_id': ObjectId.parse(id!),
      if (pacienteId != null) 'pacienteId': ObjectId.parse(pacienteId!),
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      if (diasPorDataJson != null) 'diasPorData': diasPorDataJson,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Menstruacao copyWith({
    String? id,
    String? pacienteId,
    DateTime? dataInicio,
    DateTime? dataFim,
    Map<String, DiaMenstruacao>? diasPorData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Menstruacao(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      diasPorData: diasPorData ?? this.diasPorData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calcula a duração do ciclo em dias
  int get duracaoEmDias {
    return dataFim.difference(dataInicio).inDays + 1;
  }

  // Verifica se a menstruação está ativa (hoje está entre dataInicio e dataFim)
  bool get isAtiva {
    final hoje = DateTime.now();
    return hoje.isAfter(dataInicio.subtract(const Duration(days: 1))) && 
           hoje.isBefore(dataFim.add(const Duration(days: 1)));
  }

  // Retorna o status da menstruação
  String get status {
    final hoje = DateTime.now();
    if (hoje.isBefore(dataInicio)) {
      return 'Próxima';
    } else if (hoje.isAfter(dataFim)) {
      return 'Finalizada';
    } else {
      return 'Ativa';
    }
  }
}
