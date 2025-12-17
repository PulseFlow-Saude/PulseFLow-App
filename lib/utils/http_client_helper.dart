import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Cliente HTTP personalizado que aceita certificados SSL não confiáveis
/// IMPORTANTE: Use apenas para desenvolvimento/testes. NÃO use em produção!
class HttpClientHelper {
  static http.Client? _client;
  
  /// Retorna um cliente HTTP que aceita certificados SSL não confiáveis
  /// Isso é necessário para usar serviços como ngrok durante o desenvolvimento
  static http.Client getClient() {
    if (_client != null) {
      print('🔧 [HttpClientHelper] Reutilizando cliente HTTP existente');
      return _client!;
    }
    
    print('🔧 [HttpClientHelper] Criando novo cliente HTTP com validação SSL desabilitada');
    
    // Criar HttpClient personalizado que aceita todos os certificados
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // ACEITAR TODOS OS CERTIFICADOS - APENAS PARA DESENVOLVIMENTO
        // Em produção, isso deve ser removido e usar validação adequada
        print('⚠️ [HttpClientHelper] badCertificateCallback chamado para $host:$port');
        print('⚠️ [HttpClientHelper] Aceitando certificado SSL (apenas desenvolvimento)');
        print('⚠️ [HttpClientHelper] Certificado subject: ${cert.subject}');
        print('⚠️ [HttpClientHelper] Certificado issuer: ${cert.issuer}');
        return true; // SEMPRE aceitar o certificado
      }
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30)
      ..autoUncompress = true;
    
    _client = IOClient(httpClient);
    print('✅ [HttpClientHelper] Cliente HTTP criado com sucesso');
    return _client!;
  }
  
  /// Libera o cliente HTTP
  static void close() {
    _client?.close();
    _client = null;
    print('🔧 [HttpClientHelper] Cliente HTTP fechado');
  }
  
  /// Força a recriação do cliente HTTP (útil para resolver problemas de conexão)
  static void reset() {
    close();
    print('🔄 [HttpClientHelper] Cliente HTTP resetado - será recriado na próxima requisição');
  }
}

