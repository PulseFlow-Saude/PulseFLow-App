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
import '../../models/pressao_arterial.dart';

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
  List<Map<String, dynamic>> _dailyBpData = [];
  /// `heart` = batimentos; `pressure` = pressão arterial (mesmo padrão de abas que oxigenação/respiração).
  String _selectedHeartTab = 'heart';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapOldestPatientRangeThenLoad('batimentos');
    });
  }

  Future<void> _bootstrapOldestPatientRangeThenLoad(String collection) async {
    final user = _authService.currentUser;
    _selectedDateTo = metricChartDefaultEndDay();
    if (user?.id == null) {
      _selectedDateFrom = metricChartDefaultWideStartDay();
    } else {
      DateTime? oldest;
      final bounds = await _db.getPatientMetricDateBounds(collection, user!.id!);
      if (bounds.min != null) {
        oldest = DateTime(bounds.min!.year, bounds.min!.month, bounds.min!.day);
      }
      try {
        final pressoes = await _db.getPressoesByPacienteId(user.id!);
        for (final p in pressoes) {
          final d = DateTime(p.data.year, p.data.month, p.data.day);
          if (oldest == null || d.isBefore(oldest)) oldest = d;
        }
      } catch (_) {}
      _selectedDateFrom = oldest ?? _selectedDateTo;
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

      // Busca dados diretamente da coleção 'batimentos'
      final allData = await _db.fetchPatientMetricDocuments(
        'batimentos',
        currentUser!.id!,
      );

      // Filtra por período (dias civis inclusivos)
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

      print('📊 [HeartRateHistory] Total de registros encontrados: ${filteredData.length}');

      // Agrupa por dia e calcula média diária
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

      // Cria lista de médias diárias
      _dailyData = dailyValues.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final values = entry.value;
        final average = values.reduce((a, b) => a + b) / values.length;
        
        return {
          'date': date,
          'value': average.toDouble(),
          'count': values.length,
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
        };
      }).toList();

      // Ordena por data (mais recente primeiro)
      _dailyData.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      final rangeStart = DateTime(
        _selectedDateFrom!.year,
        _selectedDateFrom!.month,
        _selectedDateFrom!.day,
      );
      final rangeEnd = DateTime(
        _selectedDateTo!.year,
        _selectedDateTo!.month,
        _selectedDateTo!.day,
      );

      _dailyBpData = [];
      try {
        final list = await _db.getPressoesByPacienteId(currentUser!.id!);
        final filteredBp = list.where((p) {
          final d = DateTime(p.data.year, p.data.month, p.data.day);
          return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
        }).toList();

        final byDay = <String, List<PressaoArterial>>{};
        for (final p in filteredBp) {
          final key = DateFormat('yyyy-MM-dd').format(
            DateTime(p.data.year, p.data.month, p.data.day),
          );
          byDay.putIfAbsent(key, () => []).add(p);
        }

        _dailyBpData = byDay.entries.map((e) {
          final date = DateTime.parse(e.key);
          final regs = e.value;
          final avgSys = regs.map((r) => r.sistolica).reduce((a, b) => a + b) /
              regs.length;
          final avgDia =
              regs.map((r) => r.diastolica).reduce((a, b) => a + b) /
                  regs.length;
          return {
            'date': date,
            'sistolica': avgSys,
            'diastolica': avgDia,
            'count': regs.length,
          };
        }).toList();

        _dailyBpData.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );
      } catch (_) {}

      setState(() {
        _isLoading = false;
        if (_dailyData.isEmpty && _dailyBpData.isNotEmpty) {
          _selectedHeartTab = 'pressure';
        } else if (_dailyBpData.isEmpty && _dailyData.isNotEmpty) {
          _selectedHeartTab = 'heart';
        }
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
                            : _dailyData.isEmpty && _dailyBpData.isEmpty
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
                  'hist_heart_rate'.tr,
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
    final stats = _calculateStats();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _heartTabChip('heart', 'health_heart_rate'.tr),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _heartTabChip('pressure', 'menu_pressao'.tr),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        if (_selectedHeartTab == 'heart') ...[
          if (_dailyData.isNotEmpty) ...[
            _buildStats(stats),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            if (stats != null) ...[
              _buildAnalysis(stats),
              const SizedBox(height: 16),
            ],
            _buildDataList(),
          ] else
            _buildNoMetricHint(
              'common_no_records_heart'.tr,
              Icons.favorite_border_rounded,
            ),
        ] else ...[
          if (_dailyBpData.isNotEmpty) ...[
            _buildBloodPressureChart(),
            const SizedBox(height: 16),
            _buildBloodPressureList(),
          ] else
            _buildNoMetricHint(
              'common_no_records_pressure'.tr,
              Icons.monitor_heart_outlined,
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _heartTabChip(String tab, String label) {
    final selected = _selectedHeartTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedHeartTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoMetricHint(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.surfaceListCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: AppTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    final sorted = List<Map<String, dynamic>>.from(_dailyBpData)
      ..sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );
    if (sorted.isEmpty) return const SizedBox.shrink();

    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i]['sistolica'] as double;
      final d = sorted[i]['diastolica'] as double;
      sysSpots.add(FlSpot(i.toDouble(), s));
      diaSpots.add(FlSpot(i.toDouble(), d));
    }

    final allY = <double>[
      ...sorted.map((e) => e['sistolica'] as double),
      ...sorted.map((e) => e['diastolica'] as double),
    ];
    final maxY = chartMaxYFromValues(allY, minWhenEmptyOrZero: 140);

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
              Expanded(
                child: Text(
                  'press_chart_title'.tr,
                  style: AppTheme.titleSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _bpLegendDot(Colors.red.shade700, 'health_bp_systolic'.tr),
              const SizedBox(width: 16),
              _bpLegendDot(AppTheme.primaryBlue, 'health_bp_diastolic'.tr),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval:
                          (sorted.length / 4).clamp(1, sorted.length).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        final dt = sorted[i]['date'] as DateTime;
                        return Text(
                          '${dt.day}/${dt.month}',
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: sorted.length <= 1 ? 1 : (sorted.length - 1).toDouble(),
                minY: 40,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: sysSpots,
                    isCurved: true,
                    color: Colors.red.shade700,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: diaSpots,
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bpLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodPressureList() {
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
        ...List.generate(_dailyBpData.length, (index) {
          final data = _dailyBpData[index];
          final date = data['date'] as DateTime;
          final s = data['sistolica'] as double;
          final di = data['diastolica'] as double;
          final count = data['count'] as int;

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
                    Icons.monitor_heart_outlined,
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
                        DateFormat(
                          'EEEE, dd/MM/yyyy',
                          Get.find<SettingsController>()
                              .effectiveLocale
                              .toString(),
                        ).format(date),
                        style: AppTheme.titleSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'health_daily_avg'.tr,
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
                      '${s.round()}/${di.round()} mmHg',
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

  Map<String, dynamic>? _calculateStats() {
    if (_dailyData.isEmpty) return null;
    
    final values =
        _dailyData.map((d) => coerceMongoNumber(d['value'])).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Calcula tendência (comparando primeira metade com segunda metade)
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
      
      if (secondAvg > firstAvg + 5) {
        trend = 'health_trend_increasing'.tr;
        trendColor = Colors.orange;
      } else if (secondAvg < firstAvg - 5) {
        trend = 'health_trend_decreasing'.tr;
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
                  child: _buildStatCard('health_avg'.tr, '${stats['avg'].round()}', 'bpm',
                      AppTheme.secondaryBlue, Icons.trending_up),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('health_min'.tr, '${stats['min'].round()}', 'bpm',
                      AppTheme.success, Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('health_max'.tr, '${stats['max'].round()}', 'bpm',
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
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
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
                maxX: sortedData.length <= 1
                    ? 1
                    : (sortedData.length - 1).toDouble(),
                minY: 0,
                maxY: chartMaxYFromValues(
                  sortedData.map((d) => coerceMongoNumber(d['value'])),
                  minWhenEmptyOrZero: 120,
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
    
    // Análise baseada em valores normais de frequência cardíaca em repouso
    if (avg < 60) {
      analysis = 'health_analysis_brady'.tr;
      analysisColor = Colors.blue;
      analysisIcon = Icons.warning;
    } else if (avg >= 60 && avg <= 100) {
      analysis = 'health_analysis_normal'.tr;
      analysisColor = Colors.green;
      analysisIcon = Icons.check_circle;
    } else if (avg > 100 && avg <= 120) {
      analysis = 'health_analysis_elevated'.tr;
      analysisColor = Colors.orange;
      analysisIcon = Icons.warning;
    } else {
      analysis = 'health_analysis_tachy'.tr;
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
          final min = coerceMongoNumber(data['min']);
          final max = coerceMongoNumber(data['max']);
          
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
                  Icons.favorite,
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
                      'health_daily_min_max'.trParams({'min': '${min.round()}', 'max': '${max.round()}'}),
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
            Icons.favorite,
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
            'heart_history_empty_sub'.tr,
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

