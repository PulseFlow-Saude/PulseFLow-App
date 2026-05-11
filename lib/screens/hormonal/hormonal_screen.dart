import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'hormonal_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_health_record_form_widgets.dart';
import '../../widgets/pulse_side_menu.dart';

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd/$mm/$yyyy';
}

class HormonalScreen extends StatelessWidget {
  final String pacienteId;
  HormonalScreen({super.key, required this.pacienteId});

  final HormonalController controller = Get.put(HormonalController());
  final TextEditingController hormonioCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();
  final Rx<DateTime?> dataSel = Rx<DateTime?>(DateTime.now());
  final RxBool mostrarGrafico = false.obs;

  @override
  Widget build(BuildContext context) {
    controller.carregarRegistros(pacienteId);
    return PulseBlueScaffold(
      drawer: PulseSideMenu(activeItem: PulseNavItem.menu),
      header: PulseBlueCenteredTitleHeader(title: 'horm_title'.tr),
      body: Obx(() {
            return Column(
              children: [
                if (!mostrarGrafico.value) ...[
                  Expanded(
                    child: PulseHealthRecordMaxWidthAlign(
                      child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: PulseHealthRecordLayout.scrollPadding(context),
                      child: Card(
                        color: const Color(0xFFFFFFFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            PulseRecordSectionIntro(
                              icon: Icons.science_rounded,
                              title: 'horm_title'.tr,
                              subtitle: 'menu_hormonal_sub'.tr,
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PulseRecordFieldLabelRow(
                                  icon: Icons.biotech_rounded,
                                  label: 'horm_hormone_label'.tr,
                                ),
                                const SizedBox(height: 8),
                                Theme(
                                  data: PulseHealthRecordFormStyles.dropdownTheme(context),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DropdownMenu<String>(
                                      controller: hormonioCtrl,
                                      requestFocusOnTap: true,
                                      hintText: 'horm_select_hint'.tr,
                                      enableFilter: true,
                                      enableSearch: true,
                                      menuHeight: 300,
                                      expandedInsets: EdgeInsets.zero,
                                      dropdownMenuEntries: controller.hormoniosSugeridos
                                          .map((h) => DropdownMenuEntry<String>(value: h, label: h))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PulseRecordFieldLabelRow(
                                  icon: Icons.analytics_rounded,
                                  label: 'horm_value_label'.tr,
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: valorCtrl,
                                  decoration: PulseHealthRecordFormStyles.modernInputDecoration(
                                    hintText: 'horm_value_hint'.tr,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final placeholder = 'common_select_date'.tr;
                              final s = dataSel.value == null ? placeholder : _fmtDate(dataSel.value!);
                              return PulseRecordLabeledDateTile(
                                label: 'exam_date_label'.tr,
                                labelIcon: Icons.event_rounded,
                                isRequired: true,
                                placeholderText: placeholder,
                                displayText: s,
                                onTap: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dataSel.value ?? now,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: now,
                                  );
                                  if (picked != null) dataSel.value = DateTime(picked.year, picked.month, picked.day);
                                },
                              );
                            }),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                  onPressed: () async {
                                    if (dataSel.value == null) {
                                      Get.snackbar('common_data_required'.tr, 'horm_date_exam_msg'.tr);
                                      return;
                                    }
                                    final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
                                    if (valor == null) {
                                      Get.snackbar('horm_value_invalid'.tr, 'horm_value_invalid_msg'.tr);
                                      return;
                                    }
                                    await controller.adicionarRegistro(
                                      pacienteId: pacienteId,
                                      hormonio: hormonioCtrl.text.trim(),
                                      valor: valor,
                                      data: dataSel.value!,
                                    );
                                    hormonioCtrl.clear();
                                    valorCtrl.clear();
                                    dataSel.value = null;
                                    Get.snackbar('common_success'.tr, 'horm_saved'.tr);
                                  },
                                  child: Text('common_register'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryBlue, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                  onPressed: () => mostrarGrafico.value = !mostrarGrafico.value,
                                  child: Obx(() => Text(mostrarGrafico.value ? 'common_view_records'.tr : 'common_view_data'.tr, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16, fontWeight: FontWeight.w600))),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                ] else ...[
                  Expanded(
                    child: PulseHealthRecordMaxWidthAlign(
                      child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: PulseHealthRecordLayout.scrollPadding(context),
                      child: Column(children: [
                        _buildFilters(context),
                        const SizedBox(height: 12),
                        _HormonalChart(),
                        const SizedBox(height: 12),
                        // Placeholder simples: lista do mês
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.registrosFiltrados.length,
                          itemBuilder: (context, i) {
                            final r = controller.registrosFiltrados[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15))),
                              child: Row(children: [
                                Container(width: 50, height: 50, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(8)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${r.data.day}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('${r.data.month}'.padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 10))]))),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [const Icon(Icons.science, color: AppTheme.primaryBlue, size: 16), const SizedBox(width: 8), Flexible(child: Text('${r.hormonio}: ${r.valor.toStringAsFixed(2)}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16, fontWeight: FontWeight.w600)))]),
                                  const SizedBox(height: 6),
                                  Row(children: [const Icon(Icons.event, color: AppTheme.primaryBlue, size: 14), const SizedBox(width: 6), Text(_fmtDate(r.data), style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 14))]),
                                ])),
                              ]),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ],
            );
        }),
    );
  }
}

class _HormonalChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HormonalController>();
    final data = c.registrosFiltrados.where((r) => c.hormoniosSelecionados.isEmpty || c.hormoniosSelecionados.contains(r.hormonio)).toList();
    if (data.isEmpty) {
      return Card(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: SizedBox(
          height: 220,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.insights_outlined, size: 48, color: AppTheme.primaryBlue), const SizedBox(height: 8), Text('common_no_data_period'.tr, style: const TextStyle(color: AppTheme.primaryBlue))])),
        ),
      );
    }
    // Agrupa por dia e plota
    final sorted = data.toList()..sort((a, b) => a.data.compareTo(b.data));
    // Agrupa por hormonio => gera series
    final groups = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      groups.putIfAbsent(r.hormonio, () => []);
      groups[r.hormonio]!.add({'x': i.toDouble(), 'y': r.valor});
    }
    return Card(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white12, strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                  final d = sorted[i].data;
                  return SideTitleWidget(axisSide: meta.axisSide, space: 6, child: Text('${d.day}', style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10)));
                })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15), width: 1)),
              minX: 0,
              maxX: (sorted.length - 1).toDouble(),
              minY: (sorted.map((e) => e.valor).reduce((a, b) => a < b ? a : b) - 1).clamp(0, double.infinity),
              maxY: sorted.map((e) => e.valor).reduce((a, b) => a > b ? a : b) + 1,
              lineBarsData: groups.entries.map((entry) {
                final color = _seriesColor(entry.key);
                return LineChartBarData(
                  spots: entry.value.map((p) => FlSpot(p['x'] as double, p['y'] as double)).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true, getDotPainter: (spot, p, b, i) => FlDotCirclePainter(radius: 4, color: color, strokeWidth: 1.5, strokeColor: Colors.white)),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.25), color.withOpacity(0)], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

