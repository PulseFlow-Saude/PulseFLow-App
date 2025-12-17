import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/health_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class HeartRateHistoryScreen extends StatefulWidget {
  const HeartRateHistoryScreen({super.key});

  @override
  State<HeartRateHistoryScreen> createState() => _HeartRateHistoryScreenState();
}

class _HeartRateHistoryScreenState extends State<HeartRateHistoryScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _db = Get.find<DatabaseService>();
  final HealthDataService _healthDataService = HealthDataService();
  
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  
  List<Map<String, dynamic>> _dailyData = [];

  @override
  void initState() {
    super.initState();
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

      // Busca dados diretamente da coleção 'batimentos'
      final collection = await _db.getCollection('batimentos');
      
      // Busca todos os dados do paciente
      final allData = await collection.find({
        'pacienteId': currentUser!.id!,
      }).toList();

      // Filtra por período
      final filteredData = allData.where((item) {
        if (item['data'] == null) return false;
        final itemDate = item['data'] is DateTime 
            ? item['data'] as DateTime 
            : DateTime.parse(item['data'].toString());
        return itemDate.isAfter(_selectedDateFrom!.subtract(const Duration(days: 1))) && 
               itemDate.isBefore(_selectedDateTo!.add(const Duration(days: 1)));
      }).toList();

      print('📊 [HeartRateHistory] Total de registros encontrados: ${filteredData.length}');

      // Agrupa por dia e calcula média diária
      final Map<String, List<double>> dailyValues = {};
      
      for (final item in filteredData) {
        if (item['valor'] == null) continue;
        final itemDate = item['data'] is DateTime 
            ? item['data'] as DateTime 
            : DateTime.parse(item['data'].toString());
        final dateKey = DateFormat('yyyy-MM-dd').format(itemDate);
        final valor = (item['valor'] as num).toDouble();
        dailyValues.putIfAbsent(dateKey, () => []).add(valor);
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
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A),
        drawer: const PulseSideMenu(activeItem: PulseNavItem.history),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildErrorState()
                          : _dailyData.isEmpty
                              ? _buildEmptyState()
                              : _buildContent(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const PulseDrawerButton(iconSize: 22),
              Expanded(
                child: Center(
                  child: Text(
                    'Frequência Cardíaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                onPressed: () async {
                  final authService = Get.find<AuthService>();
                  final healthDataService = HealthDataService();
                  
                  if (authService.currentUser?.id != null) {
                    try {
                      Get.snackbar(
                        'Sincronizando',
                        'Atualizando dados do Apple Health...',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      
                      await healthDataService.saveHealthDataFromHealthKit(authService.currentUser!.id!);
                      await Future.delayed(const Duration(milliseconds: 1000));
                      await _loadHealthData();
                      
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
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildContent() {
    // Calcula estatísticas
    final stats = _calculateStats();
    
    return Column(
        children: [
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
          const SizedBox(height: 16),
          
          // Estatísticas
          _buildStats(stats),
          const SizedBox(height: 16),
          
          // Gráfico
          if (_dailyData.isNotEmpty) ...[
            _buildChart(),
            const SizedBox(height: 16),
          ],
          
          // Análise
          if (stats != null) ...[
            _buildAnalysis(stats),
            const SizedBox(height: 16),
          ],
          
          // Lista de dados
          _buildDataList(),
          const SizedBox(height: 16),
        ],
      );
  }

  Map<String, dynamic>? _calculateStats() {
    if (_dailyData.isEmpty) return null;
    
    final values = _dailyData.map((d) => d['value'] as double).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Calcula tendência (comparando primeira metade com segunda metade)
    String trend = 'estável';
    Color trendColor = Colors.grey;
    if (_dailyData.length >= 4) {
      final firstHalf = _dailyData.sublist(0, _dailyData.length ~/ 2);
      final secondHalf = _dailyData.sublist(_dailyData.length ~/ 2);
      final firstAvg = firstHalf.map((d) => d['value'] as double).reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.map((d) => d['value'] as double).reduce((a, b) => a + b) / secondHalf.length;
      
      if (secondAvg > firstAvg + 5) {
        trend = 'aumentando';
        trendColor = Colors.orange;
      } else if (secondAvg < firstAvg - 5) {
        trend = 'diminuindo';
        trendColor = Colors.blue;
      }
    }
    
    return {
      'avg': avg,
      'min': min,
      'max': max,
      'count': _dailyData.length,
      'trend': trend,
      'trendColor': trendColor,
    };
  }

  Widget _buildStats(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Estatísticas do Período',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Média', '${stats['avg'].round()}', 'bpm', Colors.blue, Icons.trending_up),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Mínimo', '${stats['min'].round()}', 'bpm', Colors.green, Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Máximo', '${stats['max'].round()}', 'bpm', Colors.red, Icons.keyboard_arrow_up),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              '$value $unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_dailyData.isEmpty) return const SizedBox.shrink();
    
    // Ordena por data (mais antiga primeiro para o gráfico)
    final sortedData = List<Map<String, dynamic>>.from(_dailyData)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Evolução',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                      interval: 20,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (sortedData.length / 5).clamp(1, sortedData.length).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) return const SizedBox.shrink();
                        final date = sortedData[index]['date'] as DateTime;
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble(),
                minY: 0,
                maxY: sortedData.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['value'] as double);
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysis(Map<String, dynamic> stats) {
    final avg = stats['avg'] as double;
    String analysis = '';
    Color analysisColor = Colors.grey;
    IconData analysisIcon = Icons.info;
    
    // Análise baseada em valores normais de frequência cardíaca em repouso
    if (avg < 60) {
      analysis = 'Frequência cardíaca abaixo do normal (bradicardia). Consulte um médico se persistir.';
      analysisColor = Colors.blue;
      analysisIcon = Icons.warning;
    } else if (avg >= 60 && avg <= 100) {
      analysis = 'Frequência cardíaca dentro da faixa normal para adultos em repouso.';
      analysisColor = Colors.green;
      analysisIcon = Icons.check_circle;
    } else if (avg > 100 && avg <= 120) {
      analysis = 'Frequência cardíaca ligeiramente elevada. Monitore e consulte se persistir.';
      analysisColor = Colors.orange;
      analysisIcon = Icons.warning;
    } else {
      analysis = 'Frequência cardíaca elevada (taquicardia). Consulte um médico.';
      analysisColor = Colors.red;
      analysisIcon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: analysisColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: analysisColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(analysisIcon, color: analysisColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análise',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: analysisColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tendência: ${stats['trend']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: stats['trendColor'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Registros Diários',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        ...List.generate(_dailyData.length, (index) {
          final data = _dailyData[index];
          final date = data['date'] as DateTime;
          final value = data['value'] as double;
          final count = data['count'] as int;
          final min = data['min'] as double;
          final max = data['max'] as double;
          
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
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
                      'Média diária • Min: ${min.round()} • Max: ${max.round()}',
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
                    '${value.round()} bpm',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
        }),
      ],
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
          const Text(
            'Erro ao carregar dados',
            style: TextStyle(
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
            Icons.favorite,
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
          const Text(
            'Não há registros de frequência cardíaca no período selecionado',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

