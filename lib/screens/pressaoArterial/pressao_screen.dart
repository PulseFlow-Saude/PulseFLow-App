import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../diabetes/diabetes_screen.dart' show formatarData, formatarMes, formatarMesAno; // reuse helpers
import 'pressao_controller.dart';
import '../../models/pressao_arterial.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class PressaoScreen extends StatelessWidget {
  final String pacienteId;
  final PressaoController controller = Get.put(PressaoController());

  PressaoScreen({super.key, required this.pacienteId});

  final TextEditingController pressaoController = TextEditingController();
  final Rx<DateTime?> dataSelecionada = Rx<DateTime?>(DateTime.now());
  final RxBool mostrarGrafico = false.obs;

  @override
  Widget build(BuildContext context) {
    controller.carregarRegistros(pacienteId);

    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        elevation: 0,
        title: const Text('Registro de Pressão', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: const PulseDrawerButton(iconSize: 22),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Novo registro', style: TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: pressaoController,
                              decoration: const InputDecoration(labelText: 'Pressão (mmHg)', hintText: 'Ex: 120/80'),
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final dataText = dataSelecionada.value == null ? 'Selecione a data' : formatarData(dataSelecionada.value!);
                              return InkWell(
                                onTap: () async {
                                  final hoje = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dataSelecionada.value ?? hoje,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(hoje.year, hoje.month, hoje.day),
                                    helpText: 'Selecione a data da medição',
                                    cancelText: 'Cancelar',
                                    confirmText: 'Confirmar',
                                  );
                                  if (picked != null) {
                                    dataSelecionada.value = DateTime(picked.year, picked.month, picked.day);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.2))),
                                  child: Row(children: [const Icon(Icons.event, color: Color(0xFF00324A)), const SizedBox(width: 12), Expanded(child: Text(dataText, style: const TextStyle(color: Color(0xFF00324A))))]),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: () async {
                                      if (dataSelecionada.value == null) {
                                        Get.snackbar('Data obrigatória', 'Selecione a data da medição');
                                        return;
                                      }
                                      final raw = pressaoController.text.trim();
                                      final match = RegExp(r'^(\d{2,3})\s*/\s*(\d{2,3})$').firstMatch(raw);
                                      if (match == null) {
                                        Get.snackbar('Formato inválido', 'Use o formato 120/80');
                                        return;
                                      }
                                      final sis = double.tryParse(match.group(1)!);
                                      final dia = double.tryParse(match.group(2)!);
                                      if (sis == null || dia == null) {
                                        Get.snackbar('Valores inválidos', 'Digite uma pressão válida, ex: 120/80');
                                        return;
                                      }
                                      await controller.adicionarRegistro(
                                        pacienteId: pacienteId,
                                        sistolica: sis,
                                        diastolica: dia,
                                        data: dataSelecionada.value!,
                                      );
                                      pressaoController.clear();
                                      dataSelecionada.value = null;
                                      Get.snackbar('Sucesso', 'Registro de pressão salvo com sucesso');
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
                              ],
                            ),
                            const SizedBox(height: 24),
                            // sem lista de dados na tela de cadastro
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _GraficoPressao(
                          registros: controller.registrosFiltrados,
                          mesSelecionado: controller.mesSelecionado.value,
                          onPrevMonth: () {
                            final d = controller.mesSelecionado.value;
                            controller.mesSelecionado.value = DateTime(d.year, d.month - 1);
                          },
                          onNextMonth: () {
                            final d = controller.mesSelecionado.value;
                            controller.mesSelecionado.value = DateTime(d.year, d.month + 1);
                          },
                          onClose: () => mostrarGrafico.value = false,
                        ),
                        const SizedBox(height: 24),
                        _PressaoAnalysisSection(registros: controller.registrosFiltrados),
                        const SizedBox(height: 12),
                        // lista de registros com classificação
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.registrosFiltrados.length,
                          itemBuilder: (context, index) {
                            final item = controller.registrosFiltrados[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15))),
                              child: Row(children: [
                                Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF00324A), borderRadius: BorderRadius.circular(8)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${item.data.day}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(formatarMes(item.data.month), style: const TextStyle(color: Colors.white, fontSize: 10))]))),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [const Icon(Icons.favorite, color: Color(0xFF00324A), size: 16), const SizedBox(width: 8), Flexible(child: Text('${item.sistolica.toStringAsFixed(0)}/${item.diastolica.toStringAsFixed(0)} mmHg', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600)))]),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 8, runSpacing: 6, children: _buildChips(item)),
                                ])),
                              ]),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              const url = 'https://www.msdmanuals.com/pt/profissional/multimedia/table/classifica%C3%A7%C3%A3o-da-press%C3%A3o-arterial-em-adultos';
                              final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
                              if (!ok) {
                                await launchUrlString(url);
                              }
                            },
                            child: const Text(
                              'Referência: Classificação da pressão arterial em adultos (MSD)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF00324A), decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  List<Widget> _buildChips(PressaoArterial p) {
    final status = _classificarPressao(p.sistolica, p.diastolica);
    final Color bg;
    final Color fg;
    switch (status) {
      case 'Normal':
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade700;
        break;
      case 'Elevada':
      case 'HA Estágio 1':
        bg = Colors.amber.withOpacity(0.2);
        fg = Colors.amber.shade800;
        break;
      case 'HA Estágio 2':
      case 'Crise hipertensiva':
        bg = Colors.red.withOpacity(0.15);
        fg = Colors.red.shade700;
        break;
      default:
        bg = const Color(0xFF00324A).withOpacity(0.10);
        fg = const Color(0xFF00324A);
    }
    return [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Text(status, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600))),
    ];
  }

  String _classificarPressao(double sis, double dia) {
    // Classificação conforme MSD Manuals (ACC/AHA 2017)
    // Referência: https://www.msdmanuals.com/pt/profissional/multimedia/table/classifica%C3%A7%C3%A3o-da-press%C3%A3o-arterial-em-adultos
    if (sis < 120 && dia < 80) return 'Normal';
    if (sis >= 120 && sis <= 129 && dia < 80) return 'Elevada';
    if ((sis >= 130 && sis <= 139) || (dia >= 80 && dia <= 89)) return 'Hipertensão estágio 1';
    if (sis >= 140 || dia >= 90) return 'Hipertensão estágio 2';
    return 'Indefinido';
  }
}

