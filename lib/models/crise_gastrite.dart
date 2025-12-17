import 'package:mongo_dart/mongo_dart.dart';

class CriseGastrite {
  final String? id;
  final String? pacienteId;
  final DateTime data;
  final int intensidadeDor;
  final String sintomas;
  final String alimentosIngeridos;
  final String medicacao;
  final bool alivioMedicacao;
  final String observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CriseGastrite({
    this.id,
    this.pacienteId,
    required this.data,
    required this.intensidadeDor,
    required this.sintomas,
    required this.alimentosIngeridos,
    required this.medicacao,
    required this.alivioMedicacao,
    required this.observacoes,
    this.createdAt,
    this.updatedAt,
  });

  factory CriseGastrite.fromJson(Map<String, dynamic> json) {
    return CriseGastrite(
      id: json['_id'] is ObjectId ? json['_id'].toHexString() : json['_id'] as String?,
      pacienteId: json['paciente'] is ObjectId ? json['paciente'].toHexString() : json['paciente'] as String,
      data: DateTime.parse(json['data']),
      intensidadeDor: json['intensidadeDor'],
      sintomas: json['sintomas'],
      alimentosIngeridos: json['alimentosIngeridos'],
      medicacao: json['medicacao'],
      alivioMedicacao: json['alivioMedicacao'],
      observacoes: json['observacoes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': ObjectId.parse(id!),
      if (pacienteId != null) 'paciente': ObjectId.parse(pacienteId!),
      'data': data.toIso8601String(),
      'intensidadeDor': intensidadeDor,
      'sintomas': sintomas,
      'alimentosIngeridos': alimentosIngeridos,
      'medicacao': medicacao,
      'alivioMedicacao': alivioMedicacao,
      'observacoes': observacoes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  CriseGastrite copyWith({
    String? id,
    String? pacienteId,
    DateTime? data,
    int? intensidadeDor,
    String? sintomas,
    String? alimentosIngeridos,
    String? medicacao,
    bool? alivioMedicacao,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CriseGastrite(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      data: data ?? this.data,
      intensidadeDor: intensidadeDor ?? this.intensidadeDor,
      sintomas: sintomas ?? this.sintomas,
      alimentosIngeridos: alimentosIngeridos ?? this.alimentosIngeridos,
      medicacao: medicacao ?? this.medicacao,
      alivioMedicacao: alivioMedicacao ?? this.alivioMedicacao,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
