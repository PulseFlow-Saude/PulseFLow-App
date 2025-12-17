class AccessHistory {
  final String id;
  final String medicoId;
  final String medicoNome;
  final String medicoEspecialidade;
  final DateTime dataHora;
  final DateTime? desconectadoEm;
  final bool isActive;
  final int? duracao;

  AccessHistory({
    required this.id,
    required this.medicoId,
    required this.medicoNome,
    required this.medicoEspecialidade,
    required this.dataHora,
    this.desconectadoEm,
    required this.isActive,
    this.duracao,
  });

  factory AccessHistory.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) {
        return dateValue.toLocal();
      }
      if (dateValue is String) {
        final parsed = DateTime.tryParse(dateValue);
        if (parsed != null) {
          return parsed.toLocal();
        }
        return DateTime.now();
      }
      if (dateValue is Map && dateValue['\$date'] != null) {
        final dateData = dateValue['\$date'];
        if (dateData is String) {
          final parsed = DateTime.tryParse(dateData);
          if (parsed != null) {
            return parsed.toLocal();
          }
        } else if (dateData is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateData, isUtc: true).toLocal();
        }
        final dateStr = dateData.toString();
        if (dateStr.contains('T')) {
          final parsed = DateTime.tryParse(dateStr);
          if (parsed != null) {
            return parsed.toLocal();
          }
        }
        final milliseconds = int.tryParse(dateStr);
        if (milliseconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true).toLocal();
        }
      }
      return DateTime.now();
    }

    return AccessHistory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      medicoId: json['medicoId']?.toString() ?? '',
      medicoNome: json['medicoNome']?.toString() ?? 'Médico não informado',
      medicoEspecialidade: json['medicoEspecialidade']?.toString() ?? 'Não informado',
      dataHora: parseDateTime(json['dataHora']),
      desconectadoEm: json['desconectadoEm'] != null 
          ? parseDateTime(json['desconectadoEm']) 
          : null,
      isActive: json['isActive'] as bool? ?? false,
      duracao: json['duracao'] != null 
          ? (json['duracao'] is int ? json['duracao'] as int : int.tryParse(json['duracao'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicoId': medicoId,
      'medicoNome': medicoNome,
      'medicoEspecialidade': medicoEspecialidade,
      'dataHora': dataHora.toIso8601String(),
      'desconectadoEm': desconectadoEm?.toIso8601String(),
      'isActive': isActive,
      'duracao': duracao,
    };
  }

  String get duracaoFormatada {
    if (duracao == null) return 'Em andamento';
    
    final segundos = duracao!;
    if (segundos < 60) return '${segundos}s';
    
    final minutos = segundos ~/ 60;
    if (minutos < 60) return '${minutos}min';
    
    final horas = minutos ~/ 60;
    final minutosRestantes = minutos % 60;
    if (horas < 24) return '${horas}h ${minutosRestantes}min';
    
    final dias = horas ~/ 24;
    final horasRestantes = horas % 24;
    return '${dias}d ${horasRestantes}h';
  }
}

