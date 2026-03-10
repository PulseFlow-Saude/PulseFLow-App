class Patient {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String cpf;
  final String rg;
  final String phone;
  final String? secondaryPhone;
  final DateTime birthDate;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String address;
  final double? height; // Altura em cm
  final double? weight; // Peso em kg
  final String? profession; // Profissão
  final bool acceptedTerms; // aceitou os termos de uso, política de privacidade e uso de dados
  final bool isAdmin; // indica se o usuário é administrador
  final String? profilePhoto; // URL ou base64 da foto de perfil
  final String? emergencyContact; // Nome do contato de emergência
  final String? emergencyPhone; // Telefone do contato de emergência
  final String? fcmToken; // Token para notificações push
  final String? twoFactorCode; // Código 2FA
  final DateTime? twoFactorExpires; // Expiração do código 2FA
  final String? passwordResetCode; // Código de redefinição de senha
  final DateTime? passwordResetExpires; // Expiração do código de redefinição
  final bool passwordResetRequired; // Indica se a senha precisa ser redefinida (após migração)
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.cpf,
    required this.rg,
    required this.phone,
    this.secondaryPhone,
    required this.birthDate,
    required this.gender,
    required this.maritalStatus,
    required this.nationality,
    required this.address,
    this.height, // Campo opcional para altura
    this.weight, // Campo opcional para peso
    this.profession, // Campo opcional para profissão
    required this.acceptedTerms,
    this.profilePhoto, // Campo opcional para foto de perfil
    this.emergencyContact, // Campo opcional para contato de emergência
    this.emergencyPhone, // Campo opcional para telefone de emergência
    this.fcmToken, // Campo opcional para token de notificações push
    this.isAdmin = false, // por padrão, usuários não são admin
    this.twoFactorCode,
    this.twoFactorExpires,
    this.passwordResetCode,
    this.passwordResetExpires,
    this.passwordResetRequired = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'cpf': cpf,
      'rg': rg,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      'address': address,
      'height': height, // Incluir altura no JSON
      'weight': weight, // Incluir peso no JSON
      'profession': profession, // Incluir profissão no JSON
      'acceptedTerms': acceptedTerms,
      'profilePhoto': profilePhoto, // Incluir foto de perfil no JSON
      'emergencyContact': emergencyContact, // Incluir contato de emergência no JSON
      'emergencyPhone': emergencyPhone, // Incluir telefone de emergência no JSON
      'fcmToken': fcmToken, // Incluir token FCM no JSON
      'isAdmin': isAdmin,
      'twoFactorCode': twoFactorCode,
      'twoFactorExpires': twoFactorExpires?.toIso8601String(),
      'passwordResetCode': passwordResetCode,
      'passwordResetExpires': passwordResetExpires?.toIso8601String(),
      'passwordResetRequired': passwordResetRequired,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String? _parseProfilePhoto(Map<String, dynamic> json) {
    final raw = json['profilePhoto'] ?? json['fotoPerfil'] ?? json['foto'];
    if (raw == null) return null;
    if (raw is String) return raw.isEmpty ? null : raw;
    return raw.toString();
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final birthDateStr = json['birthDate'] ?? json['dataNascimento'];
    final createdAtStr = json['createdAt'];
    final updatedAtStr = json['updatedAt'];
    return Patient(
      id: json['_id']?.toString(),
      name: json['name'] ?? json['nome'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? json['senha'] ?? '',
      cpf: json['cpf'] ?? '',
      rg: json['rg'] ?? '',
      phone: json['phone'] ?? json['telefone'] ?? '',
      secondaryPhone: json['secondaryPhone'],
      birthDate: birthDateStr != null ? DateTime.tryParse(birthDateStr.toString()) ?? DateTime.now() : DateTime.now(),
      gender: json['gender'] ?? json['genero'] ?? '',
      maritalStatus: json['maritalStatus'] ?? '',
      nationality: json['nationality'] ?? json['nacionalidade'] ?? '',
      address: json['address'] ?? '',
      height: json['height'] != null ? (json['height'] as num).toDouble() : (json['altura'] != null ? double.tryParse(json['altura'].toString()) : null),
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : (json['peso'] != null ? double.tryParse(json['peso'].toString()) : null),
      profession: json['profession'] ?? json['profissao'],
      acceptedTerms: json['acceptedTerms'] ?? false,
      profilePhoto: _parseProfilePhoto(json),
      emergencyContact: json['emergencyContact'],
      emergencyPhone: json['emergencyPhone'],
      fcmToken: json['fcmToken'],
      isAdmin: json['isAdmin'] ?? false,
      twoFactorCode: json['twoFactorCode'],
      twoFactorExpires: json['twoFactorExpires'] != null ? DateTime.tryParse(json['twoFactorExpires'].toString()) : null,
      passwordResetCode: json['passwordResetCode'],
      passwordResetExpires: json['passwordResetExpires'] != null ? DateTime.tryParse(json['passwordResetExpires'].toString()) : null,
      passwordResetRequired: json['passwordResetRequired'] ?? false,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr.toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
} 