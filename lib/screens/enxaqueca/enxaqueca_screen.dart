import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:url_launcher/url_launcher_string.dart';
import 'enxaqueca_controller.dart';
import '../../models/enxaqueca.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

String formatarData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return "$dd/$mm/$yyyy";
}

String formatarMesAno(DateTime d) {
  const meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  return '${meses[d.month - 1]} de ${d.year}';
}

String formatarMes(int mes) {
  const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
  return meses[mes - 1];
}

String calcularMediaIntensidade(List<Enxaqueca> data) {
  if (data.isEmpty) return '0';
  final soma = data.fold<int>(0, (sum, item) => sum + (int.tryParse(item.intensidade) ?? 0));
  return (soma / data.length).toStringAsFixed(1);
}

String calcularMaiorIntensidade(List<Enxaqueca> data) {
  if (data.isEmpty) return '0';
  final valores = data.map((e) => int.tryParse(e.intensidade) ?? 0).toList();
  final maior = valores.reduce((a, b) => a > b ? a : b);
  return maior.toString();
}

String calcularMenorIntensidade(List<Enxaqueca> data) {
  if (data.isEmpty) return '0';
  final valores = data.map((e) => int.tryParse(e.intensidade) ?? 0).toList();
  final menor = valores.reduce((a, b) => a < b ? a : b);
  return menor.toString();
}

double calcularFatorIntensidade(String intensidade) {
  final valor = int.tryParse(intensidade) ?? 0;
  return valor / 10.0;
}

Color getCorIntensidade(String intensidade) {
  final valor = int.tryParse(intensidade) ?? 0;
  if (valor <= 3) {
    return Colors.green;
  }
  if (valor <= 6) {
    return Colors.orange;
  }
  return Colors.red;
}

String classificarIntensidade(String intensidade) {
  final valor = int.tryParse(intensidade) ?? 0;
  if (valor <= 0) return 'Sem dor';
  if (valor <= 2) return 'Leve';
  if (valor <= 4) return 'Desconforto';
  if (valor <= 6) return 'Moderada';
  if (valor <= 8) return 'Intensa';
  if (valor == 9) return 'Muito intensa';
  return 'Pior dor'; // 10
}

String classificarDuracaoHoras(int horas) {
  if (horas <= 0) return 'Sem duração';
  if (horas <= 1) return 'Curta';
  if (horas <= 3) return 'Moderada';
  return 'Prolongada';
}

class EnxaquecaScreen extends StatelessWidget {
  final String pacienteId;
  final EnxaquecaController controller = Get.put(EnxaquecaController());

  EnxaquecaScreen({super.key, required this.pacienteId});

  final TextEditingController intensidadeController = TextEditingController();
  final TextEditingController duracaoController = TextEditingController();
  final Rx<DateTime?> dataSelecionada = Rx<DateTime?>(DateTime.now());
  final RxBool mostrarGrafico = false.obs; // Reverting to false
  final RxInt intensidadeSelecionada = 0.obs;

