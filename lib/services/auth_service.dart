import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/patient.dart';
import '../config/app_config.dart';
import 'database_service.dart';
import 'encryption_service.dart';
import 'notification_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';


class AuthService extends GetxController {
  static AuthService get instance => Get.find<AuthService>();
  final _storage = const FlutterSecureStorage();
  final _token = ''.obs;
  final _isAuthenticated = false.obs;
  final _currentUser = Rxn<Patient>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final EncryptionService _encryptionService = EncryptionService();

  String get token => _token.value;
  bool get isAuthenticated => _isAuthenticated.value;
  Patient? get currentUser => _currentUser.value;
  set currentUser(Patient? user) => _currentUser.value = user;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  // Inicialização do serviço
  Future<AuthService> init() async {
    await _checkAuthStatus();
    return this;
  }

  // Verifica se há um token válido
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        final patientId = JwtDecoder.decode(token)['sub'];
        final patient = await getPatientById(patientId);
        if (patient != null) {
          _token.value = token; // Definir o token no reativo
          _currentUser.value = patient;
          _isAuthenticated.value = true;
        } else {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  // Gera token JWT
  String _generateToken(Patient patient) {
    if (patient.id == null) {
      throw 'ID do paciente não encontrado';
    }

    if (patient.id!.isEmpty) {
      throw 'ID do paciente está vazio';
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7)); // Token válido por 7 dias

    final payload = {
      'sub': patient.id,
      'email': patient.email,
      'name': patient.name,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    };

    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    String base64UrlEncode(List<int> bytes) {
      final base64 = base64Encode(bytes);
      return base64
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');
    }
    
    final encodedHeader = base64UrlEncode(utf8.encode(json.encode(header)));
    final encodedPayload = base64UrlEncode(utf8.encode(json.encode(payload)));
    
    final jwtSecret = AppConfig.jwtSecret;
    
    final signature = Hmac(sha256, utf8.encode(jwtSecret))
        .convert(utf8.encode('$encodedHeader.$encodedPayload'))
        .bytes;
    final encodedSignature = base64UrlEncode(signature);

    final token = '$encodedHeader.$encodedPayload.$encodedSignature';
    
    return token;
  }

  // Gera código 2FA de 6 dígitos
  String _generate2FACode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // Configura servidor SMTP baseado no domínio do email
  SmtpServer _getSmtpServer(String user, String pass) {
    final domain = user.split('@').last.toLowerCase();
    
    switch (domain) {
      case 'gmail.com':
        return gmail(user, pass);
      case 'outlook.com':
      case 'hotmail.com':
      case 'live.com':
        return SmtpServer('smtp-mail.outlook.com',
            port: 587,
            username: user,
            password: pass,
            ssl: false,
            allowInsecure: false);
      case 'yahoo.com':
        return SmtpServer('smtp.mail.yahoo.com',
            port: 587,
            username: user,
            password: pass,
            ssl: false,
            allowInsecure: false);
      case 'icloud.com':
        return SmtpServer('smtp.mail.me.com',
            port: 587,
            username: user,
            password: pass,
            ssl: false,
            allowInsecure: false);
      case 'aol.com':
        return SmtpServer('smtp.aol.com',
            port: 587,
            username: user,
            password: pass,
            ssl: false,
            allowInsecure: false);
      default:
        // Para outros domínios, tenta configuração genérica
        // Muitos provedores usam smtp.[dominio] na porta 587
        return SmtpServer('smtp.$domain',
            port: 587,
            username: user,
            password: pass,
            ssl: false,
            allowInsecure: false);
    }
  }

