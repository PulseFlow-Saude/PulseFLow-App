import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/health_metric_chart_utils.dart';
import '../../utils/intl_locale.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/health_data_service.dart';
import '../../theme/app_theme.dart';
import '../institutional/settings_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class SleepHistoryScreen extends StatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapOldestPatientRangeThenLoad('insonias');
    });
  }

  Future<void> _bootstrapOldestPatientRangeThenLoad(String collection) async {
    final user = _authService.currentUser;
    _selectedDateTo = metricChartDefaultEndDay();
    if (user?.id == null) {
      _selectedDateFrom = metricChartDefaultWideStartDay();
    } else {
      final bounds = await _db.getPatientMetricDateBounds(collection, user!.id!);
      _selectedDateFrom = bounds.min != null
          ? DateTime(bounds.min!.year, bounds.min!.month, bounds.min!.day)
          : _selectedDateTo;
    }
    if (!mounted) return;
    await _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        throw 'common_user_not_auth'.tr;
      }

      if (_selectedDateFrom == null || _selectedDateTo == null) {
        throw 'common_select_period'.tr;
      }

      final allData = await _db.fetchPatientMetricDocuments(
        'insonias',
        currentUser!.id!,
      );

      final filteredData = allData.where((item) {
        final raw = item['data'] ?? item['date'];
        final itemDate = coerceMongoDateField(raw);
        if (itemDate == null) return false;
        return metricDocInSelectedRange(
          itemDate,
          _selectedDateFrom!,
          _selectedDateTo!,
        );
      }).toList();

      print('📊 [SleepHistory] Total de registros encontrados: ${filteredData.length}');

      // Agrupa por dia e calcula total diário
      final Map<String, List<double>> dailyValues = {};
      
      for (final item in filteredData) {
        final raw = item['data'] ?? item['date'];
        final itemDate = coerceMongoDateField(raw);
        if (itemDate == null) continue;
        final valor = coerceMongoNumber(item['valor'] ?? item['value']);
        if (valor < 0) continue;
        final dateKey = DateFormat('yyyy-MM-dd').format(itemDate);
        dailyValues.putIfAbsent(dateKey, () => []).add(valor);
      }

      // Cria lista de totais diários
      _dailyData = dailyValues.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final values = entry.value;
        final total = values.reduce((a, b) => a + b);
        
        return {
          'date': date,
          'value': total.toDouble(),
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
      firstDate: metricChartPickerFirstDate(),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateFrom != null && _selectedDateTo != null
          ? DateTimeRange(start: _selectedDateFrom!, end: _selectedDateTo!)
          : null,
      locale: Get.find<SettingsController>().effectiveLocale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
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
        backgroundColor: Colors.transparent,
        drawer: const PulseSideMenu(activeItem: PulseNavItem.history),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.blueScreenGradientDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: AppTheme.blueContentSheetDecoration,
                  clipBehavior: Clip.antiAlias,
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
        ),
        // bottomNavigationBar removido - tela tem sidebar
        // bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const PulseDrawerButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'health_sleep'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: () async {
                  final authService = Get.find<AuthService>();
                  final healthDataService = HealthDataService();
                  
                  if (authService.currentUser?.id != null) {
                    try {
                      Get.snackbar(
                        'health_syncing'.tr,
                        'health_sync_msg'.tr,
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      
                      await healthDataService.saveHealthDataFromHealthKit(authService.currentUser!.id!);
                      await Future.delayed(const Duration(milliseconds: 1000));
                      await _loadHealthData();
                      
                      Get.snackbar(
                        'health_success'.tr,
                        'health_updated'.tr,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    } catch (e) {
                      Get.snackbar(
                        'health_error'.tr,
                        '${'health_error_sync'.tr}: $e',
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
                color: AppTheme.lightBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'common_period'.tr,
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDateFrom != null && _selectedDateTo != null
                              ? '${DateFormat('dd/MM/yyyy').format(_selectedDateFrom!)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateTo!)}'
                              : 'common_select_period'.tr,
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textSecondary),
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
    
    final values =
        _dailyData.map((d) => coerceMongoNumber(d['value'])).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Calcula tendência
    String trend = 'health_trend_stable'.tr;
    Color trendColor = Colors.grey;
    if (_dailyData.length >= 4) {
      final firstHalf = _dailyData.sublist(0, _dailyData.length ~/ 2);
      final secondHalf = _dailyData.sublist(_dailyData.length ~/ 2);
      final firstAvg = firstHalf
              .map((d) => coerceMongoNumber(d['value']))
              .reduce((a, b) => a + b) /
          firstHalf.length;
      final secondAvg = secondHalf
              .map((d) => coerceMongoNumber(d['value']))
              .reduce((a, b) => a + b) /
          secondHalf.length;
      
      if (secondAvg > firstAvg + 0.5) {
        trend = 'health_trend_increasing'.tr;
        trendColor = Colors.green;
      } else if (secondAvg < firstAvg - 0.5) {
        trend = 'health_trend_decreasing'.tr;
        trendColor = Colors.orange;
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
      decoration: AppTheme.surfaceListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'common_period_stats'.tr,
                style: AppTheme.titleSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('health_avg'.tr, '${stats['avg'].toStringAsFixed(1)}', 'health_unit_h'.tr,
                      AppTheme.secondaryBlue, Icons.trending_up),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('health_min'.tr, '${stats['min'].toStringAsFixed(1)}', 'health_unit_h'.tr,
                      AppTheme.success, Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('health_max'.tr, '${stats['max'].toStringAsFixed(1)}', 'health_unit_h'.tr,
                      AppTheme.error, Icons.keyboard_arrow_up),
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
                fontSize: 16,
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
    
    final sortedData = List<Map<String, dynamic>>.from(_dailyData)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'health_evolution'.tr,
                style: AppTheme.titleSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
                  horizontalInterval: 1,
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
                            value.toStringAsFixed(1),
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                      interval: 2,
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
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
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
                maxY: chartMaxYFromValues(
                  sortedData.map((d) => coerceMongoNumber(d['value'])),
                  minWhenEmptyOrZero: 10,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        coerceMongoNumber(entry.value['value']),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryBlue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          AppTheme.primaryBlue.withValues(alpha: 0.12),
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
    
    // Análise baseada em recomendações de sono (7-9 horas para adultos)
    if (avg >= 7 && avg <= 9) {
      analysis = 'Excelente! Você está dormindo dentro da faixa recomendada de 7-9 horas por noite.';
      analysisColor = Colors.green;
      analysisIcon = Icons.check_circle;
    } else if (avg >= 6 && avg < 7) {
      analysis = 'Bom, mas idealmente deveria dormir entre 7-9 horas. Tente melhorar sua rotina de sono.';
      analysisColor = Colors.lightGreen;
      analysisIcon = Icons.info;
    } else if (avg > 9) {
      analysis = 'Você está dormindo mais que o recomendado. Consulte um médico se isso persistir.';
      analysisColor = Colors.orange;
      analysisIcon = Icons.warning;
    } else if (avg >= 5 && avg < 6) {
      analysis = 'Pouco sono. A falta de sono pode afetar sua saúde. Tente dormir pelo menos 7 horas.';
      analysisColor = Colors.orange;
      analysisIcon = Icons.warning;
    } else {
      analysis = 'Muito pouco sono. Isso pode afetar seriamente sua saúde. Consulte um médico.';
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
                  'health_analysis'.tr,
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
                  'health_trend_label'.trParams({'trend': stats['trend']}),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'health_daily_records'.tr,
            style: AppTheme.titleSmall.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...List.generate(_dailyData.length, (index) {
          final data = _dailyData[index];
          final date = data['date'] as DateTime;
          final value = coerceMongoNumber(data['value']);
          final count = (data['count'] as num?)?.toInt() ?? 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceListCardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bedtime,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd/MM/yyyy', Get.find<SettingsController>().effectiveLocale.toString()).format(date),
                      style: AppTheme.titleSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tempo na cama',
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
                    '${value.toStringAsFixed(1)}h',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  if (count > 1)
                    Text(
                      'health_records_count'.trParams({'count': '$count'}),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'health_loading'.tr,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
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
            'common_error_load'.tr,
            style: AppTheme.titleSmall.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'common_unknown_error'.tr,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHealthData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text('common_try_again'.tr),
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
            Icons.bedtime,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'common_no_data'.tr,
            style: AppTheme.titleSmall.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'common_no_records_sleep'.tr,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

