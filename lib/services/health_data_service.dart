import 'package:get/get.dart';
import '../models/health_data.dart';
import 'database_service.dart';
import 'health_service.dart';

class HealthDataService {
  final DatabaseService _db = Get.find<DatabaseService>();
  final HealthService _healthService = HealthService();

  // Salva dados de saúde do HealthKit no banco de dados
  Future<void> saveHealthDataFromHealthKit(String patientId) async {
    try {
      print('💾 [HealthDataService] Iniciando salvamento de dados do HealthKit...');
      
      // Verifica se tem permissões
      final hasPermissions = await _healthService.hasPermissions();
      
      if (!hasPermissions) {
        print('⚠️ [HealthDataService] Sem permissões, solicitando...');
        final granted = await _healthService.requestPermissions();
        if (!granted) {
          print('❌ [HealthDataService] Permissões negadas, não é possível salvar dados');
          return;
        }
      }

      // Busca dados do HealthKit
      print('💾 [HealthDataService] Buscando dados do HealthKit...');
      final healthData = await _healthService.getAllHealthData();
      
      // Log detalhado de cada tipo de dado
      print('💾 [HealthDataService] Dados recebidos:');
      healthData.forEach((key, value) {
        if (value.isNotEmpty) {
          print('  - $key: ${value.length} pontos');
        } else {
          print('  - $key: vazio');
        }
      });
      
      // Salva dados nas coleções específicas
      print('💾 [HealthDataService] Salvando dados nas coleções...');
      await _saveHeartRateData(patientId, healthData);
      await _saveStepsData(patientId, healthData);
      await _saveSleepData(patientId, healthData);
      
      print('✅ [HealthDataService] Salvamento concluído com sucesso');
      
    } catch (e, stackTrace) {
      print('❌ [HealthDataService] Erro ao salvar dados do HealthKit: $e');
      print('❌ [HealthDataService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Salva dados de frequência cardíaca na coleção 'batimentos'
  Future<void> _saveHeartRateData(String patientId, Map<String, List<dynamic>> healthData) async {
    try {
      if (healthData['heartRate'] == null || healthData['heartRate']!.isEmpty) {
        return;
      }

      print('💾 [HealthDataService] Salvando dados de frequência cardíaca...');

      final collection = await _db.getCollection('batimentos');
      final now = DateTime.now();
      
      // Busca dados existentes
      final existingData = await collection.find({
        'pacienteId': patientId,
      }).toList();
      
      int savedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;
      
      for (int i = 0; i < healthData['heartRate']!.length; i++) {
        final spot = healthData['heartRate']![i];
        final date = now.subtract(Duration(days: (6 - i)));
        
        // Não salva valores padrão (70.0) se não houver dados reais
        if (spot.y == 70.0) {
          skippedCount++;
          continue;
        }
        
        final dateKey = DateTime(date.year, date.month, date.day);
        Map<String, dynamic>? existingRecord;
        
        try {
          existingRecord = existingData.firstWhere(
            (existing) {
              final existingDate = existing['data'] as DateTime;
              final existingDateKey = DateTime(existingDate.year, existingDate.month, existingDate.day);
              return existingDateKey.isAtSameMomentAs(dateKey);
            },
          ) as Map<String, dynamic>?;
        } catch (e) {
          existingRecord = null;
        }
        
        if (existingRecord != null) {
          // Atualiza se o valor mudou
          final existingValue = existingRecord['valor'] as num?;
          if (existingValue != spot.y) {
            await collection.update(
              {'_id': existingRecord['_id']},
              {
                '\$set': {
                  'valor': spot.y,
                  'fonte': 'HealthKit',
                  'updatedAt': DateTime.now(),
                }
              },
            );
            updatedCount++;
          } else {
            skippedCount++;
          }
        } else {
        final data = {
          'pacienteId': patientId,
          'valor': spot.y,
            'data': dateKey,
          'fonte': 'HealthKit',
          'unidade': 'bpm',
          'descricao': 'Frequência cardíaca',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        
        await collection.insert(data);
          savedCount++;
        }
      }
      
      print('💾 [HealthDataService] Frequência cardíaca: $savedCount salvos, $updatedCount atualizados, $skippedCount pulados');
      
    } catch (e, stackTrace) {
      print('❌ [HealthDataService] Erro ao salvar frequência cardíaca: $e');
      print('❌ [HealthDataService] Stack trace: $stackTrace');
    }
  }

  // Salva dados de passos na coleção 'passos'
  Future<void> _saveStepsData(String patientId, Map<String, List<dynamic>> healthData) async {
    try {
      if (healthData['steps'] == null || healthData['steps']!.isEmpty) {
        return;
      }

      print('💾 [HealthDataService] Salvando dados de passos...');

      final collection = await _db.getCollection('passos');
      final now = DateTime.now();
      
      // Busca dados existentes
      final existingData = await collection.find({
        'pacienteId': patientId,
      }).toList();
      
      int savedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;
      
      for (int i = 0; i < healthData['steps']!.length; i++) {
        final spot = healthData['steps']![i];
        final date = now.subtract(Duration(days: (6 - i)));
        
        // Não salva valores padrão (8000.0) se não houver dados reais
        if (spot.y == 8000.0) {
          skippedCount++;
          continue;
        }
        
        final dateKey = DateTime(date.year, date.month, date.day);
        Map<String, dynamic>? existingRecord;
        
        try {
          existingRecord = existingData.firstWhere(
            (existing) {
              final existingDate = existing['data'] as DateTime;
              final existingDateKey = DateTime(existingDate.year, existingDate.month, existingDate.day);
              return existingDateKey.isAtSameMomentAs(dateKey);
            },
          ) as Map<String, dynamic>?;
        } catch (e) {
          existingRecord = null;
        }
        
        if (existingRecord != null) {
          // Atualiza se o valor mudou
          final existingValue = existingRecord['valor'] as num?;
          if (existingValue != spot.y) {
            await collection.update(
              {'_id': existingRecord['_id']},
              {
                '\$set': {
                  'valor': spot.y,
                  'fonte': 'HealthKit',
                  'updatedAt': DateTime.now(),
                }
              },
            );
            updatedCount++;
          } else {
            skippedCount++;
          }
        } else {
        final data = {
          'pacienteId': patientId,
          'valor': spot.y,
            'data': dateKey,
          'fonte': 'HealthKit',
          'unidade': 'passos',
          'descricao': 'Passos diários',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        
        await collection.insert(data);
          savedCount++;
        }
      }
      
      print('💾 [HealthDataService] Passos: $savedCount salvos, $updatedCount atualizados, $skippedCount pulados');
      
    } catch (e, stackTrace) {
      print('❌ [HealthDataService] Erro ao salvar passos: $e');
      print('❌ [HealthDataService] Stack trace: $stackTrace');
    }
  }

  // Salva dados de sono na coleção 'insonias'
  Future<void> _saveSleepData(String patientId, Map<String, List<dynamic>> healthData) async {
    try {
      print('💾 [HealthDataService] Salvando dados de sono...');
      
      if (healthData['sleep'] == null || healthData['sleep']!.isEmpty) {
        print('⚠️ [HealthDataService] Nenhum dado de sono encontrado para salvar');
        return; // Não cria dados de teste, apenas retorna
      }

      print('💾 [HealthDataService] Encontrados ${healthData['sleep']!.length} pontos de dados de sono');

      final collection = await _db.getCollection('insonias');
      final now = DateTime.now();
      
      // Verifica dados existentes para evitar duplicatas
      final existingData = await collection.find({
        'pacienteId': patientId,
      }).toList();
      
      int savedCount = 0;
      int skippedCount = 0;
      
      for (int i = 0; i < healthData['sleep']!.length; i++) {
        final spot = healthData['sleep']![i];
        final date = now.subtract(Duration(days: (6 - i)));
        
        // Não salva valores padrão (7.5) se não houver dados reais
        if (spot.y == 7.5) {
          print('⏭️ [HealthDataService] Valor padrão (7.5) para ${date.toString()}, pulando...');
          skippedCount++;
          continue;
        }
        
        // Verifica se já existe um registro para esta data
        final dateKey = DateTime(date.year, date.month, date.day);
        Map<String, dynamic>? existingRecord;
        
        try {
          existingRecord = existingData.firstWhere(
            (existing) {
              final existingDate = existing['data'] as DateTime;
              final existingDateKey = DateTime(existingDate.year, existingDate.month, existingDate.day);
              return existingDateKey.isAtSameMomentAs(dateKey);
            },
          ) as Map<String, dynamic>?;
        } catch (e) {
          // Não encontrado, existingRecord permanece null
          existingRecord = null;
        }
        
        if (existingRecord != null) {
          // Se existe e é valor padrão (7.5) ou fonte de teste, atualiza com dados reais
          final existingValue = existingRecord['valor'] as num?;
          final existingSource = existingRecord['fonte'] as String?;
          
          if (existingValue == 7.5 || existingSource == 'Teste' || existingSource == 'Test') {
            print('🔄 [HealthDataService] Atualizando dados de sono para ${dateKey.toString()} de $existingValue para ${spot.y} horas');
            
            await collection.update(
              {'_id': existingRecord['_id']},
              {
                '\$set': {
                  'valor': spot.y,
                  'fonte': 'HealthKit',
                  'descricao': 'Tempo dormido',
                  'updatedAt': DateTime.now(),
                }
              },
            );
            savedCount++;
            print('✅ [HealthDataService] Dados de sono atualizados: ${dateKey.toString()} = ${spot.y} horas');
          } else {
            print('⏭️ [HealthDataService] Dados de sono para ${dateKey.toString()} já existem com valor real ($existingValue), pulando...');
            skippedCount++;
          }
          continue;
        }
        
        // Cria novo registro
        final data = {
          'pacienteId': patientId,
          'valor': spot.y,
          'data': dateKey,
          'fonte': 'HealthKit',
          'unidade': 'horas',
          'descricao': 'Tempo dormido',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        
        await collection.insert(data);
        savedCount++;
        print('✅ [HealthDataService] Dados de sono salvos: ${dateKey.toString()} = ${spot.y} horas');
      }
      
      print('💾 [HealthDataService] Resumo: $savedCount salvos, $skippedCount pulados');
      
    } catch (e, stackTrace) {
      print('❌ [HealthDataService] Erro ao salvar dados de sono: $e');
      print('❌ [HealthDataService] Stack trace: $stackTrace');
    }
  }

  // Busca dados de saúde do banco de dados
  Future<List<HealthData>> getHealthDataByPatient(String patientId) async {
    try {
      return await _db.getHealthDataByPatientId(patientId);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde por tipo
  Future<List<HealthData>> getHealthDataByType(String patientId, String dataType) async {
    try {
      return await _db.getHealthDataByType(patientId, dataType);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde por período
  Future<List<HealthData>> getHealthDataByPeriod(
    String patientId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      return await _db.getHealthDataByPeriod(patientId, startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde dos últimos N dias
  Future<List<HealthData>> getHealthDataLastDays(String patientId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      return await getHealthDataByPeriod(patientId, startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde do dia atual
  Future<List<HealthData>> getTodayHealthData(String patientId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      return await getHealthDataByPeriod(patientId, startOfDay, endOfDay);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde da semana atual
  Future<List<HealthData>> getThisWeekHealthData(String patientId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfDay.add(Duration(days: 7));
      
      return await getHealthDataByPeriod(patientId, startOfDay, endOfWeek);
    } catch (e) {
      rethrow;
    }
  }

  // Busca dados de saúde do mês atual
  Future<List<HealthData>> getThisMonthHealthData(String patientId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);
      
      return await getHealthDataByPeriod(patientId, startOfMonth, endOfMonth);
    } catch (e) {
      rethrow;
    }
  }

  // Calcula estatísticas dos dados de saúde
  Future<Map<String, dynamic>> getHealthDataStats(String patientId, String dataType) async {
    try {
      final data = await getHealthDataByType(patientId, dataType);
      
      if (data.isEmpty) {
        return {
          'count': 0,
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'latest': null,
        };
      }
      
      final values = data.map((d) => d.value).toList();
      final sum = values.reduce((a, b) => a + b);
      
      return {
        'count': data.length,
        'average': sum / data.length,
        'min': values.reduce((a, b) => a < b ? a : b),
        'max': values.reduce((a, b) => a > b ? a : b),
        'latest': data.first.value,
        'latestDate': data.first.date,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Sincroniza dados do HealthKit com o banco de dados
  Future<void> syncHealthData(String patientId) async {
    try {
      
      // Verifica se tem permissões
      final hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        return;
      }

      // Busca dados existentes do banco
      final existingData = await getHealthDataLastDays(patientId, 7);
      
      // Busca dados do HealthKit
      final healthData = await _healthService.getAllHealthData();
      
      // Verifica quais dados são novos
      final newDataList = <HealthData>[];
      final now = DateTime.now();
      
      // Processa frequência cardíaca
      if (healthData['heartRate'] != null && healthData['heartRate']!.isNotEmpty) {
        for (int i = 0; i < healthData['heartRate']!.length; i++) {
          final spot = healthData['heartRate']![i];
          final date = now.subtract(Duration(days: (6 - i)));
          
          // Verifica se já existe
          final exists = existingData.any((data) => 
            data.dataType == 'heartRate' && 
            data.date.day == date.day &&
            data.date.month == date.month &&
            data.date.year == date.year
          );
          
          if (!exists) {
            newDataList.add(HealthData(
              patientId: patientId,
              dataType: 'heartRate',
              value: spot.y,
              date: date,
              source: 'HealthKit',
              metadata: {
                'unit': 'bpm',
                'description': 'Frequência cardíaca'
              },
            ));
          }
        }
      }
      
      // Processa dados de sono
      if (healthData['sleep'] != null && healthData['sleep']!.isNotEmpty) {
        for (int i = 0; i < healthData['sleep']!.length; i++) {
          final spot = healthData['sleep']![i];
          final date = now.subtract(Duration(days: (6 - i)));
          
          // Verifica se já existe
          final exists = existingData.any((data) => 
            data.dataType == 'sleep' && 
            data.date.day == date.day &&
            data.date.month == date.month &&
            data.date.year == date.year
          );
          
          if (!exists) {
            newDataList.add(HealthData(
              patientId: patientId,
              dataType: 'sleep',
              value: spot.y,
              date: date,
              source: 'HealthKit',
              metadata: {
                'unit': 'hours',
                'description': 'Horas de sono'
              },
            ));
          }
        }
      }
      
      // Processa dados de passos
      if (healthData['steps'] != null && healthData['steps']!.isNotEmpty) {
        for (int i = 0; i < healthData['steps']!.length; i++) {
          final spot = healthData['steps']![i];
          final date = now.subtract(Duration(days: (6 - i)));
          
          // Verifica se já existe
          final exists = existingData.any((data) => 
            data.dataType == 'steps' && 
            data.date.day == date.day &&
            data.date.month == date.month &&
            data.date.year == date.year
          );
          
          if (!exists) {
            newDataList.add(HealthData(
              patientId: patientId,
              dataType: 'steps',
              value: spot.y,
              date: date,
              source: 'HealthKit',
              metadata: {
                'unit': 'steps',
                'description': 'Passos diários'
              },
            ));
          }
        }
      }
      
      if (newDataList.isNotEmpty) {
        // Salva apenas dados novos
        await _db.createMultipleHealthData(newDataList);
      } else {
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Deleta dados de saúde
  Future<void> deleteHealthData(String healthDataId) async {
    try {
      await _db.deleteHealthData(healthDataId);
    } catch (e) {
      rethrow;
    }
  }
}
