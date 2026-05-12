class HealthData {
  final String? id;
  final String patientId;
  final String dataType; // 'heartRate', 'sleep', 'steps'
  final double value;
  final DateTime date;
  final String? source; // 'HealthKit', 'Manual', 'Smartwatch'
  final Map<String, dynamic>? metadata; // Dados adicionais como qualidade do sono
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthData({
    this.id,
    required this.patientId,
    required this.dataType,
    required this.value,
    required this.date,
    this.source,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Converte para Map para salvar no MongoDB
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'dataType': dataType,
      'value': value,
      'date': date,
      'source': source ?? 'HealthKit',
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _coerceDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  static double _coerceDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  /// [dataTypeHint] — documentos das coleções `batimentos` / `passos` / `insonias`
  /// guardam chaves em PT (`pacienteId`, `valor`, `data`, `fonte`) sem `dataType`.
  factory HealthData.fromMap(Map<String, dynamic> map, [String? dataTypeHint]) {
    final dynamic pid = map['patientId'] ?? map['pacienteId'];
    final patientId = pid?.toString() ?? '';

    final dataType =
        (dataTypeHint ?? map['dataType'])?.toString() ?? '';

    final value = _coerceDouble(map['value'] ?? map['valor']);

    final rawDate = map['date'] ?? map['data'];
    final date = _coerceDate(rawDate);
    if (date == null) {
      throw FormatException('HealthData.fromMap: campo de data em falta ou inválido');
    }

    final source = map['source']?.toString() ?? map['fonte']?.toString();

    DateTime coalesceTs(dynamic v) {
      final d = _coerceDate(v);
      return d ?? DateTime.now();
    }

    return HealthData(
      id: map['_id']?.toString(),
      patientId: patientId,
      dataType: dataType,
      value: value,
      date: date,
      source: source,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      createdAt: coalesceTs(map['createdAt']),
      updatedAt: coalesceTs(map['updatedAt']),
    );
  }

  // Cria uma cópia com novos valores
  HealthData copyWith({
    String? id,
    String? patientId,
    String? dataType,
    double? value,
    DateTime? date,
    String? source,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthData(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dataType: dataType ?? this.dataType,
      value: value ?? this.value,
      date: date ?? this.date,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HealthData(id: $id, patientId: $patientId, dataType: $dataType, value: $value, date: $date, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthData &&
        other.id == id &&
        other.patientId == patientId &&
        other.dataType == dataType &&
        other.value == value &&
        other.date == date &&
        other.source == source;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        patientId.hashCode ^
        dataType.hashCode ^
        value.hashCode ^
        date.hashCode ^
        source.hashCode;
  }
}