Color _seriesColor(String key) {
  // paleta simples baseada no hash do texto
  final colors = [
    AppTheme.primaryBlue,
    const Color(0xFF1E88E5),
    const Color(0xFF43A047),
    const Color(0xFFF4511E),
    const Color(0xFF8E24AA),
    const Color(0xFF00897B),
  ];
  final h = key.hashCode;
  return colors[h.abs() % colors.length];
}

class _HormonalSelectionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HormonalController>();
    return Obx(() {
      final disponiveis = c.hormoniosDisponiveis;
      if (disponiveis.isEmpty) return const SizedBox.shrink();
      return Card(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('horm_in_chart'.tr, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: disponiveis.map((h) {
                final selected = c.hormoniosSelecionados.contains(h);
                return FilterChip(
                  label: Text(h),
                  selected: selected,
                  onSelected: (v) {
                    if (v) {
                      if (!c.hormoniosSelecionados.contains(h)) c.hormoniosSelecionados.add(h);
                    } else {
                      c.hormoniosSelecionados.remove(h);
                    }
                  },
                  selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
                  checkmarkColor: AppTheme.primaryBlue,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              TextButton(onPressed: () { c.hormoniosSelecionados.assignAll(disponiveis); c.applyFilters(); }, child: Text('horm_select_all'.tr)),
              const SizedBox(width: 8),
              TextButton(onPressed: () { c.hormoniosSelecionados.clear(); c.applyFilters(); }, child: Text('horm_clear_selection'.tr)),
            ])
          ]),
        ),
      );
    });
  }
}

Widget _buildFilters(BuildContext context) {
  final c = Get.find<HormonalController>();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(children: [
      Row(children: [
        Expanded(
          child: DropdownMenu<String>(
            label: Text('horm_search'.tr),
            enableFilter: true,
            enableSearch: true,
            hintText: 'horm_filter_hint'.tr,
            onSelected: (v) => c.filtroHormonio.value = (v ?? '').trim(),
            dropdownMenuEntries: c.hormoniosDisponiveis
                .map((h) => DropdownMenuEntry<String>(value: h, label: h))
                .toList(),
          ),
        ),
        IconButton(
          tooltip: 'common_clear'.tr,
          onPressed: () {
            c.filtroHormonio.value = '';
            c.filtroInicio.value = null;
            c.filtroFim.value = null;
            // Seleciona todos para gráfico também
            c.hormoniosSelecionados.assignAll(c.hormoniosDisponiveis);
          },
          icon: const Icon(Icons.clear_all),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, initialDate: c.filtroInicio.value ?? now, firstDate: DateTime(now.year - 5), lastDate: now);
              if (picked != null) c.filtroInicio.value = picked;
            },
            icon: const Icon(Icons.date_range),
            label: Obx(() => Text(c.filtroInicio.value == null ? 'horm_date_start'.tr : _fmtDate(c.filtroInicio.value!))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, initialDate: c.filtroFim.value ?? now, firstDate: DateTime(now.year - 5), lastDate: now);
              if (picked != null) c.filtroFim.value = picked;
            },
            icon: const Icon(Icons.event),
            label: Obx(() => Text(c.filtroFim.value == null ? 'horm_date_end'.tr : _fmtDate(c.filtroFim.value!))),
          ),
        ),
      ]),
    ]),
  );
}


