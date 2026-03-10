import 'dart:convert';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
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
  // Suporta: "salt:hash" (SHA-256), bcrypt ($2a$/$2b$), e hash antigo sem salt
  Future<bool> verifyPassword(String password, String storedPassword) async {
    try {
      // Senhas bcrypt (usadas pelo backend)
      if (storedPassword.startsWith(r'$2a$') || storedPassword.startsWith(r'$2b$')) {
        return BCrypt.checkpw(password, storedPassword);
      }
      // Formato salt:hash (SHA-256 com salt)
      if (storedPassword.contains(':')) {
      
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
      }
      // Senha antiga sem salt (SHA-256 simples)
      final bytes = utf8.encode(password);
      final hash = sha256.convert(bytes);
      return hash.toString() == storedPassword;
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