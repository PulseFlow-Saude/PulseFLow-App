import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/health_data_service.dart';
import '../../theme/app_theme.dart';
import '../institutional/settings_controller.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../../widgets/pulse_bottom_navigation.dart';

class OxygenRespiratoryHistoryScreen extends StatefulWidget {
  const OxygenRespiratoryHistoryScreen({super.key});

  @override
  State<OxygenRespiratoryHistoryScreen> createState() =>
      _OxygenRespiratoryHistoryScreenState();
}

class _OxygenRespiratoryHistoryScreenState
    extends State<OxygenRespiratoryHistoryScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _db = Get.find<DatabaseService>();
  final HealthDataService _healthDataService = HealthDataService();

  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String _selectedMetric = 'oxygen';
  List<Map<String, dynamic>> _dailyData = [];

  @override
  void initState() {
    super.initState();
    _selectedDateTo = DateTime.now();
    _selectedDateFrom = DateTime.now().subtract(const Duration(days: 30));
    _loadHealthData();
  }

  String get _collectionName =>
      _selectedMetric == 'oxygen' ? 'oxigenacao' : 'respiracao';

  String get _metricTitle =>
      _selectedMetric == 'oxygen' ? 'Oxigenação' : 'Respiração';

  String get _metricUnit => _selectedMetric == 'oxygen' ? '%' : 'irpm';

  IconData get _metricIcon =>
      _selectedMetric == 'oxygen' ? Icons.air_rounded : Icons.monitor_heart;

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) throw 'common_user_not_auth'.tr;
      if (_selectedDateFrom == null || _selectedDateTo == null) {
        throw 'common_select_period'.tr;
      }

      final collection = await _db.getCollection(_collectionName);
      final allData = await collection.find({'pacienteId': currentUser!.id!}).toList();

      final filteredData = allData.where((item) {
        if (item['data'] == null) return false;
        final itemDate = item['data'] is DateTime
            ? item['data'] as DateTime
            : DateTime.parse(item['data'].toString());
        return itemDate.isAfter(_selectedDateFrom!.subtract(const Duration(days: 1))) &&
            itemDate.isBefore(_selectedDateTo!.add(const Duration(days: 1)));
      }).toList();

      final Map<String, List<double>> dailyValues = {};
      for (final item in filteredData) {
        if (item['valor'] == null) continue;
        final itemDate = item['data'] is DateTime
            ? item['data'] as DateTime
            : DateTime.parse(item['data'].toString());
        final dateKey = DateFormat('yyyy-MM-dd').format(itemDate);
        final value = (item['valor'] as num).toDouble();
        dailyValues.putIfAbsent(dateKey, () => []).add(value);
      }

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

      _dailyData
          .sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      setState(() => _isLoading = false);
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
      locale: Get.find<SettingsController>().effectiveLocale,
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
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Text(_error!)
                            : _dailyData.isEmpty
                                ? _buildEmptyState()
                                : _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      child: Row(
        children: [
          const PulseDrawerButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Oxigenação e Respiração',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () async {
              final userId = _authService.currentUser?.id;
              if (userId == null) return;
              await _healthDataService.saveHealthDataFromHealthKit(userId);
              await Future.delayed(const Duration(milliseconds: 700));
              await _loadHealthData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stats = _calculateStats();
    return Column(
      children: [
        // Seletor de métrica (mesmo padrão de bloco do conteúdo)
        Row(
          children: [
            Expanded(child: _metricChip('oxygen', 'Oxigenação')),
            const SizedBox(width: 8),
            Expanded(child: _metricChip('respiration', 'Respiração')),
          ],
        ),
        const SizedBox(height: 12),
        // Seletor de período
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${DateFormat('dd/MM/yyyy').format(_selectedDateFrom!)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateTo!)}',
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStats(stats),
        const SizedBox(height: 16),
        _buildChart(),
        const SizedBox(height: 16),
        _buildDataList(),
      ],
    );
  }

  Widget _metricChip(String metric, String label) {
    final selected = _selectedMetric == metric;
    return InkWell(
      onTap: () async {
        setState(() => _selectedMetric = metric);
        await _loadHealthData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final values = _dailyData.map((d) => d['value'] as double).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    return {
      'avg': avg,
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }

  Widget _buildStats(Map<String, dynamic> stats) {
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
                'Estatísticas do período',
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
                Expanded(child: _stat('Média', stats['avg'] as double, AppTheme.secondaryBlue, Icons.trending_up)),
                const SizedBox(width: 12),
                Expanded(child: _stat('Mín', stats['min'] as double, AppTheme.success, Icons.keyboard_arrow_down)),
                const SizedBox(width: 12),
                Expanded(child: _stat('Máx', stats['max'] as double, AppTheme.error, Icons.keyboard_arrow_up)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color, IconData icon) {
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(_selectedMetric == 'oxygen' ? 1 : 0)} $_metricUnit',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final sorted = List<Map<String, dynamic>>.from(_dailyData)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final maxY = sorted
            .map((d) => d['value'] as double)
            .reduce((a, b) => a > b ? a : b) *
        1.2;
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
                'Evolução',
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
                minX: 0,
                maxX: (sorted.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    spots: sorted.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['value'] as double);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return Column(
      children: _dailyData.map((data) {
        final date = data['date'] as DateTime;
        final value = data['value'] as double;
        final min = data['min'] as double;
        final max = data['max'] as double;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.surfaceListCardDecoration(),
          child: Row(
            children: [
              Icon(_metricIcon, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
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
                      'Mín ${min.toStringAsFixed(1)} | Máx ${max.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(_selectedMetric == 'oxygen' ? 1 : 0)} $_metricUnit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(
              _metricIcon,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado de $_metricTitle no período selecionado.',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
