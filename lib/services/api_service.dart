import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import '../utils/http_client_helper.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cliente HTTP personalizado que aceita certificados SSL não confiáveis (para desenvolvimento)
  http.Client get _httpClient {
    print('🔧 [ApiService] Obtendo cliente HTTP personalizado');
    return HttpClientHelper.getClient();
  }

  // URL base do backend web
  String get baseUrl => AppConfig.apiBaseUrl;

  // Headers padrão para requisições
  Map<String, String> get _defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Adicionar headers do ngrok se estiver usando ngrok (para evitar página de aviso)
    if (baseUrl.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
      // Adicionar User-Agent para parecer um navegador e evitar bloqueio
      headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1';
      // Adicionar referer pode ajudar
      headers['Referer'] = baseUrl;
    }
    
    return headers;
  }

  // Headers com autenticação
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_defaultHeaders);
    try {
      final authService = Get.find<AuthService>();
      // Obter token do storage diretamente se o token.value estiver vazio
      String token = authService.token;
      
      if (token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'auth_token') ?? '';
      }
      
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
    }
    return headers;
  }

  Future<http.Response> _postAccessCodeRequest({
    required String base,
    required Map<String, String> headers,
    required Map<String, dynamic> requestBody,
  }) async {
    print('🔧 [ApiService] Executando POST para base: $base');
    return _httpClient.post(
      Uri.parse('$base/api/access-code/gerar'),
      headers: headers,
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));
  }

  bool _isLocalTunnelUnavailable(http.Response response) {
    final tunnelStatus = response.headers['x-localtunnel-status'] ?? '';
    return response.statusCode == 503 &&
        tunnelStatus.toLowerCase().contains('tunnel unavailable');
  }

  // Enviar código de acesso para o backend
  Future<Map<String, dynamic>> sendAccessCode({
    required String patientId,
    required String accessCode,
    required DateTime expiresAt,
    bool accessLogEmail = false,
  }) async {
    try {
      final url = '$baseUrl/api/access-code/gerar';
      
      // Debug: verificar URL e baseUrl
      print('🔍 [ApiService] Tentando enviar código para: $url');
      print('🔍 [ApiService] Base URL: $baseUrl');
      
      final requestBody = {
        'patientId': patientId,
        'accessCode': accessCode,
        // UTC explícito: ISO local sem Z no servidor (ex. Render UTC) deslocava a expiração.
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'accessLogEmail': accessLogEmail,
        // Idioma dos e-mails da Chave Oryon (pt-BR | en), alinhado ao app.
        'appLocale': (Get.locale?.languageCode == 'en') ? 'en' : 'pt-BR',
      };

      final headers = await _getAuthHeaders();
      
      // Verificar se tem token de autenticação
      if (!headers.containsKey('Authorization')) {
        print('❌ [ApiService] Token de autenticação não encontrado');
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }
      
      print('✅ [ApiService] Token de autenticação encontrado');
      print('🔍 [ApiService] Headers (sem token): ${headers.keys.toList()}');
      print('🔍 [ApiService] Token presente: ${headers.containsKey('Authorization')}');
      if (headers.containsKey('Authorization')) {
        final authHeader = headers['Authorization']!;
        final tokenPreview = authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader;
        print('🔍 [ApiService] Token preview: $tokenPreview');
      }
      print('🔍 [ApiService] Usando cliente HTTP personalizado para SSL');
      print('🔍 [ApiService] Corpo da requisição: ${jsonEncode(requestBody)}');

      var currentBaseUrl = baseUrl;
      var response = await _postAccessCodeRequest(
        base: currentBaseUrl,
        headers: headers,
        requestBody: requestBody,
      );

      if (_isLocalTunnelUnavailable(response)) {
        final fallbackBase = AppConfig.apiFallbackUrl ?? AppConfig.defaultApiBaseUrl;
        if (fallbackBase != currentBaseUrl) {
          print('⚠️ [ApiService] Endpoint principal indisponível. Tentando fallback: $fallbackBase');
          currentBaseUrl = fallbackBase;
          response = await _postAccessCodeRequest(
            base: currentBaseUrl,
            headers: headers,
            requestBody: requestBody,
          );
          print('📡 [ApiService] Resultado do fallback - Status: ${response.statusCode}');
        } else {
          throw Exception(
            'Endpoint público indisponível. Verifique o servidor no Render e ajuste API_BASE_URL/API_FALLBACK_URL para uma URL acessível.',
          );
        }
      }

      print('✅ [ApiService] Resposta recebida com sucesso');
      
      print('📡 [ApiService] Status code: ${response.statusCode}');
      print('📡 [ApiService] Response body (primeiros 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      print('📡 [ApiService] Response headers: ${response.headers}');
      
      // Verificar se o proxy/túnel público está offline (ex.: ERR_NGROK_3200)
      final ngrokErrorCode = response.headers['ngrok-error-code'] ?? '';
      final contentType = response.headers['content-type'] ?? '';
      if (ngrokErrorCode == 'ERR_NGROK_3200' || 
          (response.body.contains('is offline') && baseUrl.contains('ngrok'))) {
        print('⚠️ [ApiService] Endpoint público está offline (ERR_NGROK_3200).');
        print('⚠️ [ApiService] Solução: validar URL pública e disponibilidade do backend no Render.');
        throw Exception('Endpoint público offline (ERR_NGROK_3200). Verifique a URL da API e o status do servidor no Render.');
      }
      
      // Verificar se o ngrok está bloqueando (retornando HTML em vez de JSON)
      if (contentType.contains('text/html') && baseUrl.contains('ngrok')) {
        print('⚠️ [ApiService] Ngrok está retornando página HTML (bloqueio). A página de aviso pode estar ativa.');
        print('⚠️ [ApiService] Solução: Visite a URL no navegador uma vez para desbloquear: $baseUrl');
        throw Exception('Ngrok está bloqueando a requisição. Visite $baseUrl no navegador para desbloquear o túnel.');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        String errorMessage = 'Erro desconhecido';
        Map<String, dynamic>? errorBody;
        try {
          if (response.body.isNotEmpty) {
            // Tentar decodificar como JSON primeiro
            if (contentType.contains('application/json')) {
              errorBody = jsonDecode(response.body);
              errorMessage = errorBody?['message'] ?? errorBody?['error'] ?? errorBody.toString();
              print('📡 [ApiService] Erro detalhado do servidor: $errorBody');
            } else {
              // Se não for JSON, pode ser HTML do ngrok
              errorMessage = 'Resposta não é JSON (pode ser página de bloqueio do ngrok)';
              print('⚠️ [ApiService] Resposta não é JSON - Content-Type: $contentType');
            }
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body.substring(0, 100) : 'Erro desconhecido';
          print('⚠️ [ApiService] Não foi possível decodificar o corpo da resposta de erro: $e');
        }
        
        // Mensagens específicas por status code
        if (response.statusCode == 401) {
          throw Exception('Sessão expirada. Faça login novamente.');
        } else if (response.statusCode == 403) {
          // Melhorar mensagem de erro 403 com mais detalhes
          final detailMessage = errorBody?['message'] ?? errorBody?['error'] ?? 'Acesso negado pelo servidor';
          print('❌ [ApiService] Erro 403 - Detalhes: $detailMessage');
          print('⚠️ [ApiService] Verifique: 1) Se o token JWT é válido, 2) Se o usuário tem permissão para acessar este endpoint, 3) Se o backend está verificando corretamente o token');
          throw Exception('Acesso negado (403). $detailMessage');
        } else if (response.statusCode == 404) {
          // Verificar se é erro específico do ngrok offline
          final responseBody = response.body.toLowerCase();
          final ngrokErrorCode = response.headers['ngrok-error-code'] ?? '';
          
          if (ngrokErrorCode == 'ERR_NGROK_3200' || 
              responseBody.contains('err_ngrok_3200') || 
              (responseBody.contains('endpoint') && responseBody.contains('offline')) ||
              response.headers.containsKey('ngrok-error-code')) {
            final ngrokError = response.headers['ngrok-error-code'] ?? 'ERR_NGROK_3200';
            print('❌ [ApiService] Ngrok está offline: $ngrokError');
            print('⚠️ [ApiService] O túnel ngrok não está ativo. Possíveis causas:');
            print('   1. O domínio fixo expirou (no plano gratuito)');
            print('   2. O ngrok precisa ser reiniciado');
            print('   3. O backend não está rodando na porta 65432');
            print('⚠️ [ApiService] Solução: valide API_BASE_URL e confirme backend ativo no Render.');
            throw Exception('Endpoint público offline (ERR_NGROK_3200). O domínio pode estar indisponível. Verifique API_BASE_URL e o servidor no Render.');
          }
          throw Exception('Endpoint não encontrado (404). Verifique se o endpoint /api/access-code/gerar existe no backend.');
        } else if (response.statusCode == 500) {
          throw Exception('Erro interno do servidor. Tente novamente mais tarde.');
        } else if (response.statusCode == 503) {
          if (_isLocalTunnelUnavailable(response)) {
            throw Exception(
              'Endpoint público indisponível (503). Verifique o servidor no Render ou ajuste API_BASE_URL/API_FALLBACK_URL para uma URL acessível pelo dispositivo.',
            );
          }
          throw Exception('Servidor indisponível (503). Tente novamente em instantes.');
        } else {
          throw Exception('Erro ao enviar código (${response.statusCode}) em $currentBaseUrl - $errorMessage');
        }
      }
    } on SocketException catch (e) {
      print('❌ [ApiService] SocketException: ${e.message}');
      print('❌ [ApiService] OS Error: ${e.osError?.message ?? "N/A"}');
      print('❌ [ApiService] Address: ${e.address}');
      print('❌ [ApiService] Port: ${e.port}');
      // Verificar se é realmente problema de conexão ou configuração
      final osErrorMsg = e.osError?.message ?? '';
      if (osErrorMsg.contains('nodename nor servname provided') ||
          osErrorMsg.contains('No address associated with hostname') ||
          osErrorMsg.contains('Name or service not known')) {
        throw Exception('URL do servidor inválida: $baseUrl. Verifique se o IP/domínio está correto.');
      }
      if (osErrorMsg.contains('Connection refused') || 
          osErrorMsg.contains('Connection reset') ||
          osErrorMsg.contains('Network is unreachable')) {
        throw Exception('Não foi possível conectar ao servidor $baseUrl. Verifique:\n1. Se o servidor está rodando\n2. Se o IP/porta estão corretos\n3. Se há firewall bloqueando');
      }
      throw Exception('Erro de conexão com o servidor $baseUrl: ${osErrorMsg.isNotEmpty ? osErrorMsg : e.message}');
    } on http.ClientException catch (e) {
      print('❌ [ApiService] ClientException: ${e.message}');
      print('❌ [ApiService] URI: ${e.uri}');
      // Pode ser CORS, SSL, ou outros problemas de rede
      if (e.message.contains('CORS') || e.message.contains('cors')) {
        throw Exception('Erro de CORS: O servidor não permite requisições desta origem.');
      }
      throw Exception('Erro de conexão HTTP: ${e.message}');
    } on TimeoutException catch (e) {
      print('❌ [ApiService] TimeoutException: ${e.message}');
      throw Exception('Tempo de espera esgotado. O servidor demorou muito para responder. Verifique se o servidor está acessível.');
    } on FormatException catch (e) {
      print('❌ [ApiService] FormatException: ${e.message}');
      throw Exception('Erro ao processar resposta do servidor: ${e.message}');
    } on TlsException catch (e) {
      final errorUrl = '$baseUrl/api/access-code/gerar';
      print('❌ [ApiService] TlsException: ${e.message}');
      print('❌ [ApiService] TlsException OS Error: ${e.osError?.message ?? "N/A"}');
      print('⚠️ [ApiService] Dica: Verifique se o servidor backend está acessível pela URL pública configurada');
      print('⚠️ [ApiService] Teste a URL no navegador: $errorUrl');
      throw Exception('Erro de certificado SSL. O servidor pode estar fechando a conexão. Verifique a URL HTTPS configurada e o servidor backend.');
    } on HandshakeException catch (e) {
      final errorUrl = '$baseUrl/api/access-code/gerar';
      print('❌ [ApiService] HandshakeException: ${e.message}');
      print('❌ [ApiService] HandshakeException OS Error: ${e.osError?.message ?? "N/A"}');
      print('⚠️ [ApiService] Dica: O handshake SSL foi interrompido. Pode ser problema no servidor ou no endpoint público');
      print('⚠️ [ApiService] Teste a URL no navegador: $errorUrl');
      throw Exception('Erro de handshake SSL. A conexão foi interrompida durante o handshake. Verifique se o servidor backend está rodando e acessível pela URL pública.');
    } catch (e) {
      print('❌ [ApiService] Erro genérico: ${e.runtimeType} - ${e.toString()}');
      print('❌ [ApiService] Stack trace: ${StackTrace.current}');
      // Se já é uma Exception com mensagem, relançar sem duplicar
      if (e is Exception) {
        // Se a mensagem já está formatada, apenas relançar
        final errorStr = e.toString();
        if (errorStr.contains('Token') || 
            errorStr.contains('Sessão') || 
            errorStr.contains('Erro ao enviar') ||
            errorStr.contains('Servidor não está acessível') ||
            errorStr.contains('não foi possível conectar') ||
            errorStr.contains('URL do servidor')) {
          rethrow;
        }
      }
      // Para outros erros, criar nova Exception com mensagem limpa
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      throw Exception('Erro ao enviar código: $errorMsg');
    }
  }

  // Verificar se o código foi salvo corretamente
  Future<bool> verifyAccessCode({
    required String patientId,
    required String accessCode,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/access-code/verificar'),
        headers: headers,
        body: jsonEncode({
          'patientId': patientId,
          'accessCode': accessCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valido'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Testar conexão com o backend
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/access-code/test'),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Buscar solicitações de acesso pendentes
  Future<List<Map<String, dynamic>>> buscarSolicitacoesPendentes(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/access-code/solicitacoes/$patientId'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['solicitacoes'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Marcar solicitação como visualizada
  Future<bool> marcarSolicitacaoVisualizada(String solicitacaoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.put(
        Uri.parse('$baseUrl/api/access-code/solicitacoes/$solicitacaoId/visualizar'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Pedido ao servidor para enviar e-mail ao paciente quando o médico fica ligado via Chave Oryon.
  /// Respeita [AppConfig.apiAccessCodeNotifyAccessEmailPath]; se o path estiver vazio, não faz chamada.
  Future<bool> notificarPacienteAcessoMedicoConectado({
    required String patientId,
    String? medicoNome,
    String? medicoEspecialidade,
  }) async {
    final path = AppConfig.apiAccessCodeNotifyAccessEmailPath;
    if (path.isEmpty) return false;
    try {
      final headers = await _getAuthHeaders();
      if (!headers.containsKey('Authorization')) {
        return false;
      }
      final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$root$path');
      final body = <String, dynamic>{
        'patientId': patientId,
        if (medicoNome != null && medicoNome.isNotEmpty) 'medicoNome': medicoNome,
        if (medicoEspecialidade != null && medicoEspecialidade.isNotEmpty)
          'medicoEspecialidade': medicoEspecialidade,
      };
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> verificarConexaoMedico(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/pacientes/$patientId/conexao-ativa'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> desconectarMedico(String patientId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/pacientes/$patientId/desconectar-medico'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoAcessos() async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/pacientes/historico-acessos'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final acessos = data['acessos'] as List<dynamic>? ?? [];
        return acessos.map((acesso) => Map<String, dynamic>.from(acesso)).toList();
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao buscar histórico de acessos: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> criarAgendamento({
    required String medicoId,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    required String tipoConsulta,
    required String motivoConsulta,
    String? observacoes,
    int? duracao,
    Map<String, dynamic>? endereco,
    String? linkVideochamada,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final dataStr = '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

      String? pacienteId;
      try {
        pacienteId = Get.find<AuthService>().currentUser?.id;
      } catch (_) {}

      final requestBody = {
        'medicoId': medicoId,
        'data': dataStr,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'tipoConsulta': tipoConsulta,
        'motivoConsulta': motivoConsulta,
        if (pacienteId != null && pacienteId.isNotEmpty) 'pacienteId': pacienteId,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
        if (duracao != null) 'duracao': duracao,
        if (endereco != null) 'endereco': endereco,
        if (linkVideochamada != null && linkVideochamada.isNotEmpty) 'linkVideochamada': linkVideochamada,
      };
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/agendamentos-paciente'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            errorMessage = decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['erro']?.toString() ??
                decoded['msg']?.toString() ??
                errorMessage;
          }
          
          if (errorMessage.toLowerCase().contains('token inválido') || 
              errorMessage.toLowerCase().contains('token expirado') ||
              response.statusCode == 401 || response.statusCode == 400) {
            final authService = Get.find<AuthService>();
            await authService.logout();
            throw Exception('Sua sessão expirou ou o token é inválido. Por favor, faça login novamente.');
          }
        } catch (e) {
          if (e.toString().contains('Sua sessão expirou')) {
            rethrow;
          }
          errorMessage = 'Erro ao criar agendamento: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelarAgendamento({
    required String agendamentoId,
    String? motivoCancelamento,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final requestBody = {
        if (motivoCancelamento != null && motivoCancelamento.isNotEmpty) 'motivoCancelamento': motivoCancelamento,
      };

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/agendamentos-paciente/$agendamentoId/cancelar'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao cancelar agendamento: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarAgendamentosPaciente({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? medicoId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }
      if (medicoId != null && medicoId.isNotEmpty) {
        queryParams['medicoId'] = medicoId;
      }

      final uri = Uri.parse('$baseUrl/api/agendamentos-paciente')
          .replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['agendamentos'] ?? []);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao buscar agendamentos: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarAgendamentosMedico({
    required String medicoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final queryParams = <String, String>{};
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/agendamentos-paciente/medico/$medicoId')
          .replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['agendamentos'] ?? []);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao buscar agendamentos: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obterHorariosDisponiveis({
    required String medicoId,
    required DateTime data,
  }) async {
    try {
      final headers = _defaultHeaders;
      
      final dataFormatada = '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      
      final uri = Uri.parse('$baseUrl/api/horarios-disponibilidade/disponiveis/$medicoId')
          .replace(queryParameters: {'data': dataFormatada});

      final response = await _httpClient.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao obter horários disponíveis: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listarHorariosMedico({
    required String medicoId,
  }) async {
    try {
      final headers = _defaultHeaders;
      
      final uri = Uri.parse('$baseUrl/api/horarios-disponibilidade/medico/$medicoId');

      final response = await _httpClient.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['horarios'] ?? []);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao listar horários do médico: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarNotificacoes({bool? archived}) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      String url = '$baseUrl/api/notificacoes-paciente';
      if (archived != null) {
        url += '?archived=$archived';
      }

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = List<Map<String, dynamic>>.from(data);
        return notifications;
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao buscar notificações: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<int> buscarContadorNotificacoesNaoLidas() async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        return 0;
      }

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/notificacoes-paciente/unread-count'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> marcarNotificacaoComoLida(String notificacaoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/notificacoes-paciente/$notificacaoId/read'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao marcar notificação como lida: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> marcarTodasNotificacoesComoLidas() async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/notificacoes-paciente/mark-all-read'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao marcar notificações como lidas: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> excluirNotificacao(String notificacaoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.delete(
        Uri.parse('$baseUrl/api/notificacoes-paciente/$notificacaoId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao excluir notificação: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> arquivarNotificacao(String notificacaoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/notificacoes-paciente/$notificacaoId/archive'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao arquivar notificação: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> desarquivarNotificacao(String notificacaoId) async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/notificacoes-paciente/$notificacaoId/unarchive'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao desarquivar notificação: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> criarNotificacaoPerfilAtualizado() async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        return;
      }

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/notificacoes-paciente/criar-perfil-atualizado'),
        headers: headers,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
      }
    } catch (e) {
    }
  }

  Future<Map<String, dynamic>> uploadExame({
    required String nome,
    required String categoria,
    required DateTime data,
    required File arquivo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/anexoExame/upload'),
      );

      request.headers.addAll({
        'Authorization': headers['Authorization']!,
      });

      if (baseUrl.contains('ngrok')) {
        request.headers['ngrok-skip-browser-warning'] = 'true';
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1';
        request.headers['Referer'] = baseUrl;
      }

      request.fields['nome'] = nome;
      request.fields['categoria'] = categoria;
      request.fields['data'] = data.toIso8601String();

      final fileExtension = arquivo.path.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';
      
      if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      } else if (['png', 'jpg', 'jpeg'].contains(fileExtension)) {
        contentType = 'image/$fileExtension';
      } else if (fileExtension == 'heic') {
        contentType = 'image/heic';
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'arquivo',
        arquivo.path,
        filename: arquivo.path.split('/').last,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      final client = _httpClient;
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exame': data['exame'],
          'message': data['message'] ?? 'Exame enviado com sucesso',
        };
      } else {
        String errorMessage = 'Erro ao enviar exame';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          }
        } catch (_) {
          if (response.statusCode == 404) {
            errorMessage = 'Rota não encontrada. Verifique se o servidor está rodando corretamente.';
          } else if (response.statusCode == 401) {
            errorMessage = 'Sessão expirada. Faça login novamente.';
          } else if (response.statusCode == 403) {
            errorMessage = 'Acesso negado. Verifique suas permissões.';
          } else {
            errorMessage = 'Erro ao enviar exame: ${response.statusCode}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarExamesPaciente() async {
    try {
      final headers = await _getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Token de autenticação não encontrado. Faça login novamente.');
      }

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/anexoExame/paciente'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Erro ao buscar exames: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
