import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../login/paciente_controller.dart';
import 'hormonal_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

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
  final LayerLink _link = LayerLink();
  final RxBool _showSuggestions = false.obs;

  @override
  Widget build(BuildContext context) {
    controller.carregarRegistros(pacienteId);
    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        elevation: 0,
        title: const Text('Registro Hormonal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: const PulseDrawerButton(iconSize: 22),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            return Column(
              children: [
                if (!mostrarGrafico.value) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Card(
                        color: const Color(0xFFFFFFFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Novo registro', style: TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownMenu<String>(
                                controller: hormonioCtrl,
                                requestFocusOnTap: true,
                                label: const Text('Hormônio'),
                                hintText: 'Selecione ou digite',
                                enableFilter: true,
                                enableSearch: true,
                                menuHeight: 300,
                                dropdownMenuEntries: controller.hormoniosSugeridos
                                    .map((h) => DropdownMenuEntry<String>(value: h, label: h))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: valorCtrl,
                              decoration: const InputDecoration(labelText: 'Valor', hintText: 'Ex: 2.3'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final s = dataSel.value == null ? 'Selecione a data' : _fmtDate(dataSel.value!);
                              return InkWell(
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.2))),
                                  child: Row(children: [const Icon(Icons.event, color: Color(0xFF00324A)), const SizedBox(width: 12), Expanded(child: Text(s, style: const TextStyle(color: Color(0xFF00324A))))]),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                  onPressed: () async {
                                    if (dataSel.value == null) {
                                      Get.snackbar('Data obrigatória', 'Selecione a data do exame');
                                      return;
                                    }
                                    final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
                                    if (valor == null) {
                                      Get.snackbar('Valor inválido', 'Digite um número válido');
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
                                    Get.snackbar('Sucesso', 'Registro hormonal salvo');
                                  },
                                  child: const Text('Registrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00324A), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                  onPressed: () => mostrarGrafico.value = !mostrarGrafico.value,
                                  child: Obx(() => Text(mostrarGrafico.value ? 'Visualizar registros' : 'Visualizar dados', style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600))),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
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
                              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15))),
                              child: Row(children: [
                                Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF00324A), borderRadius: BorderRadius.circular(8)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${r.data.day}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('${r.data.month}'.padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 10))]))),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [const Icon(Icons.science, color: Color(0xFF00324A), size: 16), const SizedBox(width: 8), Flexible(child: Text('${r.hormonio}: ${r.valor.toStringAsFixed(2)}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600)))]),
                                  const SizedBox(height: 6),
                                  Row(children: [const Icon(Icons.event, color: Color(0xFF00324A), size: 14), const SizedBox(width: 6), Text(_fmtDate(r.data), style: const TextStyle(color: Color(0xFF00324A), fontSize: 14))]),
                                ])),
                              ]),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
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
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.insights_outlined, size: 48, color: Color(0xFF00324A)), SizedBox(height: 8), Text('Sem dados neste período', style: TextStyle(color: Color(0xFF00324A)))])),
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
                  return SideTitleWidget(axisSide: meta.axisSide, space: 6, child: Text('${d.day}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)));
                })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15), width: 1)),
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
    const Color(0xFF00324A),
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
            const Text('Hormonios no gráfico', style: TextStyle(color: Color(0xFF00324A), fontWeight: FontWeight.w600)),
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
                  selectedColor: const Color(0xFF00324A).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF00324A),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              TextButton(onPressed: () { c.hormoniosSelecionados.assignAll(disponiveis); c.applyFilters(); }, child: const Text('Selecionar todos')),
              const SizedBox(width: 8),
              TextButton(onPressed: () { c.hormoniosSelecionados.clear(); c.applyFilters(); }, child: const Text('Limpar seleção')),
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
            label: const Text('Pesquisar hormônio'),
            enableFilter: true,
            enableSearch: true,
            hintText: 'Digite ou selecione',
            onSelected: (v) => c.filtroHormonio.value = (v ?? '').trim(),
            dropdownMenuEntries: c.hormoniosDisponiveis
                .map((h) => DropdownMenuEntry<String>(value: h, label: h))
                .toList(),
          ),
        ),
        IconButton(
          tooltip: 'Limpar',
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
            label: Obx(() => Text(c.filtroInicio.value == null ? 'Data início' : _fmtDate(c.filtroInicio.value!))),
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
            label: Obx(() => Text(c.filtroFim.value == null ? 'Data fim' : _fmtDate(c.filtroFim.value!))),
          ),
        ),
      ]),
    ]),
  );
}


