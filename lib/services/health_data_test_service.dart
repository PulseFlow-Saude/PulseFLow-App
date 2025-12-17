import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/health_data.dart';
import 'database_service.dart';
import 'health_service.dart';

class HealthDataTestService {
  final DatabaseService _db = Get.find<DatabaseService>();

  // Testa a conexão com o banco de dados
  Future<void> testDatabaseConnection() async {
    try {
      await _db.testConnection();
    } catch (e) {
      rethrow;
    }
  }

  // Testa a criação de um dado de saúde
  Future<void> testCreateHealthData(String patientId) async {
    try {
      
      // Testa inserção na coleção 'batimentos'
      await _testCollectionInsert('batimentos', patientId, {
        'pacienteId': patientId,
        'valor': 72.0,
        'data': DateTime.now(),
        'fonte': 'Test',
        'unidade': 'bpm',
        'descricao': 'Teste de frequência cardíaca',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      
      // Testa inserção na coleção 'passos'
      await _testCollectionInsert('passos', patientId, {
        'pacienteId': patientId,
        'valor': 8000.0,
        'data': DateTime.now(),
        'fonte': 'Test',
        'unidade': 'passos',
        'descricao': 'Teste de passos',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      
      // Testa inserção na coleção 'insonias'
      await _testCollectionInsert('insonias', patientId, {
        'pacienteId': patientId,
        'valor': 7.5,
        'data': DateTime.now(),
        'fonte': 'Test',
        'unidade': 'horas',
        'descricao': 'Teste de sono',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      
    } catch (e) {
      rethrow;
    }
  }

  // Testa inserção em uma coleção específica
  Future<void> _testCollectionInsert(String collectionName, String patientId, Map<String, dynamic> data) async {
    try {
      
      final collection = await _db.getCollection(collectionName);
      
      final result = await collection.insert(data);
      
      // Busca o dado inserido
      final retrieved = await collection.findOne(where.eq('pacienteId', patientId));
      if (retrieved != null) {
      } else {
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Testa a busca de dados de saúde
  Future<void> testGetHealthData(String patientId) async {
    try {
      
      // Busca dados nas coleções específicas
      await _testCollectionSearch('batimentos', patientId);
      await _testCollectionSearch('passos', patientId);
      await _testCollectionSearch('insonias', patientId);
      
    } catch (e) {
      rethrow;
    }
  }

  // Testa busca em uma coleção específica
  Future<void> _testCollectionSearch(String collectionName, String patientId) async {
    try {
      
      final collection = await _db.getCollection(collectionName);
      
      final data = await collection.find(where.eq('pacienteId', patientId)).toList();
      
      for (final item in data) {
      }
      
    } catch (e) {
    }
  }

  // Executa todos os testes
  Future<void> runAllTests(String patientId) async {
    try {
      
      await testDatabaseConnection();
      await testCreateHealthData(patientId);
      await testGetHealthData(patientId);
      await testHealthKitDiagnosis();
      
      
    } catch (e) {
      rethrow;
    }
  }

  // Testa diagnóstico do Apple Health
  Future<void> testHealthKitDiagnosis() async {
    try {
      
      final healthService = HealthService();
      await healthService.diagnoseHealthData();
      
    } catch (e) {
    }
  }
}