  // Envia código 2FA por e-mail
  Future<void> send2FACodeEmail(String email, String code) async {
    try {
      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;
      
      if (user.isEmpty || pass.isEmpty) {
        throw 'Configurações de email não encontradas. Verifique o arquivo .env';
      }
      
      final smtpServer = _getSmtpServer(user, pass);
      final message = Message()
        ..from = Address(user, 'PulseFlow Saúde')
        ..recipients.add(email)
        ..subject = 'Código de verificação 2FA - PulseFlow'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #1CB5E0 0%, #000046 100%); padding: 30px; border-radius: 15px; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 24px;">Verificação em Duas Etapas</h1>
              <p style="color: white; margin: 10px 0 0 0; opacity: 0.9;">PulseFlow Saúde</p>
            </div>
            
            <div style="background: white; padding: 30px; border-radius: 0 0 15px 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
              <h2 style="color: #333; margin: 0 0 20px 0;">Olá!</h2>
              <p style="color: #666; line-height: 1.6; margin: 0 0 20px 0;">
                Você solicitou acesso ao seu perfil no PulseFlow Saúde. Para continuar, use o código de verificação abaixo:
              </p>
              
              <div style="background: #f8f9fa; border: 2px dashed #1CB5E0; border-radius: 10px; padding: 20px; margin: 20px 0; text-align: center;">
                <h3 style="color: #1CB5E0; margin: 0; font-size: 32px; letter-spacing: 8px; font-weight: bold;">$code</h3>
                <p style="color: #666; margin: 10px 0 0 0; font-size: 14px;">Código de 6 dígitos</p>
              </div>
              
              <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 15px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                  ⏰ <strong>Importante:</strong> Este código expira em 5 minutos por segurança.
                </p>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin: 20px 0 0 0; font-size: 14px;">
                Se você não solicitou este código, ignore este e-mail ou entre em contato conosco.
              </p>
              
              <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                PulseFlow Saúde - Cuidando da sua saúde com tecnologia
              </p>
            </div>
          </div>
        ''';
      
      await send(message, smtpServer);
    } catch (e) {
      throw 'Erro ao enviar email: $e';
    }
  }

  // Login com 2FA 
  // Retorna o ID do paciente:
  // - Para usuários admin: retorna o ID diretamente (bypass 2FA)
  // - Para usuários normais: retorna o ID após gerar e enviar código 2FA
  Future<String> loginWith2FA(String email, String password) async {
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'Paciente não encontrado. Verifique se digitou corretamente o e-mail, incluindo maiúsculas e minúsculas.';
      }
      
      // Verifica se o usuário precisa redefinir a senha após migração
      if (patient.passwordResetRequired) {
        throw 'Sua senha foi atualizada. Por favor, use a funcionalidade "Esqueci minha senha" para redefinir.';
      }
      
      final isValidPassword = await _encryptionService.verifyPassword(
        password,
        patient.password,
      );
      if (!isValidPassword) {
        throw 'Senha incorreta. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }
      
      // Se o usuário for admin, retorna o ID diretamente sem 2FA
      if (patient.isAdmin) {
        return patient.id!;
      }
      
      // Para usuários não-admin, continua com o fluxo 2FA
      final code = _generate2FACode();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      
      final patientIdString = patient.id!;
      
      await _databaseService.setTwoFactorCode(patientIdString, code, expires);
      
      // Enviar código por email automaticamente
      await send2FACodeEmail(patient.email, code);
      
      // Retorna o ID para o controller fazer o redirecionamento
      return patientIdString;
    } catch (e) {
      rethrow;
    }
  }

  // Valida o código 2FA e finaliza o login (ou finaliza login direto para admin)
  // Para usuários admin: ignora o código e finaliza login diretamente
  // Para usuários normais: valida o código 2FA antes de finalizar
  Future<Patient> verify2FACode(String patientId, String code) async {
    final patient = await _databaseService.getPatientById(ObjectId.parse(patientId));
    if (patient == null) throw 'Paciente não encontrado';
    
    // Se o usuário for admin, valida diretamente sem verificar código 2FA
    if (patient.isAdmin) {
    // Gera o token JWT e autentica
    final token = _generateToken(patient);
    await _storage.write(key: 'auth_token', value: token);
    _token.value = token;
    _isAuthenticated.value = true;
    _currentUser.value = patient;
    
    // Atualizar FCM Token após login
    await updateFcmToken();
    
    // Retorna o paciente autenticado (redirecionamento será feito no controller)
    return patient;
    }
    
    // Para usuários não-admin, valida o código 2FA
    final isValid = await _databaseService.validateTwoFactorCode(patientId, code);
    if (!isValid) throw 'Código de verificação inválido ou expirado';
    
    // Gera o token JWT e autentica
    final token = _generateToken(patient);
    await _storage.write(key: 'auth_token', value: token);
    _token.value = token;
    _isAuthenticated.value = true;
    _currentUser.value = patient;
    
    // Atualizar FCM Token após login
    await updateFcmToken();
    
    // Retorna o paciente autenticado (redirecionamento será feito na tela)
    return patient;
  }

  // Busca paciente por ID
  Future<Patient?> getPatientById(String patientId) async {
    try {
      return await _databaseService.getPatientById(ObjectId.parse(patientId));
    } catch (e) {
      return null;
    }
  }

  // Reenvia código 2FA
  Future<void> resend2FACode(String patientId, {String? method}) async {
    try {
      final patient = await _databaseService.getPatientById(ObjectId.parse(patientId));
      if (patient == null) throw 'Paciente não encontrado';
      
      final code = _generate2FACode();
      final expires = DateTime.now().add(const Duration(minutes: 5));
      
      await _databaseService.setTwoFactorCode(patientId, code, expires);
      
      // Sempre enviar por email
      await send2FACodeEmail(patient.email, code);
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<Patient> login(String email, String password) async {
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      
      if (patient == null) {
        throw 'Paciente não encontrado. Verifique se digitou corretamente o e-mail, incluindo maiúsculas e minúsculas.';
      }

      // Verifica se o usuário precisa redefinir a senha após migração
      if (patient.passwordResetRequired) {
        throw 'Sua senha foi atualizada pela equipe de suporte. Por favor, use a funcionalidade "Esqueci minha senha" para redefinir.';
      }

      // Verifica a senha usando o serviço de criptografia
      final isValidPassword = await _encryptionService.verifyPassword(
        password,
        patient.password,
      );

      if (!isValidPassword) {
        throw 'Senha incorreta. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }

      // Gera o token JWT
      final token = _generateToken(patient);
      await _storage.write(key: 'auth_token', value: token);
      
      _token.value = token;
      _isAuthenticated.value = true;
      _currentUser.value = patient;

      // Atualizar FCM Token após login
      await updateFcmToken();

      return patient;
    } catch (e) {
      _token.value = '';
      _isAuthenticated.value = false;
      _currentUser.value = null;
      rethrow;
    }
  }

  // Registro
  Future<Patient> register(Patient patient) async {
    try {
      // Verificar se o e-mail já existe
      final existingPatient = await _databaseService.getPatientByEmail(patient.email);
      if (existingPatient != null) {
        throw 'E-mail já cadastrado';
      }

      // Criptografar senha com o novo formato (salt:hash)
      final hashedPassword = await _encryptionService.hashPassword(patient.password);
      
      // Cria uma nova instância com a senha criptografada
      final patientWithHashedPassword = Patient(
        name: patient.name,
        email: patient.email,
        password: hashedPassword,
        cpf: patient.cpf,
        rg: patient.rg,
        phone: patient.phone,
        secondaryPhone: patient.secondaryPhone,
        birthDate: patient.birthDate,
        gender: patient.gender,
        maritalStatus: patient.maritalStatus,
        nationality: patient.nationality,
        address: patient.address,
        height: patient.height, // Incluir altura
        weight: patient.weight, // Incluir peso
        profession: patient.profession, // Incluir profissão
        acceptedTerms: patient.acceptedTerms,
        profilePhoto: patient.profilePhoto, // Incluir foto de perfil
        isAdmin: false, // por padrão, usuários não são admin
        passwordResetRequired: false, // nova senha não precisa de redefinição
      );

      // Salvar no banco de dados
      final createdPatient = await _databaseService.createPatient(patientWithHashedPassword);
      
      if (createdPatient.id == null || createdPatient.id!.isEmpty) {
        throw 'Erro ao criar paciente: ID não foi gerado';
      }

      // Gerar token JWT
      final token = _generateToken(createdPatient);
      await _storage.write(key: 'auth_token', value: token);
      
      _token.value = token;
      _isAuthenticated.value = true;
      _currentUser.value = createdPatient;

      return createdPatient;
    } catch (e) {
      rethrow;
    }
  }

  // Registro de usuário admin
  Future<Patient> registerAdmin(Patient patient) async {
    try {
      // Verificar se o e-mail já existe
      final existingPatient = await _databaseService.getPatientByEmail(patient.email);
      if (existingPatient != null) {
        throw 'E-mail já cadastrado';
      }

      // Criptografar senha com o novo formato (salt:hash)
      final hashedPassword = await _encryptionService.hashPassword(patient.password);
      
      // Cria uma nova instância com a senha criptografada e isAdmin = true
      final adminPatient = Patient(
        name: patient.name,
        email: patient.email,
        password: hashedPassword,
        cpf: patient.cpf,
        rg: patient.rg,
        phone: patient.phone,
        secondaryPhone: patient.secondaryPhone,
        birthDate: patient.birthDate,
        gender: patient.gender,
        maritalStatus: patient.maritalStatus,
        nationality: patient.nationality,
        address: patient.address,
        height: patient.height, // Incluir altura
        weight: patient.weight, // Incluir peso
        profession: patient.profession, // Incluir profissão
        acceptedTerms: patient.acceptedTerms,
        profilePhoto: patient.profilePhoto, // Incluir foto de perfil
        isAdmin: true, // usuário admin
        passwordResetRequired: false, // nova senha não precisa de redefinição
      );

      // Salvar no banco de dados
      final createdAdmin = await _databaseService.createPatient(adminPatient);
      
      if (createdAdmin.id == null || createdAdmin.id!.isEmpty) {
        throw 'Erro ao criar usuário admin: ID não foi gerado';
      }

      // Gerar token JWT
      final token = _generateToken(createdAdmin);
      await _storage.write(key: 'auth_token', value: token);
      
      _token.value = token;
      _isAuthenticated.value = true;
      _currentUser.value = createdAdmin;

      return createdAdmin;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCurrentAccount() async {
    try {
      final user = _currentUser.value;
      if (user == null || user.id == null || user.id!.isEmpty) {
        throw 'Usuário não autenticado';
      }
      final objectId = ObjectId.parse(user.id!);
      await _databaseService.deletePatient(objectId);
      await logout();
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'auth_token');
      _token.value = '';
      _isAuthenticated.value = false;
      _currentUser.value = null;
      
      // Limpar credenciais salvas do "Lembrar-me"
      await _storage.delete(key: 'remember_me');
      await _storage.delete(key: 'saved_email');
      await _storage.delete(key: 'saved_password');
    } catch (e) {
      rethrow;
    }
  }

  // Verificar autenticação
  bool checkAuth() {
    return _token.value.isNotEmpty && _isAuthenticated.value;
  }

  // Verifica se o token está expirado
  Future<bool> isTokenExpired() async {
    try {
      final storedToken = await _storage.read(key: 'auth_token');
      if (storedToken == null) return true;
      return JwtDecoder.isExpired(storedToken);
    } catch (e) {
      return true;
    }
  }

  // Atualiza dados do usuário
  Future<void> updateUserData(Patient updatedPatient) async {
    try {
      // Se a senha foi alterada, criptografa a nova senha com o novo formato
      String password = updatedPatient.password;
      if (currentUser?.password != updatedPatient.password) {
        password = await _encryptionService.hashPassword(updatedPatient.password);
      }

      // Cria uma nova instância com a senha criptografada
      final patientWithHashedPassword = Patient(
        id: updatedPatient.id,
        name: updatedPatient.name,
        email: updatedPatient.email,
        password: password,
        cpf: updatedPatient.cpf,
        rg: updatedPatient.rg,
        phone: updatedPatient.phone,
        secondaryPhone: updatedPatient.secondaryPhone,
        birthDate: updatedPatient.birthDate,
        gender: updatedPatient.gender,
        maritalStatus: updatedPatient.maritalStatus,
        nationality: updatedPatient.nationality,
        address: updatedPatient.address,
        height: updatedPatient.height, // Incluir altura
        weight: updatedPatient.weight, // Incluir peso
        profession: updatedPatient.profession, // Incluir profissão
        acceptedTerms: updatedPatient.acceptedTerms,
        profilePhoto: updatedPatient.profilePhoto, // Incluir foto de perfil
        isAdmin: updatedPatient.isAdmin, // mantém o status de admin
        passwordResetRequired: false, // senha atualizada não precisa de redefinição
      );

      if (updatedPatient.id != null) {
        await updatePatientData(updatedPatient.id!, patientWithHashedPassword);
        _currentUser.value = patientWithHashedPassword;
      }
    } catch (e) {
      rethrow;
    }
  }



  Future<void> updatePatientData(dynamic patientId, Patient updatedPatient) async {
    try {
      // Converter string para ObjectId se necessário
      final objectId = patientId is String ? ObjectId.parse(patientId) : patientId;
      
      await _databaseService.updatePatient(
        objectId,
        updatedPatient,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verifica se o e-mail existe no sistema
  Future<Patient?> checkEmailExists(String email) async {
    try {
      return await _databaseService.getPatientByEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Envia código de redefinição de senha
  Future<void> sendPasswordResetCode(String email) async {
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'E-mail não encontrado. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }

      // Gerar código de redefinição
      final code = _generate2FACode();
      final expires = DateTime.now().add(const Duration(minutes: 10));
      
      // Salvar código no banco
      await _databaseService.setPasswordResetCode(patient.id!, code, expires);
      
      // Enviar e-mail
      await sendPasswordResetEmail(email, code);
    } catch (e) {
      rethrow;
    }
  }

  // Redefine a senha do usuário
  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'E-mail não encontrado. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }

      // Validar código de redefinição
      final isValid = await _databaseService.validatePasswordResetCode(patient.id!, code);
      if (!isValid) {
        throw 'Código de redefinição inválido ou expirado';
      }

      // Criptografar nova senha com o novo formato (salt:hash)
      final hashedPassword = await _encryptionService.hashPassword(newPassword);
      
      // Atualizar senha no banco e remover flag de redefinição necessária
      await _databaseService.updatePatientPassword(patient.id!, hashedPassword);
      
      // Remover a flag passwordResetRequired se existir
      await _databaseService.updatePatientField(
        patient.id!,
        'passwordResetRequired',
        false,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email, String code) async {
    try {
      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;
      
      if (user.isEmpty || pass.isEmpty) {
        return;
      }

      final smtpServer = _getSmtpServer(user, pass);
      final message = Message()
        ..from = Address(user, 'PulseFlow Saúde')
        ..recipients.add(email)
        ..subject = 'Redefinição de Senha - PulseFlow Saúde'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
            <div style="background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
              <div style="text-align: center; margin-bottom: 30px;">
                <div style="background-color: #1CB5E0; width: 60px; height: 60px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; margin-bottom: 20px;">
                  <span style="color: white; font-size: 24px;">🔐</span>
                </div>
                <h1 style="color: #222B45; margin: 0; font-size: 24px;">Redefinição de Senha</h1>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                Olá! Você solicitou a redefinição da sua senha no PulseFlow Saúde.
              </p>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 30px;">
                Use o código abaixo para redefinir sua senha:
              </p>
              
              <div style="background-color: #1CB5E0; color: white; padding: 20px; border-radius: 10px; text-align: center; margin-bottom: 30px;">
                <h2 style="margin: 0; font-size: 32px; letter-spacing: 8px; font-family: monospace;">$code</h2>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                <strong>Este código expira em 10 minutos.</strong>
              </p>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                Se você não solicitou esta redefinição, ignore este e-mail.
              </p>
              
              <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                PulseFlow Saúde - Cuidando da sua saúde com tecnologia
              </p>
            </div>
          </div>
        ''';
      
      await send(message, smtpServer);
    } catch (e) {
      // Silenciosamente falha
    }
  }

