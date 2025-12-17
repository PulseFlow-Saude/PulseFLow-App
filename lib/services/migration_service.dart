import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/database_config.dart';
import 'encryption_service.dart';

class MigrationService extends GetxController {
  static MigrationService get instance => Get.find<MigrationService>();
  final EncryptionService _encryptionService = EncryptionService();
  Db? _db;

  Future<void> _ensureConnection() async {
    if (_db != null && _db!.isConnected) {
      return;
    }

    try {
      final uri = DatabaseConfig.connectionString;
      if (uri.isEmpty) {
        throw 'String de conexão não configurada';
      }
      _db = await Db.create(uri);
      await _db!.open();
    } catch (e) {
      throw 'Falha ao conectar ao banco: $e';
    }
  }

  // Migra todas as senhas antigas (sem salt) para o novo formato
  Future<void> migrateAllPasswords() async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Busca todos os pacientes
      final patients = await collection.find().toList();
      
      int migratedCount = 0;
      int skippedCount = 0;
      
      for (final patient in patients) {
        final password = patient['password'] as String?;
        
        if (password != null && !password.contains(':')) {
          // Senha antiga sem salt - precisa migrar
          try {
            // Como não temos a senha em texto plano, vamos usar um hash temporário
            // O usuário precisará redefinir a senha no próximo login
            final tempPassword = 'temp_${DateTime.now().millisecondsSinceEpoch}';
            final newHashedPassword = await _encryptionService.hashPassword(tempPassword);
            
            // Atualiza a senha no banco
            await collection.update(
              where.eq('_id', patient['_id']),
              modify.set('password', newHashedPassword)
            );
            
            // Adiciona flag indicando que a senha precisa ser redefinida
            await collection.update(
              where.eq('_id', patient['_id']),
              modify.set('passwordResetRequired', true)
            );
            
            migratedCount++;
          } catch (e) {
            // Silenciosamente falha se não conseguir migrar senha
          }
        } else {
          skippedCount++;
        }
      }
      
    } catch (e) {
      rethrow;
    } finally {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
      }
    }
  }

  // Verifica se há senhas que precisam ser migradas
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Busca todos os pacientes para contar manualmente
      final allPatients = await collection.find().toList();
      
      int oldPasswordCount = 0;
      int newPasswordCount = 0;
      int resetRequiredCount = 0;
      
      for (final patient in allPatients) {
        final password = patient['password'] as String?;
        
        if (password != null) {
          if (password.contains(':')) {
            newPasswordCount++;
          } else {
            oldPasswordCount++;
          }
        }
        
        if (patient['passwordResetRequired'] == true) {
          resetRequiredCount++;
        }
      }
      
      return {
        'oldPasswordCount': oldPasswordCount,
        'newPasswordCount': newPasswordCount,
        'resetRequiredCount': resetRequiredCount,
        'totalPatients': allPatients.length,
        'needsMigration': oldPasswordCount > 0,
      };
    } catch (e) {
      rethrow;
    } finally {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
      }
    }
  }

  // Força redefinição de senha para um usuário específico
  Future<void> forcePasswordReset(String email) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      final patient = await collection.findOne(where.eq('email', email));
      if (patient == null) {
        throw 'Paciente não encontrado';
      }
      
      // Gera nova senha hash com salt
      final tempPassword = 'reset_${DateTime.now().millisecondsSinceEpoch}';
      final newHashedPassword = await _encryptionService.hashPassword(tempPassword);
      
      // Atualiza a senha e marca como necessitando redefinição
      await collection.update(
        where.eq('email', email),
        modify
          .set('password', newHashedPassword)
          .set('passwordResetRequired', true)
      );
      
      // Senha redefinida com sucesso
      
    } catch (e) {
      rethrow;
    } finally {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
      }
    }
  }

  @override
  void onClose() {
    if (_db != null && _db!.isConnected) {
      _db!.close();
    }
    super.onClose();
  }
}
