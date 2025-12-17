import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'diabetes_controller.dart';
import '../../models/diabetes.dart';
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

String calcularMediaGlicemia(List<Diabetes> data) {
  if (data.isEmpty) return '0';
  final soma = data.fold<double>(0, (sum, item) => sum + item.glicemia);
  return (soma / data.length).toStringAsFixed(0);
}

String calcularMaiorGlicemia(List<Diabetes> data) {
  if (data.isEmpty) return '0';
  final maior = data.map((e) => e.glicemia).reduce((a, b) => a > b ? a : b);
  return maior.toStringAsFixed(0);
}

String calcularMenorGlicemiaValor(List<Diabetes> data) {
  if (data.isEmpty) return '0';
  final menor = data.map((e) => e.glicemia).reduce((a, b) => a < b ? a : b);
  return menor.toStringAsFixed(0);
}

Color getCorGlicemia(double glicemia) {
  if (glicemia < 70) {
    return Colors.blue; // Hipoglicemia
  }
  if (glicemia <= 100) {
    return Colors.green; // Normal
  }
  if (glicemia <= 125) {
    return Colors.orange; // Pré-diabetes
  }
  return Colors.red; // Diabetes
}

String getStatusGlicemia(double glicemia) {
  if (glicemia < 70) {
    return 'Baixa';
  }
  if (glicemia <= 100) {
    return 'Normal';
  }
  if (glicemia <= 125) {
    return 'Elevada';
  }
  return 'Alta';
}

class DiabetesScreen extends StatelessWidget {
  final String pacienteId;
  final DiabetesController controller = Get.put(DiabetesController());

  DiabetesScreen({super.key, required this.pacienteId});

  final TextEditingController glicemiaController = TextEditingController();
  final Rx<DateTime?> dataSelecionada = Rx<DateTime?>(DateTime.now());
  final RxBool mostrarGrafico = false.obs; // Reverting to false

  @override
  Widget build(BuildContext context) {
    controller.carregarRegistros(pacienteId);

    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        elevation: 0,
        title: const Text('Registro de Diabetes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          // debugPrint('mostrarGrafico.value: ${mostrarGrafico.value}'); // Keep for debugging if needed elsewhere
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
                        const Text(
                          'Novo registro',
                              style: TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: glicemiaController,
                          decoration: const InputDecoration(
                            labelText: 'Glicemia (mg/dL)',
                            hintText: 'Ex: 95',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                    Get.snackbar('Data obrigatória', 'Selecione a data da medição');
                                    return;
                                  }
                                  final glicemia = double.tryParse(glicemiaController.text.replaceAll(',', '.'));
                                  if (glicemia == null) {
                                    Get.snackbar('Glicemia inválida', 'Digite um valor numérico');
                                    return;
                                  }

                                  await controller.adicionarRegistro(
                                    pacienteId: pacienteId,
                                    glicemia: glicemia,
                                    unidade: 'mg/dL',
                                    data: dataSelecionada.value!,
                                  );

                                  glicemiaController.clear();
                                  dataSelecionada.value = null;
                                    Get.snackbar('Sucesso', 'Registro de glicemia salvo com sucesso');
                                },
                                child: const Text('Registrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
                      _GraficoDiabetes(
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
                        _DiabetesAnalysisSection(registros: controller.registrosFiltrados),
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

class _DiabetesAnalysisSection extends StatelessWidget {
  final List<Diabetes> registros;

  const _DiabetesAnalysisSection({Key? key, required this.registros}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = registros.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Estatísticas rápidas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Menor', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)),
                        Text(calcularMenorGlicemiaValor(data), style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Média', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)),
                        Text('${calcularMediaGlicemia(data)}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Maior', style: TextStyle(color: Color(0xFF00324A), fontSize: 12)),
                        Text('${calcularMaiorGlicemia(data)}', style: const TextStyle(color: Color(0xFF00324A), fontSize: 20, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 12),
            // Lista de dados
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Data
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                        color: const Color(0xFF00324A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${item.data.day}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                formatarMes(item.data.month),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Informações
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                              const Icon(Icons.opacity, color: Color(0xFF00324A), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.glicemia.toStringAsFixed(1)} ${item.unidade}',
                                style: const TextStyle(color: Color(0xFF00324A), fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                              const Icon(Icons.event, color: Color(0xFF00324A), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Data: ${formatarData(item.data)}',
                                style: const TextStyle(color: Color(0xFF00324A), fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status da glicemia
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: () {
                          final s = getStatusGlicemia(item.glicemia);
                          if (s == 'Normal') return Colors.green.withOpacity(0.15);
                          if (s == 'Elevada') return Colors.amber.withOpacity(0.2);
                          if (s == 'Alta' || s == 'Baixa') return Colors.red.withOpacity(0.15);
                          return const Color(0xFF00324A).withOpacity(0.10);
                        }(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getStatusGlicemia(item.glicemia),
                        style: TextStyle(
                          color: () {
                            final s = getStatusGlicemia(item.glicemia);
                            if (s == 'Normal') return Colors.green.shade700;
                            if (s == 'Elevada') return Colors.amber.shade800;
                            if (s == 'Alta' || s == 'Baixa') return Colors.red.shade700;
                            return const Color(0xFF00324A);
                          }(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // Link de referência centralizado
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                const url = 'https://ge.globo.com/eu-atleta/saude/reportagem/2025/03/19/c-glicemia-alta-normal-ou-baixa-veja-o-que-e-e-valores.ghtml';
                final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
                if (!ok) {
                  // fallback: tenta modo in-app
                  await launchUrlString(url);
                }
              },
              child: const Text(
                'Referência: Classificação de glicemia',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF00324A), decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoDiabetes extends StatelessWidget {
  final List<Diabetes> registros;
  final DateTime mesSelecionado;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onClose;
  const _GraficoDiabetes({Key? key, required this.registros, required this.mesSelecionado, required this.onPrevMonth, required this.onNextMonth, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = registros.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

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
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Evolução da Glicemia', style: TextStyle(color: Color(0xFF00324A), fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(mes, style: const TextStyle(color: Color(0xFF00324A), fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Color(0xFF00324A), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Conteúdo principal
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) return const SizedBox.shrink();
                              final d = data[index].data;
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
                            interval: 10.0,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15), width: 1),
                      ),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: data.map((e) => e.glicemia).reduce((a, b) => a < b ? a : b) - 10,
                      maxY: data.map((e) => e.glicemia).reduce((a, b) => a > b ? a : b) + 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.glicemia);
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF00324A),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: getCorGlicemia(spot.y), // Color based on glicemia value
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              );
                            },
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

                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => const Color(0xFF00324A),
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  ),

                ),

              ),

            ],

            
            
            // Botões de navegação (na parte inferior)

            const SizedBox(height: 16),

            Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                ElevatedButton.icon(

                  onPressed: onPrevMonth,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF00324A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                  ),

                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
                  label: const Text('Anterior', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),

                ElevatedButton.icon(

                  onPressed: onNextMonth,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF00324A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                  ),

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









