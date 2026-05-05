import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
import 'email_translations_helper.dart';


class AuthService extends GetxController {
  static AuthService get instance => Get.find<AuthService>();
  final _storage = const FlutterSecureStorage();

  /// Quando [AppConfig.email2faSkipSmtp] está ativo: código mostrado na UI em vez de e-mail.
  String? _plaintext2FACodeForTesting;
  String? get plaintext2FACodeForTesting => _plaintext2FACodeForTesting;

  void clearPlaintext2FACodeForTesting() {
    _plaintext2FACodeForTesting = null;
  }
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
        final payload = JwtDecoder.decode(token);
        final patientId = payload['sub'] ?? payload['id']?.toString();
        final patient = await getPatientById(patientId);
        if (patient != null) {
          _token.value = token;
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
    
    const jwtSecret = AppConfig.jwtSecret;
    
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

  SmtpServer _smtpServer(
    String host, {
    int port = 587,
    bool ssl = false,
    required String username,
    required String password,
  }) {
    return SmtpServer(
      host,
      port: port,
      ssl: ssl,
      username: username,
      password: password,
      ignoreBadCertificate: AppConfig.smtpIgnoreBadCertificate,
      allowInsecure: AppConfig.smtpAllowInsecure,
    );
  }

  /// SMTP — `SMTP_HOST` recomendado para Workspace/corporativo.
  /// Para `smtp.gmail.com` usa as mesmas opções que o helper oficial do pacote mailer + flags do .env.
  SmtpServer _getSmtpServer(String user, String pass) {
    final explicit = AppConfig.smtpHost;
    if (explicit != null && explicit.isNotEmpty) {
      final h = explicit.trim().toLowerCase();
      if (h == 'smtp.gmail.com') {
        return _smtpServer(
          'smtp.gmail.com',
          username: user,
          password: pass,
        );
      }
      return _smtpServer(
        explicit.trim(),
        port: AppConfig.smtpPort,
        ssl: AppConfig.smtpSsl,
        username: user,
        password: pass,
      );
    }

    final domain = user.split('@').last.toLowerCase();

    switch (domain) {
      case 'gmail.com':
        return _smtpServer('smtp.gmail.com', username: user, password: pass);
      case 'outlook.com':
      case 'hotmail.com':
      case 'live.com':
        return _smtpServer(
          'smtp-mail.outlook.com',
          username: user,
          password: pass,
        );
      case 'yahoo.com':
        return _smtpServer(
          'smtp.mail.yahoo.com',
          username: user,
          password: pass,
        );
      case 'icloud.com':
        return _smtpServer(
          'smtp.mail.me.com',
          username: user,
          password: pass,
        );
      case 'aol.com':
        return _smtpServer('smtp.aol.com', username: user, password: pass);
      default:
        return _smtpServer(
          'smtp.$domain',
          username: user,
          password: pass,
        );
    }
  }

  bool _shouldRetryGmailImplicitSsl(SmtpServer server, Object error) {
    if (server.host.toLowerCase() != 'smtp.gmail.com') return false;
    if (server.ssl && server.port == 465) return false;
    final tn = error.runtimeType.toString();
    if (tn.contains('SmtpClientAuthenticationException')) return false;
    return true;
  }

  Future<void> _sendSmtpMessage(Message message, String credUser, String credPass) async {
    final primary = _getSmtpServer(credUser, credPass);
    final timeout = AppConfig.smtpSendTimeout;

    try {
      await send(message, primary, timeout: timeout);
      return;
    } catch (e, st) {
      developer.log(
        'SMTP falhou (${primary.host}:${primary.port}, ssl=${primary.ssl}): $e',
        name: 'PulseFlow.Auth',
        error: e,
        stackTrace: st,
      );
      if (!_shouldRetryGmailImplicitSsl(primary, e)) {
        rethrow;
      }
      developer.log(
        'SMTP nova tentativa: smtp.gmail.com:465 (SSL implícito)',
        name: 'PulseFlow.Auth',
      );
      final fallback = _smtpServer(
        'smtp.gmail.com',
        port: 465,
        ssl: true,
        username: credUser,
        password: credPass,
      );
      await send(message, fallback, timeout: timeout);
    }
  }

  /// Erros 534/535 e falhas AUTH SMTP — também usado para fallback (mostrar código no ecrã).
  bool _smtpLooksLikeAuthRejected(Object e) {
    final s = e.toString().toLowerCase();
    final tn = e.runtimeType.toString().toLowerCase();
    return s.contains('534') ||
        s.contains('535') ||
        s.contains('5.7.') ||
        s.contains('authentication failed') ||
        s.contains('authentication unsuccessful') ||
        s.contains('credentials') ||
        s.contains('invalid login') ||
        s.contains('username and password') ||
        tn.contains('smtpclientauthenticationexception');
  }

  /// Gmail/Outlook devolvem 534 ou 535 quando o SMTP não aceita utilizador/senha do REMETENTE.
  String _smtpAuthFailureHint(Object e) {
    if (!_smtpLooksLikeAuthRejected(e)) {
      return '\n\nConfirme rede/VPN, SMTP_HOST e SMTP_TIMEOUT_SECONDS. '
          'Para testar sem mail: DEV_PRINT_2FA_CODE=true.';
    }
    return '\n\n—— O servidor recusou EMAIL_USER / EMAIL_PASS (erro típico 534 ou 535) ——\n'
        '• Gmail e Google Workspace: na conta desse mesmo e-mail (EMAIL_USER), '
        'ativa verificação em 2 passos e cria uma "Senha de app" '
        '(myaccount.google.com/apppasswords). Coloca só essa senha de 16 letras em EMAIL_PASS.\n'
        '• Não uses a senha normal da conta Google — o SMTP não aceita.\n'
        '• EMAIL_USER deve ser o e-mail completo da conta onde geraste a senha de app.\n'
        '• Workspace: o administrador pode desativar SMTP; aí só OAuth2 ou outro provedor.\n'
        '• Outlook/Hotmail: Microsoft pode bloquear login SMTP por senha; usa Gmail como remetente '
        'ou SMTP que o teu serviço de e-mail permita.';
  }

  void _throwSmtpFailure(String prefix, Object e) {
    throw '$prefix $e${_smtpAuthFailureHint(e)}';
  }

  Future<void> _sendTwoFactorEmailViaBackend({
    required String toEmail,
    required String code,
    String? patientId,
  }) async {
    Future<void> postUri(String endpoint) async {
      final uri = Uri.parse(endpoint);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final secret = AppConfig.emailApiSecret;
      if (secret != null && secret.isNotEmpty) {
        headers['X-PulseFlow-Email-Secret'] = secret;
      }
      final resp = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'to': toEmail,
              'email': toEmail,
              'code': code,
              'patientId': patientId ?? '',
              'kind': 'login_2fa',
            }),
          )
          .timeout(AppConfig.emailApiTimeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) return;

