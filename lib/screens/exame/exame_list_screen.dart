import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../models/exame.dart';
import '../login/paciente_controller.dart';
import 'exame_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class ExameListScreen extends StatefulWidget {
  const ExameListScreen({super.key});

  @override
  State<ExameListScreen> createState() => _ExameListScreenState();
}

class _ExameListScreenState extends State<ExameListScreen> {
  final ExameController _controller = Get.put(ExameController());
  final PacienteController _paciente = Get.find<PacienteController>();
  final TextEditingController _nomeFilterController = TextEditingController();
  final TextEditingController _categoriaFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.carregarExames(_paciente.pacienteId.value);
    _nomeFilterController.addListener(() {
      _controller.filtroNome.value = _nomeFilterController.text;
    });
    _categoriaFilterController.addListener(() {
      _controller.filtroCategoria.value = _categoriaFilterController.text;
    });
  }

  @override
  void dispose() {
    _nomeFilterController.dispose();
    _categoriaFilterController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
  }

  IconData _iconForPath(String p) {
    final lower = p.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.heic')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return Colors.red;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.heic')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  Future<void> _deleteExame(Exame exame) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir Exame',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja excluir "${exame.nome}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (exame.id == null || exame.id!.isEmpty) {
          await _controller.removerExameByObject(exame);
        } else {
          await _controller.removerExame(exame.id!);
        }
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          Get.snackbar(
            'Sucesso',
            'Exame excluído com sucesso',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (err) {
        try {
          await _controller.removerExameByObject(exame);
          if (mounted) {
            Get.snackbar(
              'Sucesso',
              'Exame excluído com sucesso',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
        } catch (err2) {
          if (mounted) {
            Get.snackbar(
              'Erro',
              err2.toString(),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isPhone = screenSize.width < 420;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A),
        drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isSmallScreen),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildFilters(isSmallScreen, isPhone),
                      Expanded(
                        child: Obx(() {
                          final hasFilters = _controller.filtroNome.value.isNotEmpty ||
                              _controller.filtroCategoria.value.isNotEmpty ||
                              _controller.filtroInicio.value != null ||
                              _controller.filtroFim.value != null;
                          
                          final List<Exame> exames = hasFilters
                              ? _controller.examesFiltrados
                              : _controller.exames;
                          
                          if (_controller.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
                              ),
                            );
                          }

                          if (exames.isEmpty) {
                            return _buildEmptyState(isSmallScreen);
                          }

                          return RefreshIndicator(
                            onRefresh: () => _controller.carregarExames(_paciente.pacienteId.value),
                            color: const Color(0xFF00324A),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
                                return Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: maxWidth),
                                    child: ListView.separated(
                                      padding: EdgeInsets.all(isPhone ? 12 : 16),
                                      itemCount: exames.length,
                                      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 8 : 12),
                                      itemBuilder: (context, index) {
                                        final exame = exames[index];
                                        return _buildExameCard(exame, isSmallScreen, isPhone);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.toNamed(Routes.EXAME_UPLOAD);
          },
          backgroundColor: const Color(0xFF00324A),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Novo Exame',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.menu),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
      ),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meus Exames',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  _controller.exames.isEmpty
                      ? 'Nenhum exame registrado'
                      : '${_controller.exames.length} exame${_controller.exames.length > 1 ? 's' : ''} registrado${_controller.exames.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: isSmallScreen ? 60 : 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Nenhum exame registrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Adicione exames ao seu prontuário\nusando o botão abaixo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isSmallScreen, bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nomeFilterController,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  decoration: InputDecoration(
                    labelText: 'Nome do exame',
                    hintText: 'Buscar por nome...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: Obx(() {
                      if (_controller.filtroNome.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _nomeFilterController.clear();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00324A), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 14,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isPhone ? 8 : 12),
              Expanded(
                child: TextField(
                  controller: _categoriaFilterController,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Buscar categoria...',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    suffixIcon: Obx(() {
                      if (_controller.filtroCategoria.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _categoriaFilterController.clear();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00324A), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 14,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _controller.filtroInicio.value ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: now,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF00324A),
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      _controller.filtroInicio.value = picked;
                      HapticFeedback.lightImpact();
                    }
                  },
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Obx(() {
                    final d = _controller.filtroInicio.value;
                    return Text(
                      d == null ? 'Data início' : _formatDate(d),
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                    );
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00324A),
                    side: const BorderSide(color: Color(0xFF00324A)),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isPhone ? 6 : 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _controller.filtroFim.value ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: now,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF00324A),
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      _controller.filtroFim.value = picked;
                      HapticFeedback.lightImpact();
                    }
                  },
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Obx(() {
                    final d = _controller.filtroFim.value;
                    return Text(
                      d == null ? 'Data fim' : _formatDate(d),
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                    );
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00324A),
                    side: const BorderSide(color: Color(0xFF00324A)),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isPhone ? 6 : 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Limpar filtros',
                  onPressed: () {
                    _nomeFilterController.clear();
                    _categoriaFilterController.clear();
                    _controller.filtroNome.value = '';
                    _controller.filtroCategoria.value = '';
                    _controller.filtroInicio.value = null;
                    _controller.filtroFim.value = null;
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.clear_all, size: 20),
                  color: const Color(0xFF00324A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExameCard(Exame exame, bool isSmallScreen, bool isPhone) {
    final fileColor = _getFileColor(exame.filePath);
    final fileIcon = _iconForPath(exame.filePath);

    return Dismissible(
      key: Key(exame.id ?? exame.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Excluir Exame',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Deseja excluir "${exame.nome}"?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        _deleteExame(exame);
      },
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          try {
            await OpenFilex.open(exame.filePath);
          } catch (e) {
            Get.snackbar(
              'Erro',
              'Não foi possível abrir o arquivo',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
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
                width: isSmallScreen ? 48 : 56,
                height: isSmallScreen ? 48 : 56,
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  fileIcon,
                  color: fileColor,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exame.nome,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Expanded(
                          child: Text(
                            exame.categoria,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          _formatDate(exame.data),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _deleteExame(exame),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[300],
                    tooltip: 'Excluir exame',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