  // Método para tornar um usuário admin (apenas para desenvolvimento/administração)
  Future<void> makeUserAdmin(String email) async {
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'Paciente não encontrado';
      }
      
      // Cria uma nova instância com isAdmin = true
      final adminPatient = Patient(
        id: patient.id,
        name: patient.name,
        email: patient.email,
        password: patient.password,
        cpf: patient.cpf,
        rg: patient.rg,
        phone: patient.phone,
        secondaryPhone: patient.secondaryPhone,
        birthDate: patient.birthDate,
        gender: patient.gender,
        maritalStatus: patient.maritalStatus,
        nationality: patient.nationality,
        address: patient.address,
        height: patient.height, // Incluir altura
        weight: patient.weight, // Incluir peso
        profession: patient.profession, // Incluir profissão
        acceptedTerms: patient.acceptedTerms,
        profilePhoto: patient.profilePhoto, // Incluir foto de perfil
        isAdmin: true, // torna o usuário admin
        twoFactorCode: patient.twoFactorCode,
        twoFactorExpires: patient.twoFactorExpires,
        passwordResetCode: patient.passwordResetCode,
        passwordResetExpires: patient.passwordResetExpires,
        createdAt: patient.createdAt,
        updatedAt: DateTime.now(),
      );
      
      if (patient.id != null) {
        await updatePatientData(patient.id!, adminPatient);
        _currentUser.value = adminPatient;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Método para testar configuração de e-mail
  Future<void> testEmailConfiguration() async {
    try {
      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;
      
      if (user.isEmpty || pass.isEmpty) {
        return;
      }
      
      final smtpServer = _getSmtpServer(user, pass);
      final message = Message()
        ..from = Address(user, 'PulseFlow Saúde - Teste')
        ..recipients.add(user)
        ..subject = 'Teste de Configuração - PulseFlow'
        ..text = 'Este é um e-mail de teste para verificar se a configuração do Gmail está funcionando corretamente.';
      
      await send(message, smtpServer);
    } catch (e) {
      // Silenciosamente falha
    }
  }

  // Atualizar FCM Token do usuário
  Future<void> updateFcmToken() async {
    try {
      if (_currentUser.value == null || _currentUser.value!.id == null) {
        return;
      }

      // Tentar obter o token do NotificationService
      try {
        final notificationService = Get.find<NotificationService>();
        final fcmToken = await notificationService.getToken();
        
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _databaseService.updatePatientField(
            _currentUser.value!.id!,
            'fcmToken',
            fcmToken,
          );
        }
      } catch (e) {
      }
    } catch (e) {
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Inicialização do serviço, se necessário
  }

  @override
  void onClose() {
    super.onClose();
  }
} 