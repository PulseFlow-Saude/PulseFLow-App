import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pulseflow_app/theme/app_theme.dart';
import '../../models/evento_clinico.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../../theme/app_theme.dart';

class EventoClinicoHistoryScreen extends StatefulWidget {
  const EventoClinicoHistoryScreen({super.key});

  @override
  State<EventoClinicoHistoryScreen> createState() => _EventoClinicoHistoryScreenState();
}

class _EventoClinicoHistoryScreenState extends State<EventoClinicoHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<EventoClinico> _eventos = [];
  List<EventoClinico> _filteredEventos = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  String? _selectedTipo;
  String? _selectedEspecialidade;
  String? _selectedIntensidadeDor;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  
  @override
  void initState() {
    super.initState();
    _loadEventos();
  }

  Future<void> _loadEventos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.id == null) {
        throw 'Usuário não autenticado';
      }

      final eventos = await _databaseService.getEventosClinicosByPacienteId(currentUser!.id!);
      
      setState(() {
        _eventos = eventos;
        _filteredEventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEventos = _eventos.where((evento) {
        final selectedEspecialidade = _selectedEspecialidade?.trim().toLowerCase();
        if (selectedEspecialidade != null && selectedEspecialidade.isNotEmpty) {
          final especialidadeEvento = evento.especialidade.trim().toLowerCase();
          if (especialidadeEvento != selectedEspecialidade) {
            return false;
          }
        }

        final selectedTipo = _selectedTipo?.trim().toLowerCase();
        if (selectedTipo != null && selectedTipo.isNotEmpty) {
          final tipoEvento = evento.tipoEvento.trim().toLowerCase();
          if (tipoEvento != selectedTipo) {
            return false;
          }
        }

        final selectedIntensidade = _selectedIntensidadeDor?.trim().toLowerCase();
        if (selectedIntensidade != null && selectedIntensidade.isNotEmpty) {
          final intensidadeValor = int.tryParse(evento.intensidadeDor) ?? 0;
          final labelEvento = _getIntensityFilterLabel(intensidadeValor).toLowerCase();
          if (labelEvento != selectedIntensidade) {
            return false;
          }
        }

        if (_selectedDateFrom != null && evento.dataHora.isBefore(_selectedDateFrom!)) {
          return false;
        }

        if (_selectedDateTo != null && evento.dataHora.isAfter(_selectedDateTo!)) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  String _getIntensidadeLabel(int intensidade) {
    switch (intensidade) {
      case 0:
        return 'Sem Dor';
      case 1:
      case 2:
        return 'Dor Leve';
      case 3:
      case 4:
        return 'Dor Moderada';
      case 5:
      case 6:
        return 'Dor Moderada a Intensa';
      case 7:
      case 8:
        return 'Dor Intensa';
      case 9:
        return 'Dor Muito Intensa';
      case 10:
        return 'Dor Insuportável';
      default:
        return 'Sem Dor';
    }
  }

  Color _getIntensidadeColor(int intensidade) {
    if (intensidade == 0) return Colors.green;
    if (intensidade <= 3) return Colors.green;
    if (intensidade <= 6) return Colors.orange;
    return Colors.red;
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
          // Header moderno com gradiente
          _buildModernHeader(),
          
          // Conteúdo principal
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _filteredEventos.isEmpty
                            ? _buildEmptyState()
                            : _buildEventosList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed('/evento-clinico-form');
        },
        backgroundColor: const Color(0xFF00324A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Evento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
    ));
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
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
          // Linha com botão voltar e título
          Row(
            children: [
              const PulseDrawerButton(),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Histórico Evento Clínico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          
          // Campos de filtro
          const SizedBox(height: 18),
          _buildFilterSection(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header melhorado com indicador
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filtros melhorados
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDropdown(
                  hint: 'Especialidade',
                  value: _selectedEspecialidade,
                  icon: Icons.medical_services_rounded,
                  onTap: () {
                    final options = _getAvailableEspecialidades();
                    _showEspecialidadeFilter(options);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancedDropdown(
                  hint: 'Tipo',
                  value: _selectedTipo,
                  icon: Icons.event_note_rounded,
                  onTap: () {
                    final options = _getAvailableTiposEvento();
                    _showTipoFilter(options);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancedDropdown(
                  hint: 'Dor',
                  value: _selectedIntensidadeDor,
                  icon: Icons.favorite_rounded,
                  onTap: () {
                    final options = _getAvailableIntensidades();
                    _showIntensidadeFilter(options);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDropdown({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? value,
  }) {
    final isActive = value != null && value.trim().isNotEmpty;
    final displayText = isActive ? value!.trim() : hint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.1),
                  ]
                : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.2),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isActive ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: Colors.white.withOpacity(isActive ? 1 : 0.8),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withOpacity(isActive ? 1 : 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableEspecialidades() {
    final map = <String, String>{};
    for (final evento in _eventos) {
      final especialidade = evento.especialidade.trim();
      if (especialidade.isEmpty) continue;
      final key = especialidade.toLowerCase();
      map.putIfAbsent(key, () => especialidade);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> _getAvailableTiposEvento() {
    final map = <String, String>{};
    for (final evento in _eventos) {
      final tipo = evento.tipoEvento.trim();
      if (tipo.isEmpty) continue;
      final key = tipo.toLowerCase();
      map.putIfAbsent(key, () => tipo);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> _getAvailableIntensidades() {
    final map = <int, String>{};
    for (final evento in _eventos) {
      final intensidade = int.tryParse(evento.intensidadeDor) ?? 0;
      final bucket = _getIntensityBucket(intensidade);
      map.putIfAbsent(bucket, () => _getIntensityFilterLabel(intensidade));
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList();
  }

  void _showEspecialidadeFilter(List<String> especialidades) {
    if (especialidades.isEmpty) {
      Get.snackbar(
        'Filtro',
        'Nenhuma especialidade disponível nos eventos.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final searchController = TextEditingController();
    bool isModalOpen = true;
    bool shouldApplyFilters = false;
    bool ignoreTextChange = false;
    String? pendingEspecialidade = _selectedEspecialidade;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedLower = _selectedEspecialidade?.toLowerCase();
            final query = searchController.text.trim().toLowerCase();
            final filteredEspecialidades = query.isEmpty
                ? especialidades
                : especialidades.where((especialidade) => especialidade.toLowerCase().contains(query)).toList();

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filtrar por especialidade',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedEspecialidade != null && _selectedEspecialidade!.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                pendingEspecialidade = null;
                                shouldApplyFilters = true;
                                isModalOpen = false;
                                Navigator.pop(context);
                              },
                              child: const Text('Limpar'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar especialidade',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (_) {
                          if (!isModalOpen || ignoreTextChange) return;
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredEspecialidades.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  query.isEmpty
                                      ? 'Nenhuma especialidade disponível atualmente.'
                                      : 'Nenhuma especialidade encontrada para "$query".',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredEspecialidades.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final especialidade = filteredEspecialidades[index];
                            final isSelected = especialidade.toLowerCase() == selectedLower;
                            return ListTile(
                              onTap: () {
                                pendingEspecialidade = especialidade;
                                ignoreTextChange = true;
                                searchController
                                  ..text = especialidade
                                  ..selection = TextSelection.collapsed(offset: especialidade.length);
                                ignoreTextChange = false;
                                shouldApplyFilters = true;
                                isModalOpen = false;
                                Navigator.pop(context);
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_hospital_rounded,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              title: Text(
                                especialidade,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_rounded, color: Color(0xFF1E3A8A))
                                  : null,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isModalOpen = false;
      searchController.dispose();
      if (!mounted || !shouldApplyFilters) return;
      setState(() {
        _selectedEspecialidade = pendingEspecialidade;
      });
      _applyFilters();
    });
  }

  void _showTipoFilter(List<String> tipos) {
    if (tipos.isEmpty) {
      Get.snackbar(
        'Filtro',
        'Nenhum tipo de evento disponível.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final selectedLower = _selectedTipo?.trim().toLowerCase();
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtrar por tipo de evento',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedLower != null && selectedLower.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTipo = null;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tipos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final tipo = tipos[index];
                      final isSelected = tipo.toLowerCase() == selectedLower;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            _selectedTipo = tipo;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        title: Text(
                          tipo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFF0F766E))
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIntensidadeFilter(List<String> intensidades) {
    if (intensidades.isEmpty) {
      Get.snackbar(
        'Filtro',
        'Nenhuma intensidade de dor registrada.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final selectedLower = _selectedIntensidadeDor?.trim().toLowerCase();
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtrar por intensidade da dor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedLower != null && selectedLower.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIntensidadeDor = null;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: intensidades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final intensidade = intensidades[index];
                      final isSelected = intensidade.toLowerCase() == selectedLower;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            _selectedIntensidadeDor = intensidade;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        title: Text(
                          intensidade,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFFDC2626))
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getIntensityBucket(int intensidade) {
    if (intensidade <= 0) return 0;
    if (intensidade <= 2) return 1;
    if (intensidade <= 4) return 2;
    if (intensidade <= 6) return 3;
    if (intensidade <= 8) return 4;
    if (intensidade == 9) return 5;
    return 6;
  }

  String _getIntensityFilterLabel(int intensidade) {
    switch (_getIntensityBucket(intensidade)) {
      case 0:
        return 'Sem Dor (0/10)';
      case 1:
        return 'Dor Leve (1-2/10)';
      case 2:
        return 'Dor Moderada (3-4/10)';
      case 3:
        return 'Dor Moderada a Intensa (5-6/10)';
      case 4:
        return 'Dor Intensa (7-8/10)';
      case 5:
        return 'Dor Muito Intensa (9/10)';
      default:
        return 'Dor Insuportável (10/10)';
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00324A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF00324A),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Carregando eventos clínicos...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erro ao carregar eventos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadEventos,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00324A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00324A).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: Color(0xFF00324A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum evento encontrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Você ainda não registrou nenhum evento clínico.\nComece registrando seu primeiro evento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/evento-clinico-form');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar Primeiro Evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00324A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_filteredEventos.length} evento${_filteredEventos.length == 1 ? '' : 's'} encontrado${_filteredEventos.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadEventos,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF00324A),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF00324A).withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _filteredEventos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final evento = _filteredEventos[index];
              return _buildEventoCard(evento);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00324A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00324A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00324A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF00324A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoCard(EventoClinico evento) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventoDetails(evento),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com especialidade e data
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00324A).withOpacity(0.1),
                            const Color(0xFF00324A).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00324A).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.medical_services,
                            size: 16,
                            color: Color(0xFF00324A),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              evento.especialidade,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00324A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${evento.dataHora.day}/${evento.dataHora.month}/${evento.dataHora.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Título principal do evento
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                
                if (evento.descricao.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    evento.descricao,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A4A4A),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Informações adicionais em chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.event_note,
                      evento.tipoEvento,
                      const Color(0xFF00324A),
                    ),
                    if (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0)
                      _buildInfoChip(
                        Icons.favorite,
                        '${_getIntensidadeLabel(int.parse(evento.intensidadeDor))} (${evento.intensidadeDor}/10)',
                        _getIntensidadeColor(int.parse(evento.intensidadeDor)),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botão de ação
                Row(
                  children: [
                    const Text(
                      'Toque para ver detalhes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00324A), Color(0xFF00324A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00324A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver detalhes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }



  void _showEventoDetails(EventoClinico evento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildEventoDetailsModal(evento),
      ),
    );
  }

  Widget _buildEventoDetailsModal(EventoClinico evento) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 24,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.titulo.isNotEmpty ? evento.titulo : 'Detalhes do Evento',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        evento.especialidade,
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações básicas
                  _buildDetailSection(
                    title: 'Informações do Registro',
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailRow('Especialidade', evento.especialidade),
                      _buildDetailRow('Data do Atendimento', _formatDate(evento.dataHora)),
                      _buildDetailRow('Tipo da Consulta', evento.tipoEvento),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Descrição do registro, sintomas e intensidade da dor
                  if (evento.descricao.isNotEmpty || evento.sintomas.isNotEmpty || (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0))
                    _buildDetailSection(
                      title: '',
                      icon: Icons.description_rounded,
                      children: [
                        if (evento.descricao.isNotEmpty) ...[
                          Text(
                            'Descrição do evento:',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            evento.descricao,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (evento.sintomas.isNotEmpty || (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0)) const SizedBox(height: 16),
                        ],
                        if (evento.sintomas.isNotEmpty) ...[
                          Text(
                            'Sintomas:',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            evento.sintomas,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0) const SizedBox(height: 16),
                        ],
                        if (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0) ...[
                          Text(
                            'Intensidade da Dor:',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getIntensidadeColor(int.parse(evento.intensidadeDor)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_getIntensidadeLabel(int.parse(evento.intensidadeDor))} (${evento.intensidadeDor}/10)',
                                style: TextStyle(
                                  color: _getIntensidadeColor(int.parse(evento.intensidadeDor)),
                                  fontSize: 15,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  
                  if (evento.alivio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      title: 'Medicação/Alívio',
                      icon: Icons.medication_rounded,
                      children: [
                        Text(
                          evento.alivio,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Footer
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Fechar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _exportEventoToPdf(evento);
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Exportar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1E3A8A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }


  Future<void> _exportEventoToPdf(EventoClinico evento) async {
    try {
      final now = DateTime.now();
      final pdf = pw.Document();
      final bytes = await rootBundle.load('assets/images/Pulselogo.png');
      final logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final atendimentoEm = DateFormat('dd/MM/yyyy HH:mm').format(evento.dataHora);
      final patientName = AuthService.instance.currentUser?.name ?? 'Paciente não identificado';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) {
            const titleColor = PdfColor.fromInt(0xFF00324A);
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Histórico de Eventos Clínicos',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Documento gerado em $generatedAt',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.blueGrey600,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        width: 90,
                        height: 36,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Dados principais',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _pdfInfoRow('Título do evento', _fallbackValue(evento.titulo, fallback: 'Sem título informado')),
                  _pdfInfoRow('Paciente', patientName),
                  _pdfInfoRow('Especialidade', evento.especialidade),
                  _pdfInfoRow('Tipo do evento', evento.tipoEvento),
                  _pdfInfoRow('Data do atendimento', atendimentoEm),
                  if (int.tryParse(evento.intensidadeDor) != null && int.tryParse(evento.intensidadeDor)! > 0)
                    _pdfInfoRow(
                      'Intensidade da dor',
                      '${evento.intensidadeDor}/10 - ${_getIntensidadeLabel(int.parse(evento.intensidadeDor))}',
                    ),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'Descrição do evento',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _formatLongText(evento.descricao, fallback: 'Sem descrição registrada.'),
                    style: pw.TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  if (evento.sintomas.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Sintomas relatados',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      evento.sintomas,
                      style: pw.TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ],
                  if (evento.alivio.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Medicação / Alívio',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      evento.alivio,
                      style: pw.TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFE0F2FE),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Observações',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Histórico exportado automaticamente pelo aplicativo PulseFlow.',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blueGrey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final savedBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedPatient = _sanitizeFileName(patientName);
      final atendimentoDate = DateFormat('ddMMyyyy').format(evento.dataHora);
      final filename = '${sanitizedPatient}_$atendimentoDate.pdf';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(savedBytes, flush: true);

      Get.snackbar(
        'PDF exportado',
        'Arquivo salvo como $filename',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );

      final openResult = await OpenFilex.open(file.path);
      if (openResult.type != ResultType.done) {
        Get.snackbar(
          'Abrir arquivo',
          'Não foi possível abrir o PDF automaticamente. Caminho: ${file.path}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: const Color(0xFF1E293B),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro ao exportar',
        'Não foi possível gerar o PDF. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      );
    }
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? 'Não informado' : value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLongText(String text, {String fallback = 'Informação não registrada.'}) {
    if (text.trim().isEmpty) {
      return fallback;
    }
    return text.length > 400 ? '${text.substring(0, 400)}...' : text;
  }

  String _fallbackValue(String value, {required String fallback}) {
    return value.trim().isEmpty ? fallback : value;
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (sanitized.isEmpty) {
      return 'paciente';
    }
    return sanitized.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }
}