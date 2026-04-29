import 'package:health/health.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  // Tipos de dados de saúde que queremos acessar
  static const List<HealthDataType> _healthDataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_IN_BED, // Tempo na cama
    HealthDataType.SLEEP_ASLEEP, // Tempo dormindo
    HealthDataType.SLEEP_AWAKE, // Tempo acordado durante o sono
    HealthDataType.SLEEP_DEEP, // Sono profundo
    HealthDataType.SLEEP_REM, // Sono REM
    HealthDataType.STEPS,
  ];

  // Solicita permissões para acessar dados de saúde
  Future<bool> requestPermissions() async {
    try {
      print('🔐 [HealthService] Solicitando permissões do HealthKit...');
      
      // Verifica se o HealthKit está disponível (método não disponível na versão 9.0.1)
      // bool isAvailable = await _health.isHealthDataAvailable();
      
      bool requested = await _health.requestAuthorization(_healthDataTypes);
      
      if (requested) {
        print('✅ [HealthService] Permissões concedidas');
        return true;
      } else {
        print('❌ [HealthService] Permissões negadas');
        return false;
      }
    } catch (e) {
      print('❌ [HealthService] Erro ao solicitar permissões: $e');
      return false;
    }
  }

  // Busca dados de frequência cardíaca dos últimos 7 dias
  Future<List<FlSpot>> getHeartRateData() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      print('📊 [HealthService] Buscando dados de frequência cardíaca de ${weekAgo.toString()} até ${now.toString()}');
      
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      print('📊 [HealthService] Encontrados ${healthData.length} pontos de dados de frequência cardíaca');

      // Agrupa dados por data completa (ano-mês-dia) e calcula média
      Map<String, List<double>> dailyData = {};
      
      for (var dataPoint in healthData) {
        final dateKey = '${dataPoint.dateFrom.year}-${dataPoint.dateFrom.month}-${dataPoint.dateFrom.day}';
        final value = _getHealthValueAsDouble(dataPoint.value);
        
        if (dailyData[dateKey] == null) {
          dailyData[dateKey] = [];
        }
        dailyData[dateKey]!.add(value);
      }

      // Converte para FlSpot (últimos 7 dias)
      List<FlSpot> spots = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (dailyData[dateKey] != null && dailyData[dateKey]!.isNotEmpty) {
          // Calcula média dos valores do dia
          final average = dailyData[dateKey]!.reduce((a, b) => a + b) / dailyData[dateKey]!.length;
          print('📊 [HealthService] Dia $dateKey: média de ${average.toStringAsFixed(1)} bpm');
          spots.add(FlSpot(i.toDouble(), average));
        } else {
          // Se não há dados, usa valor padrão
          print('⚠️ [HealthService] Dia $dateKey: sem dados, usando valor padrão');
          spots.add(FlSpot(i.toDouble(), 70.0));
        }
      }

      return spots;
    } catch (e) {
      print('❌ [HealthService] Erro ao buscar dados de frequência cardíaca: $e');
      return _generateFallbackHeartRateData();
    }
  }

  // Busca dados de sono dos últimos 7 dias (tempo dormido)
  Future<List<FlSpot>> getSleepData() async {
    try {
      final now = DateTime.now();
      // Busca dos últimos 30 dias para ter mais dados disponíveis
      final startDate = now.subtract(const Duration(days: 30));

      print('📊 [HealthService] Buscando TODOS os dados de sono de ${startDate.toString()} até ${now.toString()}');

      // Busca TODOS os tipos de dados de sono disponíveis no HealthKit
      final allSleepTypes = [
        HealthDataType.SLEEP_ASLEEP, // Tempo dormindo
        HealthDataType.SLEEP_IN_BED, // Tempo na cama
        HealthDataType.SLEEP_AWAKE, // Tempo acordado durante o sono
        HealthDataType.SLEEP_DEEP, // Sono profundo
        HealthDataType.SLEEP_REM, // Sono REM
      ];
      
      // Busca todos os tipos de dados de sono simultaneamente
      final allSleepData = <HealthDataPoint>[];
      final sleepDataByType = <String, int>{};
      
      // Busca cada tipo de dado de sono individualmente para garantir que todos sejam coletados
      for (var sleepType in allSleepTypes) {
        try {
          List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
            startTime: startDate,
            endTime: now,
            types: [sleepType],
          );
          
          final typeName = sleepType.toString().split('.').last;
          final count = sleepData.length;
          sleepDataByType[typeName] = count;
          
          if (count > 0) {
            print('✅ [HealthService] Encontrados $count períodos de $typeName');
            // Adiciona TODOS os períodos encontrados (são medidas diferentes, não duplicatas)
            allSleepData.addAll(sleepData);
          } else {
            print('⚪ [HealthService] Nenhum período de $typeName encontrado');
          }
        } catch (e) {
          final typeName = sleepType.toString().split('.').last;
          print('⚠️ [HealthService] Erro ao buscar $typeName: $e');
          // Continua buscando outros tipos mesmo se um falhar
        }
      }
      
      // Resumo detalhado
      print('📊 [HealthService] ===== RESUMO DE DADOS DE SONO =====');
      int totalPeriods = 0;
      sleepDataByType.forEach((type, count) {
        if (count > 0) {
          print('  📈 $type: $count períodos');
          totalPeriods += count;
        }
      });
      print('📊 [HealthService] Total geral: $totalPeriods períodos de sono coletados');
      print('📊 [HealthService] ===================================');
      
      if (allSleepData.isEmpty) {
        print('⚠️ [HealthService] Nenhum dado de sono encontrado. Executando diagnóstico...');
        // Tenta diagnosticar o problema
        await diagnoseHealthData();
      } else {
        print('✅ [HealthService] Total de períodos de sono encontrados: ${allSleepData.length}');
      }

      // Agrupa dados por data completa (ano-mês-dia)
      // Considera que um período de sono pode começar em um dia e terminar no outro
      // IMPORTANTE: Soma TODOS os períodos, sem remover duplicatas (pois são medidas diferentes)
      Map<String, double> dailySleep = {};
      
      print('📊 [HealthService] Processando ${allSleepData.length} períodos de sono para agrupamento...');
      
      for (var dataPoint in allSleepData) {
        // Para dados de sono, calcula a duração em horas com decimais
        final durationInMinutes = dataPoint.dateTo.difference(dataPoint.dateFrom).inMinutes;
        final durationInHours = durationInMinutes / 60.0;
        
        // Identifica o tipo de dado de sono para log mais detalhado
        final dataType = dataPoint.type.toString().split('.').last;
        print('📊 [HealthService] Período $dataType: ${dataPoint.dateFrom.toString()} até ${dataPoint.dateTo.toString()} = ${durationInHours.toStringAsFixed(2)} horas');
        
        // Se o período cruza dois dias, divide o tempo entre os dias
        final startDate = DateTime(dataPoint.dateFrom.year, dataPoint.dateFrom.month, dataPoint.dateFrom.day);
        final endDate = DateTime(dataPoint.dateTo.year, dataPoint.dateTo.month, dataPoint.dateTo.day);
        
        if (startDate.isAtSameMomentAs(endDate)) {
          // Período está no mesmo dia - adiciona ao dia
          final dateKey = '${dataPoint.dateFrom.year}-${dataPoint.dateFrom.month}-${dataPoint.dateFrom.day}';
          final previousValue = dailySleep[dateKey] ?? 0.0;
          dailySleep[dateKey] = previousValue + durationInHours;
          print('  → Dia $dateKey: ${previousValue.toStringAsFixed(2)}h + ${durationInHours.toStringAsFixed(2)}h = ${dailySleep[dateKey]!.toStringAsFixed(2)}h');
        } else {
          // Período cruza dois dias - divide proporcionalmente
          final endOfStartDay = DateTime(dataPoint.dateFrom.year, dataPoint.dateFrom.month, dataPoint.dateFrom.day, 23, 59, 59);
          final startOfEndDay = DateTime(dataPoint.dateTo.year, dataPoint.dateTo.month, dataPoint.dateTo.day);
          
          final hoursInStartDay = endOfStartDay.difference(dataPoint.dateFrom).inMinutes / 60.0;
          final hoursInEndDay = dataPoint.dateTo.difference(startOfEndDay).inMinutes / 60.0;
          
          final startDateKey = '${dataPoint.dateFrom.year}-${dataPoint.dateFrom.month}-${dataPoint.dateFrom.day}';
          final endDateKey = '${dataPoint.dateTo.year}-${dataPoint.dateTo.month}-${dataPoint.dateTo.day}';
          
          // Adiciona às horas já existentes em cada dia
          final previousStartValue = dailySleep[startDateKey] ?? 0.0;
          final previousEndValue = dailySleep[endDateKey] ?? 0.0;
          
          dailySleep[startDateKey] = previousStartValue + hoursInStartDay;
          dailySleep[endDateKey] = previousEndValue + hoursInEndDay;
          
          print('  → Dividido: ${hoursInStartDay.toStringAsFixed(2)}h no dia $startDateKey (${previousStartValue.toStringAsFixed(2)}h → ${dailySleep[startDateKey]!.toStringAsFixed(2)}h)');
          print('              ${hoursInEndDay.toStringAsFixed(2)}h no dia $endDateKey (${previousEndValue.toStringAsFixed(2)}h → ${dailySleep[endDateKey]!.toStringAsFixed(2)}h)');
        }
      }

      print('📊 [HealthService] ===== RESUMO DE AGRUPAMENTO POR DIA =====');
      print('📊 [HealthService] Total de dias com dados de sono: ${dailySleep.length}');
      dailySleep.forEach((dateKey, hours) {
        print('  📅 $dateKey: ${hours.toStringAsFixed(2)} horas');
      });
      print('📊 [HealthService] ==========================================');

      // Converte para FlSpot (últimos 7 dias)
      // Mapeia os últimos 7 dias com os dados encontrados
      List<FlSpot> spots = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (dailySleep[dateKey] != null && dailySleep[dateKey]! > 0) {
          print('✅ [HealthService] Dia $dateKey: ${dailySleep[dateKey]!.toStringAsFixed(2)} horas de sono total');
          spots.add(FlSpot(i.toDouble(), dailySleep[dateKey]!));
        } else {
          // Se não há dados, usa valor padrão
          print('⚠️ [HealthService] Dia $dateKey: sem dados de sono, usando valor padrão (7.5h)');
          spots.add(FlSpot(i.toDouble(), 7.5));
        }
      }
      
      // Se encontrou dados mas não nos últimos 7 dias, mostra aviso
      if (dailySleep.isNotEmpty && spots.every((spot) => spot.y == 7.5)) {
        print('⚠️ [HealthService] Dados de sono encontrados, mas não nos últimos 7 dias');
        print('💡 [HealthService] Dados mais recentes: ${dailySleep.keys.toList().last}');
      }
      
      print('📊 [HealthService] Total de pontos no gráfico: ${spots.length}');
      print('📊 [HealthService] Pontos com dados reais: ${spots.where((s) => s.y != 7.5).length}');

      return spots;
    } catch (e) {
      print('❌ [HealthService] Erro ao buscar dados de sono: $e');
      return _generateFallbackSleepData();
    }
  }

  // Busca dados de passos dos últimos 7 dias
  Future<List<FlSpot>> getStepsData() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      print('📊 [HealthService] Buscando dados de passos de ${weekAgo.toString()} até ${now.toString()}');
      
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      print('📊 [HealthService] Encontrados ${healthData.length} pontos de dados de passos');

      // Agrupa dados por data completa (ano-mês-dia)
      Map<String, double> dailySteps = {};
      
      for (var dataPoint in healthData) {
        final dateKey = '${dataPoint.dateFrom.year}-${dataPoint.dateFrom.month}-${dataPoint.dateFrom.day}';
        final steps = _getHealthValueAsDouble(dataPoint.value);
        
        if (dailySteps[dateKey] == null) {
          dailySteps[dateKey] = 0.0;
        }
        dailySteps[dateKey] = dailySteps[dateKey]! + steps;
      }

      // Converte para FlSpot (últimos 7 dias)
      List<FlSpot> spots = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (dailySteps[dateKey] != null && dailySteps[dateKey]! > 0) {
          print('📊 [HealthService] Dia $dateKey: ${dailySteps[dateKey]!.toStringAsFixed(0)} passos');
          spots.add(FlSpot(i.toDouble(), dailySteps[dateKey]!));
        } else {
          // Se não há dados, usa valor padrão
          print('⚠️ [HealthService] Dia $dateKey: sem dados de passos, usando valor padrão');
          spots.add(FlSpot(i.toDouble(), 8000.0));
        }
      }

      return spots;
    } catch (e) {
      print('❌ [HealthService] Erro ao buscar dados de passos: $e');
      return _generateFallbackStepsData();
    }
  }

  // Converte HealthValue para double
  double _getHealthValueAsDouble(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    } else if (value is WorkoutHealthValue) {
      return value.totalEnergyBurned?.toDouble() ?? 0.0;
    } else if (value is ElectrocardiogramHealthValue) {
      return value.averageHeartRate?.toDouble() ?? 0.0;
    } else {
      // Para outros tipos, tenta converter para double
      try {
        return double.parse(value.toString());
      } catch (e) {
        return 0.0;
      }
    }
  }

  // Métodos de fallback com dados simulados
  List<FlSpot> _generateFallbackHeartRateData() {
    final List<FlSpot> spots = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final heartRate = 65 + (i * 2) + (date.day % 10);
      spots.add(FlSpot(i.toDouble(), heartRate.toDouble()));
    }
    
    return spots;
  }

  List<FlSpot> _generateFallbackSleepData() {
    final List<FlSpot> spots = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final sleepHours = 7.0 + (i * 0.5) + (date.day % 3);
      spots.add(FlSpot(i.toDouble(), sleepHours));
    }
    
    return spots;
  }

  List<FlSpot> _generateFallbackStepsData() {
    final List<FlSpot> spots = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = 8000 + (i * 500) + (date.day % 2000);
      spots.add(FlSpot(i.toDouble(), steps.toDouble()));
    }
    
    return spots;
  }

  // Verifica se as permissões foram concedidas
  Future<bool> hasPermissions() async {
    try {
      final result = await _health.hasPermissions(_healthDataTypes);
      
      // Se result é null, significa que as permissões não foram solicitadas ainda
      if (result == null) {
        print('⚠️ [HealthService] Permissões ainda não foram solicitadas - solicitando automaticamente...');
        // Solicita permissões automaticamente se nunca foram solicitadas
        final granted = await requestPermissions();
        return granted;
      }
      
      final hasPermission = result;
      print('🔐 [HealthService] Status de permissões: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('❌ [HealthService] Erro ao verificar permissões: $e');
      return false;
    }
  }

  // Busca todos os dados de saúde de uma vez
  Future<Map<String, List<FlSpot>>> getAllHealthData() async {
    try {
      print('📊 [HealthService] getAllHealthData() chamado');
      
      // Verifica permissões primeiro (já solicita automaticamente se necessário)
      final hasPermission = await hasPermissions();
      
      if (!hasPermission) {
        print('⚠️ [HealthService] Sem permissões, tentando solicitar novamente...');
        final granted = await requestPermissions();
        if (!granted) {
          print('❌ [HealthService] Permissões negadas, retornando dados de fallback');
          return _getFallbackData();
        }
      }
      
      print('✅ [HealthService] Permissões OK, buscando dados reais...');
      
      // Sempre tenta buscar dados reais
      // Busca dados com logs detalhados
      final heartRateData = await getHeartRateData();
      final sleepData = await getSleepData();
      final stepsData = await getStepsData();

      print('✅ [HealthService] Dados recuperados:');
      print('  - HeartRate: ${heartRateData.length} pontos');
      print('  - Sleep: ${sleepData.length} pontos');
      print('  - Steps: ${stepsData.length} pontos');
      
      return {
        'heartRate': heartRateData,
        'sleep': sleepData,
        'steps': stepsData,
      };
    } catch (e, stackTrace) {
      print('❌ [HealthService] Erro em getAllHealthData(): $e');
      print('❌ [HealthService] Stack trace: $stackTrace');
      return _getFallbackData();
    }
  }

  // Retorna dados de fallback
  Map<String, List<FlSpot>> _getFallbackData() {
    return {
      'heartRate': _generateFallbackHeartRateData(),
      'sleep': _generateFallbackSleepData(),
      'steps': _generateFallbackStepsData(),
    };
  }

  // Método de diagnóstico para verificar dados brutos do Apple Health
  Future<void> diagnoseHealthData() async {
    try {
      print('🔍 [HealthService] Iniciando diagnóstico de dados do HealthKit...');
      
      // Verifica permissões
      final hasPermission = await hasPermissions();
      
      if (!hasPermission) {
        print('⚠️ [HealthService] Sem permissões, solicitando...');
        final granted = await requestPermissions();
        if (!granted) {
          print('❌ [HealthService] Permissões negadas, não é possível diagnosticar');
          return;
        }
      }

      final now = DateTime.now();
      // Busca dos últimos 30 dias para diagnóstico
      final startDate = now.subtract(const Duration(days: 30));
      
      print('🔍 [HealthService] Diagnosticando dados de ${startDate.toString()} até ${now.toString()}');
      
      // Testa cada tipo de dado individualmente
      try {
        print('🔍 [HealthService] Testando frequência cardíaca...');
        final heartData = await _health.getHealthDataFromTypes(
          startTime: startDate, 
          endTime: now, 
          types: [HealthDataType.HEART_RATE]
        );
        print('🔍 [HealthService] Frequência cardíaca: ${heartData.length} pontos encontrados');
        if (heartData.isNotEmpty) {
          print('  - Primeiro: ${heartData.first.dateFrom} = ${_getHealthValueAsDouble(heartData.first.value)}');
          print('  - Último: ${heartData.last.dateFrom} = ${_getHealthValueAsDouble(heartData.last.value)}');
        }
      } catch (e) {
        print('❌ [HealthService] Erro ao buscar frequência cardíaca: $e');
      }

      try {
        print('🔍 [HealthService] Testando tempo dormindo (SLEEP_ASLEEP)...');
        final sleepAsleepData = await _health.getHealthDataFromTypes(
          startTime: startDate, 
          endTime: now, 
          types: [HealthDataType.SLEEP_ASLEEP]
        );
        print('🔍 [HealthService] Tempo dormindo (SLEEP_ASLEEP): ${sleepAsleepData.length} períodos encontrados');
        if (sleepAsleepData.isNotEmpty) {
          for (var i = 0; i < sleepAsleepData.length && i < 5; i++) {
            final data = sleepAsleepData[i];
            final duration = data.dateTo.difference(data.dateFrom).inHours;
            print('  - Período ${i + 1}: ${data.dateFrom} até ${data.dateTo} = $duration horas dormindo');
          }
        } else {
          print('⚠️ [HealthService] Nenhum dado de SLEEP_ASLEEP encontrado nos últimos 30 dias');
          print('💡 [HealthService] Tentando SLEEP_IN_BED como alternativa...');
          
          // Tenta SLEEP_IN_BED como alternativa
          final sleepInBedData = await _health.getHealthDataFromTypes(
            startTime: startDate, 
            endTime: now, 
            types: [HealthDataType.SLEEP_IN_BED]
          );
          print('🔍 [HealthService] Tempo na cama (SLEEP_IN_BED): ${sleepInBedData.length} períodos encontrados');
          if (sleepInBedData.isNotEmpty) {
            for (var i = 0; i < sleepInBedData.length && i < 5; i++) {
              final data = sleepInBedData[i];
              final duration = data.dateTo.difference(data.dateFrom).inHours;
              print('  - Período ${i + 1}: ${data.dateFrom} até ${data.dateTo} = $duration horas na cama');
            }
          } else {
            print('⚠️ [HealthService] Nenhum dado de sono encontrado nos últimos 30 dias');
            print('💡 [HealthService] Dica: Verifique se o Apple Health está registrando dados de sono');
          }
        }
      } catch (e) {
        print('❌ [HealthService] Erro ao buscar dados de sono: $e');
      }

      try {
        print('🔍 [HealthService] Testando passos...');
        final stepsData = await _health.getHealthDataFromTypes(
          startTime: startDate, 
          endTime: now, 
          types: [HealthDataType.STEPS]
        );
        print('🔍 [HealthService] Passos: ${stepsData.length} pontos encontrados');
        if (stepsData.isNotEmpty) {
          print('  - Primeiro: ${stepsData.first.dateFrom} = ${_getHealthValueAsDouble(stepsData.first.value)}');
          print('  - Último: ${stepsData.last.dateFrom} = ${_getHealthValueAsDouble(stepsData.last.value)}');
        }
      } catch (e) {
        print('❌ [HealthService] Erro ao buscar passos: $e');
      }

      print('✅ [HealthService] Diagnóstico concluído');
    } catch (e, stackTrace) {
      print('❌ [HealthService] Erro no diagnóstico: $e');
      print('❌ [HealthService] Stack trace: $stackTrace');
    }
  }
}