      var detail = resp.body;
      try {
        final j = jsonDecode(resp.body);
        if (j is Map && j['message'] != null) {
          detail = j['message'].toString();
        }
      } catch (_) {}

      throw 'HTTP ${resp.statusCode}: $detail';
    }

    try {
      await postUri(AppConfig.emailSendEndpoint);
    } catch (e) {
      final fb = AppConfig.apiFallbackUrl;
      if (fb != null &&
          fb.trim().isNotEmpty &&
          AppConfig.emailSendAbsoluteUrl == null) {
        await postUri(AppConfig.emailSendEndpointForApiRoot(fb));
        return;
      }
      rethrow;
    }
  }

  /// Primeiro tenta envio pelo **backend** ([AppConfig.emailSendViaApi]); depois SMTP no cliente.
  Future<void> send2FACodeEmail(
    String email,
    String code, {
    String? patientId,
  }) async {
    try {
      if (AppConfig.devPrint2FACode) {
        developer.log(
          '2FA código para $email: $code',
          name: 'PulseFlow.Auth',
        );
      }

      if (AppConfig.emailSendViaApi) {
        try {
          await _sendTwoFactorEmailViaBackend(
            toEmail: email,
            code: code,
            patientId: patientId,
          );
          developer.log(
            'Código 2FA enviado via API (${AppConfig.emailSendEndpoint}).',
            name: 'PulseFlow.Auth',
          );
          return;
        } catch (e, st) {
          developer.log(
            'Envio 2FA pela API falhou; a tentar SMTP no dispositivo: $e',
            name: 'PulseFlow.Auth',
            error: e,
            stackTrace: st,
          );
        }
      }

      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;

      if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
        if (AppConfig.emailSendViaApi) {
          throw 'O servidor não conseguiu enviar o e-mail e não há EMAIL_USER/EMAIL_PASS '
              'para tentar SMTP neste telemóvel. Confirme EMAIL_SEND_VIA_API / EMAIL_SEND_URL '
              'e o endpoint no backend, ou configure SMTP.';
        }
        throw 'Configurações de email não encontradas. Verifique o arquivo .env';
      }

      final t = EmailTranslationsHelper.getEmailTranslationsSync();

      final message = Message()
        ..from = Address(user, t['email_from_name']!)
        ..recipients.add(email)
        ..subject = t['email_2fa_subject']!
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #1CB5E0 0%, #000046 100%); padding: 30px; border-radius: 15px; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 24px;">${t['email_2fa_heading']}</h1>
              <p style="color: white; margin: 10px 0 0 0; opacity: 0.9;">${t['email_2fa_subheading']}</p>
            </div>
            
            <div style="background: white; padding: 30px; border-radius: 0 0 15px 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
              <h2 style="color: #333; margin: 0 0 20px 0;">${t['email_2fa_hello']}</h2>
              <p style="color: #666; line-height: 1.6; margin: 0 0 20px 0;">
                ${t['email_2fa_body']}
              </p>
              
              <div style="background: #f8f9fa; border: 2px dashed #1CB5E0; border-radius: 10px; padding: 20px; margin: 20px 0; text-align: center;">
                <h3 style="color: #1CB5E0; margin: 0; font-size: 32px; letter-spacing: 8px; font-weight: bold;">$code</h3>
                <p style="color: #666; margin: 10px 0 0 0; font-size: 14px;">${t['email_2fa_code_label']}</p>
              </div>
              
              <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 15px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                  ⏰ <strong>${t['email_2fa_important']}</strong>
                </p>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin: 20px 0 0 0; font-size: 14px;">
                ${t['email_2fa_ignore']}
              </p>
              
              <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                ${t['email_2fa_footer']}
              </p>
            </div>
          </div>
        ''';

      await _sendSmtpMessage(message, user, pass);
    } catch (e) {
      _throwSmtpFailure('Erro ao enviar email:', e);
    }
  }

  // Login via API do backend (MongoDB via .env)
  Future<Patient> _loginViaApi(String email, String password) async {
    final baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.isEmpty) throw 'API não configurada (apiBaseUrl)';

    final response = await http.post(
      Uri.parse('$baseUrl/api/paciente-auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw body['message'] ?? 'Erro ao fazer login';
    }

    final data = jsonDecode(response.body);
    final token = data['token'];
    if (token == null) throw 'Token não retornado pela API';

    await _storage.write(key: 'auth_token', value: token);

    final patient = await _fetchPatientFromApi(token);
    if (patient == null) throw 'Não foi possível carregar os dados do usuário';

    _token.value = token;
    _currentUser.value = patient;
    _isAuthenticated.value = true;
    return patient;
  }

  Future<Patient?> _fetchPatientFromApi(String token) async {
    final baseUrl = AppConfig.apiBaseUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/api/paciente-auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Patient.fromJson(json);
  }

  // Login com 2FA 
  // Retorna o ID do paciente:
  // - Para usuários admin: retorna o ID diretamente (bypass 2FA)
  // - Para usuários normais: retorna o ID após gerar e enviar código 2FA
  // - Quando useApiForAuth: usa a API do backend (sem 2FA)
  Future<String> loginWith2FA(String email, String password) async {
    if (AppConfig.useApiForAuth) {
      final patient = await _loginViaApi(email, password);
      return patient.id!;
    }

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

      if (AppConfig.email2faSkipSmtp) {
        _plaintext2FACodeForTesting = code;
        return patientIdString;
      }

      try {
        await send2FACodeEmail(
          patient.email,
          code,
          patientId: patientIdString,
        );
      } catch (e) {
        if (_smtpLooksLikeAuthRejected(e)) {
          _plaintext2FACodeForTesting = code;
          developer.log(
            'SMTP AUTH recusado (${e.runtimeType}): código 2FA disponível no ecrã.',
            name: 'PulseFlow.Auth',
            error: e,
          );
          return patientIdString;
        }
        await _databaseService.clearTwoFactorCode(patientIdString);
        rethrow;
      }

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

    clearPlaintext2FACodeForTesting();

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

  /// Recarrega o usuário atual do banco/API (útil para obter foto de perfil atualizada)
  Future<void> refreshCurrentUser() async {
    final id = _currentUser.value?.id;
    if (id == null) return;
    final patient = await getPatientById(id, forceRefresh: true);
    if (patient != null) {
      // Se profilePhoto não veio no paciente, buscar diretamente (campo profilePhoto no MongoDB)
      var profilePhoto = patient.profilePhoto;
      if (profilePhoto == null || profilePhoto.isEmpty) {
        profilePhoto = await _databaseService.getPatientProfilePhoto(id);
      }
      _currentUser.value = (profilePhoto != null && profilePhoto.isNotEmpty)
          ? Patient(
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
              residenceCountry: patient.residenceCountry,
              socialSecurityNumber: patient.socialSecurityNumber,
              address: patient.address,
              height: patient.height,
              weight: patient.weight,
              profession: patient.profession,
              acceptedTerms: patient.acceptedTerms,
              profilePhoto: profilePhoto,
              emergencyContact: patient.emergencyContact,
              emergencyPhone: patient.emergencyPhone,
              fcmToken: patient.fcmToken,
              isAdmin: patient.isAdmin,
              twoFactorCode: patient.twoFactorCode,
              twoFactorExpires: patient.twoFactorExpires,
              passwordResetCode: patient.passwordResetCode,
              passwordResetExpires: patient.passwordResetExpires,
              passwordResetRequired: patient.passwordResetRequired,
              createdAt: patient.createdAt,
              updatedAt: patient.updatedAt,
            )
          : patient;
    }
  }

  // Busca paciente por ID
  Future<Patient?> getPatientById(String patientId, {bool forceRefresh = false}) async {
    if (AppConfig.useApiForAuth) {
      if (!forceRefresh && _currentUser.value != null && _currentUser.value!.id == patientId) {
        return _currentUser.value;
      }
      if (_token.value.isNotEmpty) return await _fetchPatientFromApi(_token.value);
      return null;
    }
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

      if (AppConfig.email2faSkipSmtp) {
        _plaintext2FACodeForTesting = code;
        return;
      }

      try {
        await send2FACodeEmail(
          patient.email,
          code,
          patientId: patientId,
        );
      } catch (e) {
        if (_smtpLooksLikeAuthRejected(e)) {
          _plaintext2FACodeForTesting = code;
          developer.log(
            'SMTP AUTH recusado no reenvio 2FA: código no ecrã.',
            name: 'PulseFlow.Auth',
            error: e,
          );
          return;
        }
        await _databaseService.clearTwoFactorCode(patientId);
        rethrow;
      }
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
        residenceCountry: patient.residenceCountry,
        socialSecurityNumber: patient.socialSecurityNumber,
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
        residenceCountry: patient.residenceCountry,
        socialSecurityNumber: patient.socialSecurityNumber,
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
      clearPlaintext2FACodeForTesting();
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
        residenceCountry: updatedPatient.residenceCountry,
        socialSecurityNumber: updatedPatient.socialSecurityNumber,
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
    if (AppConfig.useApiForAuth) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/paciente-auth/check-email?email=${Uri.encodeComponent(email)}'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) return Patient(id: '', name: '', email: email, password: '', cpf: '', rg: '', phone: '', birthDate: DateTime.now(), gender: '', maritalStatus: '', nationality: '', address: '', acceptedTerms: false);
        if (response.statusCode == 404) return null;
        try {
          final body = jsonDecode(response.body);
          throw body['message'] ?? 'Erro ao verificar e-mail';
        } catch (_) {
          throw 'Erro ao verificar e-mail';
        }
      } catch (e) {
        rethrow;
      }
    }
    try {
      return await _databaseService.getPatientByEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Envia código de redefinição de senha
  Future<void> sendPasswordResetCode(String email) async {
    if (AppConfig.useApiForAuth) {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/paciente-auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw body['message'] ?? 'Erro ao enviar código';
      }
      return;
    }
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'E-mail não encontrado. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }

      final code = _generate2FACode();
      final expires = DateTime.now().add(const Duration(minutes: 10));
      await _databaseService.setPasswordResetCode(patient.id!, code, expires);
      try {
        await sendPasswordResetEmail(email, code);
      } catch (e) {
        await _databaseService.clearPasswordResetCode(patient.id!);
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Redefine a senha do usuário
  Future<void> resetPassword(String email, String code, String newPassword) async {
    if (AppConfig.useApiForAuth) {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/paciente-auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code, 'senha': newPassword}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw body['message'] ?? 'Erro ao redefinir senha';
      }
      return;
    }
    try {
      final patient = await _databaseService.getPatientByEmail(email);
      if (patient == null) {
        throw 'E-mail não encontrado. Verifique se digitou corretamente, incluindo maiúsculas e minúsculas.';
      }

      final isValid = await _databaseService.validatePasswordResetCode(patient.id!, code);
      if (!isValid) {
        throw 'Código de redefinição inválido ou expirado';
      }

      final hashedPassword = await _encryptionService.hashPassword(newPassword);
      await _databaseService.updatePatientPassword(patient.id!, hashedPassword);
      await _databaseService.updatePatientField(
        patient.id!,
        'passwordResetRequired',
        false,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Envia e-mail de redefinição de senha (traduzido conforme idioma do usuário/dispositivo)
  Future<void> sendPasswordResetEmail(String email, String code) async {
    try {
      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;

      if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
        throw 'Configuração de email não encontrada. Verifique EMAIL_USER e EMAIL_PASS no .env';
      }

      final t = EmailTranslationsHelper.getEmailTranslationsSync();
      final message = Message()
        ..from = Address(user, t['email_from_name']!)
        ..recipients.add(email)
        ..subject = t['email_reset_subject']!
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
            <div style="background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
              <div style="text-align: center; margin-bottom: 30px;">
                <div style="background-color: #1CB5E0; width: 60px; height: 60px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; margin-bottom: 20px;">
                  <span style="color: white; font-size: 24px;">🔐</span>
                </div>
                <h1 style="color: #222B45; margin: 0; font-size: 24px;">${t['email_reset_heading']}</h1>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                ${t['email_reset_body']}
              </p>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 30px;">
                ${t['email_reset_code_usage']}
              </p>
              
              <div style="background-color: #1CB5E0; color: white; padding: 20px; border-radius: 10px; text-align: center; margin-bottom: 30px;">
                <h2 style="margin: 0; font-size: 32px; letter-spacing: 8px; font-family: monospace;">$code</h2>
              </div>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                <strong>${t['email_reset_expiry']}</strong>
              </p>
              
              <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
                ${t['email_reset_ignore']}
              </p>
              
              <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                ${t['email_reset_footer']}
              </p>
            </div>
          </div>
        ''';

      await _sendSmtpMessage(message, user, pass);
    } catch (e) {
      _throwSmtpFailure('Erro ao enviar email de recuperação:', e);
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
        residenceCountry: patient.residenceCountry,
        socialSecurityNumber: patient.socialSecurityNumber,
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

  // Método para testar configuração de e-mail (traduzido conforme idioma do usuário/dispositivo)
  Future<void> testEmailConfiguration() async {
    try {
      final user = AppConfig.emailUser;
      final pass = AppConfig.emailPass;
      
      if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
        return;
      }
      
      final t = EmailTranslationsHelper.getEmailTranslationsSync();
      final message = Message()
        ..from = Address(user, '${t['email_from_name']} - ${t['email_test_suffix']!}')
        ..recipients.add(user)
        ..subject = t['email_test_subject']!
        ..text = t['email_test_body']!;

      await _sendSmtpMessage(message, user, pass);
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


} 