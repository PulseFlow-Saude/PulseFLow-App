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

  // Cria instância a partir do Map do MongoDB
  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      id: map['_id']?.toString(),
      patientId: map['patientId'] ?? '',
      dataType: map['dataType'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      date: map['date'] is DateTime ? map['date'] : DateTime.parse(map['date']),
      source: map['source'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      createdAt: map['createdAt'] is DateTime ? map['createdAt'] : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is DateTime ? map['updatedAt'] : DateTime.parse(map['updatedAt']),
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

