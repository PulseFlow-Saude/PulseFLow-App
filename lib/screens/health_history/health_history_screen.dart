import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/health_data_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  final DatabaseService _db = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();
  final HealthDataService _healthDataService = HealthDataService();
  
  bool _isLoading = true;
  String? _error;
  String _selectedDataType = 'heartRate';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  
  List<Map<String, dynamic>> _dailyData = [];

  @override
  void initState() {
    super.initState();
    // Define período padrão: últimos 30 dias
    _selectedDateTo = DateTime.now();
    _selectedDateFrom = DateTime.now().subtract(const Duration(days: 30));
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        throw 'Usuário não autenticado';
      }

      if (_selectedDateFrom == null || _selectedDateTo == null) {
        throw 'Selecione um período';
      }

      // Busca dados do período selecionado
      final healthData = await _healthDataService.getHealthDataByPeriod(
        currentUser!.id!,
        _selectedDateFrom!,
        _selectedDateTo!,
      );

      // Filtra por tipo selecionado
      final filteredData = healthData
          .where((d) => d.dataType == _selectedDataType)
          .toList();

      // Agrupa por dia e calcula média diária
      final Map<String, List<double>> dailyValues = {};
      
      for (final data in filteredData) {
        final dateKey = DateFormat('yyyy-MM-dd').format(data.date);
        dailyValues.putIfAbsent(dateKey, () => []).add(data.value);
      }

      // Cria lista de médias diárias
      _dailyData = dailyValues.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final values = entry.value;
        final average = values.reduce((a, b) => a + b) / values.length;
        
        return {
          'date': date,
          'value': average,
          'count': values.length,
        };
      }).toList();

      // Ordena por data (mais recente primeiro)
      _dailyData.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateFrom != null && _selectedDateTo != null
          ? DateTimeRange(start: _selectedDateFrom!, end: _selectedDateTo!)
          : null,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00324A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateFrom = picked.start;
        _selectedDateTo = picked.end;
      });
      await _loadHealthData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Histórico de Saúde',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() {
            final homeController = Get.find<HomeController>();
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white),
                  if (homeController.unreadNotificationsCount.value > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          homeController.unreadNotificationsCount.value > 9 
                              ? '9+' 
                              : homeController.unreadNotificationsCount.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Get.toNamed(Routes.NOTIFICATIONS);
                try {
                  final homeController = Get.find<HomeController>();
                  await homeController.loadNotificationsCount();
                } catch (e) {
                }
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              // Força sincronização com HealthKit antes de recarregar
              final authService = Get.find<AuthService>();
              final healthDataService = Get.find<HealthDataService>();
              
              if (authService.currentUser?.id != null) {
                try {
                  Get.snackbar(
                    'Sincronizando',
                    'Atualizando dados do Apple Health...',
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                  
                  print('🔄 [HealthHistory] Sincronizando dados do HealthKit...');
                  await healthDataService.saveHealthDataFromHealthKit(authService.currentUser!.id!);
                  
                  print('✅ [HealthHistory] Sincronização concluída, aguardando salvamento...');
                  // Aguarda mais tempo para garantir que os dados foram salvos no banco
                  await Future.delayed(const Duration(milliseconds: 1000));
                  
                  print('🔄 [HealthHistory] Recarregando dados do banco...');
                  // Limpa os dados antes de recarregar
                  setState(() {
                    _dailyData.clear();
                  });
                  // Recarrega os dados
                  await _loadHealthData();
                  
                  print('✅ [HealthHistory] Recarregamento concluído. Total de dados: ${_dailyData.length}');
                  
                  Get.snackbar(
                    'Sucesso',
                    'Dados atualizados com sucesso!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                } catch (e) {
                  Get.snackbar(
                    'Erro',
                    'Erro ao sincronizar dados: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                _loadHealthData();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando dados...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erro: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Filtros
          _buildFilters(),
          const SizedBox(height: 16),
          
          // Lista de dados
          _buildDataList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Seletor de tipo de dado
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChip('Frequência Cardíaca', 'heartRate', Icons.favorite),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Passos', 'steps', Icons.directions_walk),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Sono', 'sleep', Icons.bedtime),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Seletor de período
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF00324A), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Período',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateFrom != null && _selectedDateTo != null
                            ? '${DateFormat('dd/MM/yyyy').format(_selectedDateFrom!)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateTo!)}'
                            : 'Selecione um período',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedDataType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDataType = value;
        });
        _loadHealthData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00324A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataList() {
    return ListView.builder(
      itemCount: _dailyData.length,
      itemBuilder: (context, index) {
        final data = _dailyData[index];
        final date = data['date'] as DateTime;
        final value = data['value'] as double;
        final count = data['count'] as int;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getDataTypeColor(_selectedDataType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDataTypeIcon(_selectedDataType),
                  color: _getDataTypeColor(_selectedDataType),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Média diária',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.toStringAsFixed(_selectedDataType == 'sleep' ? 1 : 0)} ${_getDataTypeUnit(_selectedDataType)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getDataTypeColor(_selectedDataType),
                    ),
                  ),
                  if (count > 1)
                    Text(
                      '$count registros',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando dados...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Erro desconhecido',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHealthData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00324A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDataTypeIcon(_selectedDataType),
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum dado encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Não há registros de ${_getDataTypeName(_selectedDataType).toLowerCase()} no período selecionado',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDataTypeName(String type) {
    switch (type) {
      case 'heartRate':
        return 'Frequência Cardíaca';
      case 'steps':
        return 'Passos';
      case 'sleep':
        return 'Sono';
      default:
        return type;
    }
  }

  Color _getDataTypeColor(String type) {
    switch (type) {
      case 'heartRate':
        return Colors.red;
      case 'steps':
        return Colors.green;
      case 'sleep':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getDataTypeIcon(String type) {
    switch (type) {
      case 'heartRate':
        return Icons.favorite;
      case 'steps':
        return Icons.directions_walk;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.health_and_safety;
    }
  }

  String _getDataTypeUnit(String type) {
    switch (type) {
      case 'heartRate':
        return 'bpm';
      case 'steps':
        return 'passos';
      case 'sleep':
        return 'h';
      default:
        return '';
    }
  }
}
