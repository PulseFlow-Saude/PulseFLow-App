import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartwatchService extends GetxService {
  static SmartwatchService get instance => Get.find<SmartwatchService>();
  
  // Dados observáveis
  final _heartRateData = <HeartRateData>[].obs;
  final _sleepData = <SleepData>[].obs;
  final _activityData = <ActivityData>[].obs;
  final _isConnected = false.obs;
  final _lastSyncTime = Rxn<DateTime>();
  
  // Bluetooth
  final _isScanning = false.obs;
  final _availableDevices = <BluetoothDevice>[].obs;
  final _connectedDevice = Rxn<BluetoothDevice>();
  final _isConnecting = false.obs;
  
  // Getters
  List<HeartRateData> get heartRateData => _heartRateData;
  List<SleepData> get sleepData => _sleepData;
  List<ActivityData> get activityData => _activityData;
  bool get isConnected => _isConnected.value;
  DateTime? get lastSyncTime => _lastSyncTime.value;
  
  // Bluetooth getters
  bool get isScanning => _isScanning.value;
  List<BluetoothDevice> get availableDevices => _availableDevices;
  BluetoothDevice? get connectedDevice => _connectedDevice.value;
  bool get isConnecting => _isConnecting.value;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await checkPermissions();
    await _initializeHealth();
  }
  
  // Verifica permissões necessárias
  Future<bool> checkPermissions() async {
    try {
      
      // Lista de permissões necessárias
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
      
      // Verifica se todas as permissões foram concedidas
      bool allGranted = permissions.values.every((status) => status == PermissionStatus.granted);
      
      if (!allGranted) {
        permissions.forEach((permission, status) {
          if (status != PermissionStatus.granted) {
          }
        });
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Inicializa o serviço de saúde
  Future<void> _initializeHealth() async {
    try {
      if (!_isConnected.value) {
        await checkPermissions();
      }
      
      if (_isConnected.value) {
        await syncAllData();
      }
    } catch (e) {
    }
  }
  
  // Sincroniza todos os dados do smartwatch
  Future<void> syncAllData() async {
    if (!_isConnected.value) {
      return;
    }
    
    try {
      
      // Gera dados simulados para demonstração
      await _generateSampleData();
      
      _lastSyncTime.value = DateTime.now();
      
    } catch (e) {
    }
  }
  
  // Gera dados de exemplo para demonstração
  Future<void> _generateSampleData() async {
    _heartRateData.clear();
    _sleepData.clear();
    _activityData.clear();
    
    final now = DateTime.now();
    
    // Gera dados de frequência cardíaca dos últimos 7 dias
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      for (int j = 0; j < 24; j++) {
        final timestamp = date.add(Duration(hours: j));
        final heartRate = 70 + (j * 2) + (i * 3); // Variação simulada
        
        _heartRateData.add(HeartRateData(
          timestamp: timestamp,
          value: heartRate,
          type: HeartRateType.current,
        ));
      }
    }
    
    // Gera dados de sono
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final sleepTime = date.add(Duration(hours: 22)); // 22h
      
      _sleepData.add(SleepData(
        timestamp: sleepTime,
        duration: Duration(hours: 9), // 9 horas de sono
        type: SleepType.inBed,
      ));
    }
    
    // Gera dados de atividade
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final steps = 8000 + (i * 500) + (i % 2 == 0 ? 1000 : 0); // Variação de passos
      final calories = 200 + (i * 50);
      final distance = steps * 0.0008; // Aproximadamente 0.8m por passo
      
      _activityData.add(ActivityData(
        timestamp: date,
        value: steps.toDouble(),
        type: ActivityType.steps,
      ));
      
      _activityData.add(ActivityData(
        timestamp: date,
        value: calories.toDouble(),
        type: ActivityType.activeCalories,
      ));
      
      _activityData.add(ActivityData(
        timestamp: date,
        value: distance,
        type: ActivityType.distance,
      ));
    }
    
  }
  
  // Força nova sincronização
  Future<void> forceSync() async {
    await syncAllData();
  }
  
  // Solicita permissões manualmente
  Future<bool> requestPermissions() async {
    try {
      
      // Lista de permissões necessárias
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
      
      // Verifica se todas as permissões foram concedidas
      bool allGranted = permissions.values.every((status) => status == PermissionStatus.granted);
      
      if (!allGranted) {
        permissions.forEach((permission, status) {
          if (status != PermissionStatus.granted) {
          }
        });
        
        // Se alguma permissão foi negada permanentemente, abre configurações
        bool hasPermanentlyDenied = permissions.values.any((status) => status == PermissionStatus.permanentlyDenied);
        if (hasPermanentlyDenied) {
          await openAppSettings();
        }
        
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Escaneia dispositivos Bluetooth próximos
  Future<void> scanForDevices() async {
    try {
      if (_isScanning.value) return;
      
      
      // Primeiro, verifica e solicita permissões
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        return;
      }
      
      _isScanning.value = true;
      _availableDevices.clear();
      
      // Verifica se o Bluetooth está ligado
      if (await FlutterBluePlus.isOn == false) {
        _isScanning.value = false;
        return;
      }
      
      
      // Inicia o escaneamento
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [], // Procura todos os dispositivos
      );
      
      // Escuta os dispositivos encontrados
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final device = result.device;
          
          // Filtra dispositivos de smartwatch comuns
          if (_isSmartwatchDevice(device)) {
            if (!_availableDevices.any((d) => d.remoteId == device.remoteId)) {
              _availableDevices.add(device);
            }
          }
        }
      });
      
      // Para o escaneamento após 10 segundos
      Future.delayed(const Duration(seconds: 10), () {
        if (_isScanning.value) {
          FlutterBluePlus.stopScan();
          _isScanning.value = false;
        }
      });
      
    } catch (e) {
      _isScanning.value = false;
    }
  }
  
  // Verifica se é um dispositivo de smartwatch
  bool _isSmartwatchDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    
    // Lista de marcas de smartwatch comuns
    final smartwatchKeywords = [
      'watch',
      'band',
      'fit',
      'gear',
      'moto 360',
      'galaxy watch',
      'apple watch',
      'huawei',
      'xiaomi',
      'amazfit',
      'garmin',
      'polar',
      'fitbit',
      'fossil',
      'tizen',
      'wear os'
    ];
    
    return smartwatchKeywords.any((keyword) => name.contains(keyword));
  }
  
  // Conecta com um dispositivo específico
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_isConnecting.value) return false;
      
      _isConnecting.value = true;
      
      // Conecta com o dispositivo
      await device.connect();
      
      // Verifica se a conexão foi bem-sucedida
      if (device.isConnected) {
        _connectedDevice.value = device;
        _isConnected.value = true;
        
        
        // Escuta mudanças de conexão
        device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _isConnected.value = false;
            _connectedDevice.value = null;
          }
        });
        
        // Inicia a coleta de dados
        await _startDataCollection(device);
        
        _isConnecting.value = false;
        return true;
      } else {
        _isConnecting.value = false;
        return false;
      }
      
    } catch (e) {
      _isConnecting.value = false;
      return false;
    }
  }
  
  // Desconecta do dispositivo
  Future<void> disconnect() async {
    try {
      if (_connectedDevice.value != null) {
        await _connectedDevice.value!.disconnect();
        _connectedDevice.value = null;
        _isConnected.value = false;
      }
    } catch (e) {
    }
  }
  
  // Inicia a coleta de dados do dispositivo conectado
  Future<void> _startDataCollection(BluetoothDevice device) async {
    try {
      
      // Descobre serviços do dispositivo
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        // Serviço de frequência cardíaca
        if (service.uuid.toString().toLowerCase().contains('heart')) {
          await _subscribeToHeartRateService(service);
        }
        
        // Serviço de atividade física
        if (service.uuid.toString().toLowerCase().contains('fitness') ||
            service.uuid.toString().toLowerCase().contains('activity')) {
          await _subscribeToActivityService(service);
        }
      }
      
      // Se não encontrou serviços específicos, usa dados simulados
      if (_heartRateData.isEmpty && _activityData.isEmpty) {
        await _generateSampleData();
      }
      
    } catch (e) {
      // Usa dados simulados como fallback
      await _generateSampleData();
    }
  }
  
  // Subscreve ao serviço de frequência cardíaca
  Future<void> _subscribeToHeartRateService(BluetoothService service) async {
    try {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          
          characteristic.lastValueStream.listen((data) {
            if (data.isNotEmpty) {
              // Processa dados de frequência cardíaca
              final heartRate = data[1]; // Assumindo que o valor está no segundo byte
              
              _heartRateData.add(HeartRateData(
                timestamp: DateTime.now(),
                value: heartRate,
                type: HeartRateType.current,
              ));
              
            }
          });
        }
      }
    } catch (e) {
    }
  }
  
  // Subscreve ao serviço de atividade física
  Future<void> _subscribeToActivityService(BluetoothService service) async {
    try {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          
          characteristic.lastValueStream.listen((data) {
            if (data.isNotEmpty) {
              // Processa dados de atividade
              final steps = (data[0] << 8) | data[1]; // Assumindo 2 bytes para passos
              
              _activityData.add(ActivityData(
                timestamp: DateTime.now(),
                value: steps.toDouble(),
                type: ActivityType.steps,
              ));
              
            }
          });
        }
      }
    } catch (e) {
    }
  }
  
  // Verifica se há dados recentes
  bool hasRecentData() {
    if (_lastSyncTime.value == null) return false;
    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime.value!);
    return diff.inHours < 24; // Dados de até 24 horas
  }
  
  // Obtém dados de frequência cardíaca para gráfico
  List<FlSpot> getHeartRateChartData() {
    return _heartRateData
        .where((data) => data.type == HeartRateType.current)
        .map((data) => FlSpot(
              data.timestamp.millisecondsSinceEpoch.toDouble(),
              data.value.toDouble(),
            ))
        .toList();
  }
  
  // Obtém dados de passos para gráfico
  List<FlSpot> getStepsChartData() {
    final dailySteps = <DateTime, int>{};
    
    for (var data in _activityData) {
      if (data.type == ActivityType.steps) {
        final date = DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
        dailySteps[date] = (dailySteps[date] ?? 0) + data.value.toInt();
      }
    }
    
    return dailySteps.entries
        .map((entry) => FlSpot(
              entry.key.millisecondsSinceEpoch.toDouble(),
              entry.value.toDouble(),
            ))
        .toList();
  }
  
  // Obtém resumo dos dados de hoje
  Map<String, dynamic> getTodaySummary() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Frequência cardíaca média
    final todayHeartRate = _heartRateData
        .where((data) => 
            data.timestamp.isAfter(startOfDay) && 
            data.timestamp.isBefore(endOfDay) &&
            data.type == HeartRateType.current)
        .map((data) => data.value)
        .toList();
    
    final avgHeartRate = todayHeartRate.isEmpty 
        ? 0 
        : todayHeartRate.reduce((a, b) => a + b) / todayHeartRate.length;
    
    // Passos de hoje
    final todaySteps = _activityData
        .where((data) => 
            data.timestamp.isAfter(startOfDay) && 
            data.timestamp.isBefore(endOfDay) &&
            data.type == ActivityType.steps)
        .map((data) => data.value.toInt())
        .fold<int>(0, (sum, steps) => sum + steps);
    
    // Calorias ativas de hoje
    final todayCalories = _activityData
        .where((data) => 
            data.timestamp.isAfter(startOfDay) && 
            data.timestamp.isBefore(endOfDay) &&
            data.type == ActivityType.activeCalories)
        .map((data) => data.value.toInt())
        .fold<int>(0, (sum, calories) => sum + calories);
    
    return {
      'avgHeartRate': avgHeartRate.round(),
      'steps': todaySteps,
      'calories': todayCalories,
      'lastSync': _lastSyncTime.value,
    };
  }
}

// Classes de dados
class HeartRateData {
  final DateTime timestamp;
  final int value;
  final HeartRateType type;
  
  HeartRateData({
    required this.timestamp,
    required this.value,
    required this.type,
  });
}

class SleepData {
  final DateTime timestamp;
  final Duration duration;
  final SleepType type;
  
  SleepData({
    required this.timestamp,
    required this.duration,
    required this.type,
  });
}

class ActivityData {
  final DateTime timestamp;
  final double value;
  final ActivityType type;
  
  ActivityData({
    required this.timestamp,
    required this.value,
    required this.type,
  });
}

// Enums
enum HeartRateType {
  current,
  resting,
  walking,
}

enum SleepType {
  inBed,
  awake,
  deep,
  light,
  rem,
}

enum ActivityType {
  steps,
  activeCalories,
  basalCalories,
  distance,
}