  @override
  Widget build(BuildContext context) {
    controller.carregarRegistros(pacienteId);

    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        elevation: 0,
        title: const Text("Registro de Enxaqueca", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          // debug: EnxaquecaScreen building with mostrarGrafico.value
          return Column(
            children: [
              if (!mostrarGrafico.value) ...[
                // debug: rendering registration and list view
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
                        const Text(
                          "Novo registro",
                              style: TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        // Intensidade em uma linha (100% largura)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Intensidade da Dor',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00324A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final valor = intensidadeSelecionada.value;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: getCorIntensidade(valor.toString()),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${classificarIntensidade(valor.toString())} ($valor/10)',
                                            style: TextStyle(
                                              color: getCorIntensidade(valor.toString()),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: getCorIntensidade(valor.toString()),
                                        inactiveTrackColor: getCorIntensidade(valor.toString()).withOpacity(0.3),
                                        thumbColor: getCorIntensidade(valor.toString()),
                                        overlayColor: getCorIntensidade(valor.toString()).withOpacity(0.2),
                                        trackHeight: 6,
                                      ),
                                      child: Slider(
                                        value: valor.toDouble(),
                                        min: 0,
                                        max: 10,
                                        divisions: 10,
                                        onChanged: (v) => intensidadeSelecionada.value = v.round(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Duração (100% largura)
                        TextField(
                          controller: duracaoController,
                          decoration: const InputDecoration(
                            labelText: "Duração (horas)",
                            hintText: "Ex: 2",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final dataText = dataSelecionada.value == null
                              ? 'Selecione a data'
                              : formatarData(dataSelecionada.value!);
                          return InkWell(
                            onTap: () async {
                              final hoje = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dataSelecionada.value ?? hoje,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(hoje.year, hoje.month, hoje.day),
                                helpText: 'Selecione a data do episódio',
                                cancelText: 'Cancelar',
                                confirmText: 'Confirmar',
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF00324A),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                dataSelecionada.value = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF00324A).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                      const Icon(Icons.event, color: Color(0xFF00324A)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      dataText,
                                          style: const TextStyle(color: Color(0xFF00324A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00324A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  if (dataSelecionada.value == null) {
                                    Get.snackbar('Data obrigatória', 'Selecione a data do episódio');
                                    return;
                                  }
                                  await controller.adicionarRegistro(
                                    pacienteId: pacienteId,
                                    intensidade: intensidadeSelecionada.value.toString(),
                                    duracao: int.tryParse(duracaoController.text) ?? 0,
                                    data: dataSelecionada.value!,
                                  );

                                  duracaoController.clear();
                                  intensidadeSelecionada.value = 0;
                                  dataSelecionada.value = null;
                                  Get.snackbar('Sucesso', 'Registro de enxaqueca salvo com sucesso');
                                },
                                child: const Text("Registrar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF00324A), width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  mostrarGrafico.value = !mostrarGrafico.value;
                                },
                                    child: Obx(() => Text(mostrarGrafico.value ? "Visualizar registros" : "Visualizar dados", style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600))),
                              ),
                            ),
                          ],
                ),
                const SizedBox(height: 24),
                // Removido: lista de dados na tela de registro. As informações ficam na tela do gráfico.
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
                      _GraficoEnxaqueca(
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
                        onClose: () {
                          mostrarGrafico.value = false;
                        },
                      ),
                        const SizedBox(height: 24),
                      _MigraineAnalysisSection(registros: controller.registrosFiltrados),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.registrosFiltrados.length,
                          itemBuilder: (context, index) {
                            final item = controller.registrosFiltrados[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: const Color(0xFF00324A), borderRadius: BorderRadius.circular(8)),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('${item.data.day}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          Text(formatarMes(item.data.month), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [const Icon(Icons.health_and_safety, color: Color(0xFF00324A), size: 16), const SizedBox(width: 8), Text('Intensidade: ${item.intensidade}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600))]),
                                        const SizedBox(height: 4),
                                        Row(children: [const Icon(Icons.timer, color: Color(0xFF00324A), size: 14), const SizedBox(width: 6), Text('Duração: ${item.duracao} h', style: const TextStyle(color: Color(0xFF00324A), fontSize: 14))]),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _buildChipIntensidade(item.intensidade),
                                            _buildChipDuracao(item.duracao),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              const url = 'https://www.disturbiosdomovimento.com.br/post/como-classificar-a-intensidade-da-dor-de-cabe%C3%A7a-e-por-que-isso-%C3%A9-importante';
                              final ok = await launchUrlString(url);
                              if (!ok) {
                                await launchUrlString(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text(
                              'Referência: Classificação de intensidade da dor de cabeça',
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
}

Widget _buildChipIntensidade(String intensidade) {
  final valor = int.tryParse(intensidade) ?? 0;
  late final Color bg;
  late final Color fg;
  if (valor <= 3) {
    bg = Colors.green.withOpacity(0.15);
    fg = Colors.green.shade700;
  } else if (valor <= 6) {
    bg = Colors.amber.withOpacity(0.2);
    fg = Colors.amber.shade800;
  } else {
    bg = Colors.red.withOpacity(0.15);
    fg = Colors.red.shade700;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: Text(classificarIntensidade(intensidade), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

Widget _buildChipDuracao(int horas) {
  // Mantém paleta principal para duração
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFF00324A).withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
    child: Text(classificarDuracaoHoras(horas), style: const TextStyle(color: Color(0xFF00324A), fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _GraficoEnxaqueca extends StatelessWidget {
  final List<Enxaqueca> registros;
  final DateTime mesSelecionado;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onClose;
  const _GraficoEnxaqueca({Key? key, required this.registros, required this.mesSelecionado, required this.onPrevMonth, required this.onNextMonth, required this.onClose}) : super(key: key);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Evolução da Intensidade', style: TextStyle(color: Color(0xFF00324A), fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(mes, style: const TextStyle(color: Color(0xFF00324A), fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Color(0xFF00324A), size: 20)),
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white12, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) return const SizedBox.shrink();
                              final d = data[i].data;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 6,
                                child: Text('${d.day}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)),
                              );
                            },
                            interval: (data.length / 6).clamp(1, 6).toDouble(),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Color(0xFF00324A), fontSize: 10)),
                            interval: 1.0,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15), width: 1)),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (int.tryParse(e.value.intensidade) ?? 0).toDouble())).toList(),
                          isCurved: true,
                          color: const Color(0xFF00324A),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF00324A),
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00324A).withOpacity(0.25),
                                const Color(0xFF00324A).withOpacity(0),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (s) => const Color(0xFF00324A)), handleBuiltInTouches: true),
                      ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: onPrevMonth,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
                  label: const Text('Anterior', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: onNextMonth,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00324A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                  label: const Text('Próximo', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MigraineAnalysisSection extends StatelessWidget {
  final List<Enxaqueca> registros;
  const _MigraineAnalysisSection({Key? key, required this.registros}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = registros.toList()..sort((a, b) => a.data.compareTo(b.data));

    return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15))),
              child: Row(
                children: [
                  Expanded(child: Column(children: [const Text('Menor', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(calcularMenorIntensidade(data), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [const Text('Média', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(calcularMediaIntensidade(data), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [const Text('Maior', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)), Text(calcularMaiorIntensidade(data), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600))])),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Removido: lista de dados na tela de registro. As informações ficam na tela do gráfico.
          ],
    );
  }
}