class _GraficoPressao extends StatelessWidget {
  final List<PressaoArterial> registros;
  final DateTime mesSelecionado;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onClose;
  const _GraficoPressao({Key? key, required this.registros, required this.mesSelecionado, required this.onPrevMonth, required this.onNextMonth, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = registros.toList()..sort((a, b) => a.data.compareTo(b.data));
    final mes = formatarMesAno(mesSelecionado);

    return Card(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Registro de Pressão Arterial', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: Color(0xFF00324A), fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(mes, style: const TextStyle(color: Color(0xFF00324A), fontSize: 14))])), IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Color(0xFF00324A), size: 20))]),
          const SizedBox(height: 20),
          if (data.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: const [
                  Icon(Icons.insights_outlined, size: 48, color: Color(0xFF00324A)),
                  SizedBox(height: 8),
                  Text('Sem dados neste mês', style: TextStyle(color: Color(0xFF00324A), fontSize: 14)),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 320,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, drawHorizontalLine: true, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white12, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final d = data[i].data;
                        return SideTitleWidget(axisSide: meta.axisSide, space: 6, child: Text('${d.day}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)));
                      }, interval: (data.length / 6).clamp(1, 6).toDouble())),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)), interval: 10)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15), width: 1)),
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 40,
                    maxY: 200,
                    lineBarsData: [
                      LineChartBarData(
                        // Um único ponto por registro (Pressão Média Arterial ≈ DIA + 1/3*(SIS-DIA))
                        spots: data.asMap().entries.map((e) {
                          final p = e.value;
                          final map = p.diastolica + (p.sistolica - p.diastolica) / 3.0;
                          return FlSpot(e.key.toDouble(), map);
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF00324A),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true, getDotPainter: (spot, p, b, i) => FlDotCirclePainter(radius: 4, color: const Color(0xFF00324A), strokeWidth: 1.5, strokeColor: Colors.white)),
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF00324A).withOpacity(0.25), const Color(0xFF00324A).withOpacity(0)], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                      ),
                    ],
                    lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (s) => const Color(0xFF00324A)), handleBuiltInTouches: true),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ElevatedButton.icon(onPressed: onPrevMonth, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), icon: const Icon(Icons.chevron_left, color: Colors.white, size: 16), label: const Text('Anterior', style: TextStyle(color: Colors.white, fontSize: 12))),
            ElevatedButton.icon(onPressed: onNextMonth, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), icon: const Icon(Icons.chevron_right, color: Colors.white, size: 16), label: const Text('Próximo', style: TextStyle(color: Colors.white, fontSize: 12))),
          ]),
        ]),
      ),
    );
  }
}

class _PressaoAnalysisSection extends StatelessWidget {
  final List<PressaoArterial> registros;
  const _PressaoAnalysisSection({Key? key, required this.registros}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = registros.toList()..sort((a, b) => a.data.compareTo(b.data));
    String mediaPair() {
      if (data.isEmpty) return '0/0';
      final mSis = data.map((e) => e.sistolica).reduce((a, b) => a + b) / data.length;
      final mDia = data.map((e) => e.diastolica).reduce((a, b) => a + b) / data.length;
      return '${mSis.toStringAsFixed(0)}/${mDia.toStringAsFixed(0)}';
    }
    String menorPair() {
      if (data.isEmpty) return '0/0';
      final minSis = data.map((e) => e.sistolica).reduce((a, b) => a < b ? a : b);
      final minDia = data.map((e) => e.diastolica).reduce((a, b) => a < b ? a : b);
      return '${minSis.toStringAsFixed(0)}/${minDia.toStringAsFixed(0)}';
    }
    String maiorPair() {
      if (data.isEmpty) return '0/0';
      final maxSis = data.map((e) => e.sistolica).reduce((a, b) => a > b ? a : b);
      final maxDia = data.map((e) => e.diastolica).reduce((a, b) => a > b ? a : b);
      return '${maxSis.toStringAsFixed(0)}/${maxDia.toStringAsFixed(0)}';
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15))),
        child: Row(children: [
          Expanded(child: Column(children: [const Text('Menor', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(menorPair(), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))]))
          ,
          Expanded(child: Column(children: [const Text('Média', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(mediaPair(), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))]))
          ,
          Expanded(child: Column(children: [const Text('Maior', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(maiorPair(), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))]))
        ]),
      ),
    ]);
  }
}


