import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  EncryptionService._internal();

  // Gera um salt aleatório de 16 caracteres
  String _generateSalt() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Criptografa a senha usando SHA-256 com salt único
  // Retorna uma string no formato: "salt:hash"
  Future<String> hashPassword(String password) async {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return '$salt:${hash.toString()}';
  }

  // Verifica se a senha fornecida corresponde à senha criptografada
  // A senha armazenada deve estar no formato: "salt:hash"
  Future<bool> verifyPassword(String password, String storedPassword) async {
    try {
      // Verifica se a senha armazenada tem o formato correto
      if (!storedPassword.contains(':')) {
        // Se não tem formato salt:hash, assume que é uma senha antiga sem salt
        // Para compatibilidade, faz hash simples da senha fornecida
        final bytes = utf8.encode(password);
        final hash = sha256.convert(bytes);
        return hash.toString() == storedPassword;
      }
      
      // Extrai o salt e hash da senha armazenada
      final parts = storedPassword.split(':');
      if (parts.length != 2) {
        return false;
      }
      
      final salt = parts[0];
      final storedHash = parts[1];
      
      // Aplica o mesmo salt à senha fornecida
      final bytes = utf8.encode(password + salt);
      final hash = sha256.convert(bytes);
      
      return hash.toString() == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Método para migrar senhas antigas (sem salt) para o novo formato
  // Use este método quando quiser atualizar senhas existentes
  Future<String> migratePassword(String oldHashedPassword, String plainPassword) async {
    return await hashPassword(plainPassword);
  }
} 