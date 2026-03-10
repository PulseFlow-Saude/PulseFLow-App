import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/crise_gastrite.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class CriseGastriteHistoryScreen extends StatefulWidget {
  const CriseGastriteHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CriseGastriteHistoryScreen> createState() => _CriseGastriteHistoryScreenState();
}

class _CriseGastriteHistoryScreenState extends State<CriseGastriteHistoryScreen>
    with TickerProviderStateMixin {
  final List<CriseGastrite> _crises = [];
  List<CriseGastrite> _filteredCrises = [];
  String? _selectedIntensidade;
  String? _selectedPeriodo;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    
    _loadCrises();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadCrises() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.id == null) {
        throw 'Usuário não autenticado';
      }

      final crises = await DatabaseService().getCrisesGastriteByPacienteId(currentUser!.id!);

      setState(() {
        _crises.clear();
        _crises.addAll(crises);
        _isLoading = false;
        _filteredCrises = List<CriseGastrite>.from(crises);
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    final selectedIntensidade = _selectedIntensidade?.trim().toLowerCase();
    final selectedPeriodo = _selectedPeriodo?.trim();

    final filtered = _crises.where((crise) {
      if (selectedIntensidade != null && selectedIntensidade.trim().isNotEmpty) {
        final eventKey = _getIntensityFilterLabelKey(crise.intensidadeDor);
        if (eventKey != selectedIntensidade!.trim()) {
          return false;
        }
      }

      if (selectedPeriodo != null && selectedPeriodo.isNotEmpty) {
        final periodLabel = DateFormat('MM/yyyy').format(DateTime(crise.data.year, crise.data.month));
        if (periodLabel != selectedPeriodo) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {
      _filteredCrises = filtered;
    });
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
          
          // Conteúdo
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  final isPhone = constraints.maxWidth < 400;
                  
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : (isPhone ? 16 : 24),
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          // Contador e ações
                          _buildCounterSection(),
                          const SizedBox(height: 24),
                          
                          if (_isLoading)
                            _buildLoadingState()
                          else if (_hasError)
                            _buildErrorState()
                          else if (_crises.isEmpty)
                            _buildEmptyState()
                          else if (_filteredCrises.isEmpty)
                            _buildNoResultsState()
                          else
                            _buildCrisesList(isTablet, isPhone),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.CRISE_GASTRITE_FORM),
        backgroundColor: const Color(0xFF00324A),
        icon: const Icon(Icons.add, color: Colors.white),
<<<<<<< Updated upstream
        label: Text(
          'gastrite_new_crisis'.tr,
=======
          label: Text(
          'crise_new'.tr,
>>>>>>> Stashed changes
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // bottomNavigationBar removido - tela tem sidebar
      // bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
<<<<<<< Updated upstream
                  'gastrite_history_title'.tr,
=======
                  'crise_history_title'.tr,
>>>>>>> Stashed changes
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header dos filtros
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
<<<<<<< Updated upstream
                'gastrite_filters'.tr,
=======
                'common_filters'.tr,
>>>>>>> Stashed changes
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filtros em linha única
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
<<<<<<< Updated upstream
                  hint: 'gastrite_filter_intensidade'.tr,
=======
                  hint: 'crise_intensity'.tr,
>>>>>>> Stashed changes
                  icon: Icons.favorite_rounded,
                  value: _selectedIntensidade,
                  onTap: () {
                    final options = _getAvailableIntensidades();
                    _showIntensidadeFilter(options);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
<<<<<<< Updated upstream
                  hint: 'gastrite_filter_periodo'.tr,
=======
                  hint: 'crise_period'.tr,
>>>>>>> Stashed changes
                  icon: Icons.date_range,
                  value: _selectedPeriodo,
                  onTap: () {
                    final options = _getAvailablePeriodos();
                    _showPeriodoFilter(options);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
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

  List<String> _getAvailableIntensidades() {
    final map = <int, String>{};
    for (final crise in _crises) {
      final bucket = _getIntensityBucket(crise.intensidadeDor);
      map.putIfAbsent(bucket, () => _getIntensityFilterLabelKey(crise.intensidadeDor));
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList();
  }

  List<String> _getAvailablePeriodos() {
    final map = <String, String>{};
    for (final crise in _crises) {
      final periodDate = DateTime(crise.data.year, crise.data.month);
      final key = '${periodDate.year.toString().padLeft(4, '0')}-${periodDate.month.toString().padLeft(2, '0')}';
      final label = DateFormat('MM/yyyy').format(periodDate);
      map.putIfAbsent(key, () => label);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries.map((entry) => entry.value).toList();
  }

  void _showIntensidadeFilter(List<String> intensidades) {
    if (intensidades.isEmpty) {
      Get.snackbar(
        'gastrite_filter_label'.tr,
        'gastrite_no_intensidade'.tr,
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
        final selectedKey = _selectedIntensidade?.trim();
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
                          'gastrite_filter_by_intensidade'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedKey != null && selectedKey.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIntensidade = null;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: Text('common_clear'.tr),
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
                      final isSelected = intensidade == selectedKey;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            _selectedIntensidade = intensidade;
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
                          intensidade.tr,
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

  void _showPeriodoFilter(List<String> periodos) {
    if (periodos.isEmpty) {
      Get.snackbar(
        'gastrite_filter_label'.tr,
        'gastrite_no_periodo'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF1E293B),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final selectedPeriodo = _selectedPeriodo?.trim();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim();
            final normalizedQuery = query.toLowerCase();
            final filteredPeriodos = query.isEmpty
                ? periodos
                : periodos
                    .where((periodo) => periodo.toLowerCase().contains(normalizedQuery))
                    .toList();

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
                              'gastrite_filter_by_periodo'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedPeriodo != null && selectedPeriodo.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPeriodo = null;
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: Text('common_clear'.tr),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: searchController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'gastrite_hint_periodo'.tr,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (value) {
                          String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length > 6) {
                            digits = digits.substring(0, 6);
                          }

                          String formatted;
                          if (digits.length <= 2) {
                            formatted = digits;
                          } else {
                            formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
                          }

                          if (formatted != value) {
                            final offset = formatted.length;
                            searchController
                              ..text = formatted
                              ..selection = TextSelection.collapsed(offset: offset);
                          }

                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredPeriodos.isEmpty)
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
                                      ? 'gastrite_no_period_now'.tr
                                      : 'gastrite_no_period_for_query'.trParams({'query': query}),
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
                          itemCount: filteredPeriodos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final periodo = filteredPeriodos[index];
                            final isSelected = periodo == selectedPeriodo;
                            return ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedPeriodo = periodo;
                                });
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.date_range,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              title: Text(
                                periodo,
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
    ).whenComplete(() => searchController.dispose());
  }

  Widget _buildCounterSection() {
    final totalCount = _crises.length;
    final filteredCount = _filteredCrises.length;
    final hasFilters = (_selectedIntensidade != null && _selectedIntensidade!.trim().isNotEmpty) ||
        (_selectedPeriodo != null && _selectedPeriodo!.trim().isNotEmpty);
    final text = hasFilters && filteredCount != totalCount
        ? 'gastrite_count_filtered'.trParams({'filtered': '$filteredCount', 'total': '$totalCount'})
        : 'gastrite_count_found'.trParams({'count': '$filteredCount'});

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _loadCrises,
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
    );
  }

  Widget _buildSliverAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 140 : 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'gastrite_crises_title'.tr,
                                style: AppTheme.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTablet ? 20 : 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'gastrite_crises_subtitle'.tr,
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 12 : 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_crises.length}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      leading: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: PulseDrawerButton(iconSize: 20),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _loadCrises,
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'gastrite_crises_title'.tr,
            style: AppTheme.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'gastrite_crises_subtitle'.tr,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
<<<<<<< Updated upstream
                  'gastrite_loading'.tr,
=======
                  'crise_loading'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.titleMedium.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
<<<<<<< Updated upstream
                  'menstruacao_loading_sub'.tr,
=======
                  'menst_loading_sub'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade500,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
<<<<<<< Updated upstream
                  'gastrite_error_load'.tr,
=======
                  'crise_error_load'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.titleLarge.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loadCrises,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
<<<<<<< Updated upstream
                    label: Text('evento_try_again'.tr),
=======
                    label: Text('common_try_again'.tr),
>>>>>>> Stashed changes
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
<<<<<<< Updated upstream
                  'gastrite_empty_title'.tr,
=======
                  'crise_empty'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.titleLarge.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
<<<<<<< Updated upstream
                  'gastrite_empty_subtitle'.tr,
=======
                  'crise_empty_sub'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(Routes.CRISE_GASTRITE_FORM),
                    icon: const Icon(Icons.add_rounded, size: 22),
<<<<<<< Updated upstream
                    label: Text('gastrite_register_first'.tr),
=======
                    label: Text('crise_register_first'.tr),
>>>>>>> Stashed changes
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisesList(bool isTablet, bool isPhone) {
    return Column(
      children: [
        for (int i = 0; i < _filteredCrises.length; i++) ...[
          _buildCriseCard(_filteredCrises[i], i, isTablet, isPhone),
          if (i < _filteredCrises.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  int _getIntensityBucket(int intensidade) {
    if (intensidade <= 0) return 0;
    if (intensidade <= 2) return 1;
    if (intensidade <= 4) return 2;
    if (intensidade <= 6) return 3;
    if (intensidade <= 8) return 4;
    return 5;
  }

  String _getIntensityFilterLabelKey(int intensidade) {
    final bucket = _getIntensityBucket(intensidade);
    switch (bucket) {
      case 0: return 'pain_0_10';
      case 1: return 'pain_1_2_10';
      case 2: return 'pain_3_4_10';
      case 3: return 'pain_5_6_10';
      case 4: return 'pain_7_8_10';
      case 5: return 'pain_9_10_range';
      default: return 'pain_3_4_10';
    }
  }

  Widget _buildNoResultsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'gastrite_empty_title'.tr,
            style: AppTheme.titleMedium.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
<<<<<<< Updated upstream
            'gastrite_ajuste_filtros'.tr,
=======
            'crise_no_results'.tr,
>>>>>>> Stashed changes
            style: AppTheme.bodySmall.copyWith(
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCriseCard(CriseGastrite crise, int index, bool isTablet, bool isPhone) {
    final intensityColor = _getIntensidadeColor(crise.intensidadeDor);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFBFC),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showCriseDetails(crise),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com data e intensidade
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: intensityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: intensityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: intensityColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_getIntensidadeLabelKey(crise.intensidadeDor).tr} (${crise.intensidadeDor}/10)',
                                style: AppTheme.bodySmall.copyWith(
                                  color: intensityColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(crise.data),
                      style: AppTheme.bodySmall.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Título
                Text(
<<<<<<< Updated upstream
                  'gastrite_title'.tr,
=======
                  'crise_title'.tr,
>>>>>>> Stashed changes
                  style: AppTheme.titleLarge.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações principais
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sintomas
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              size: 18,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
<<<<<<< Updated upstream
                                  'gastrite_sintomas_label'.tr,
=======
                                  'evt_symptoms_label'.tr,
>>>>>>> Stashed changes
                                  style: AppTheme.bodySmall.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  crise.sintomas,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Medicação
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medication_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
<<<<<<< Updated upstream
                                  'gastrite_medicacao_label'.tr,
=======
                                  'evt_medication'.tr,
>>>>>>> Stashed changes
                                  style: AppTheme.bodySmall.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  crise.medicacao,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (crise.observacoes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  
                  // Observações
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.note_alt_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
<<<<<<< Updated upstream
                              'gastrite_observacoes_label'.tr,
=======
                              'crise_notes_label'.tr,
>>>>>>> Stashed changes
                              style: AppTheme.bodySmall.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          crise.observacoes.length > 120 
                              ? '${crise.observacoes.substring(0, 120)}...'
                              : crise.observacoes,
                          style: AppTheme.bodyMedium.copyWith(
                            color: const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Footer com hora e ação
                Row(
                  children: [
                    Text(
                      _formatTime(crise.data),
                      style: AppTheme.bodySmall.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
<<<<<<< Updated upstream
                            'gastrite_ver_detalhes'.tr,
=======
                            'common_view_details'.tr,
>>>>>>> Stashed changes
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
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

  String _getIntensidadeLabelKey(int intensidade) {
    switch (intensidade) {
      case 0: return 'pain_no';
      case 1: case 2: return 'pain_mild';
      case 3: case 4: return 'pain_moderate';
      case 5: case 6: return 'pain_moderate_severe';
      case 7: case 8: return 'pain_severe';
      case 9: case 10: return 'pain_very_severe';
      default: return 'pain_moderate';
    }
  }

  Color _getIntensidadeColor(int intensidade) {
    if (intensidade <= 3) return Colors.green;
    if (intensidade <= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
<<<<<<< Updated upstream
      return 'intl_today'.tr;
    } else if (dateOnly == yesterday) {
      return 'intl_yesterday'.tr;
=======
      return 'common_today'.tr;
    } else if (dateOnly == yesterday) {
      return 'common_yesterday'.tr;
>>>>>>> Stashed changes
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCriseDetails(CriseGastrite crise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCriseDetailsModal(crise),
    );
  }

  Widget _buildCriseDetailsModal(CriseGastrite crise) {
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
<<<<<<< Updated upstream
                        'gastrite_detalhes_crise'.tr,
=======
                        'crise_details'.tr,
>>>>>>> Stashed changes
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'gastrite_title'.tr,
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
<<<<<<< Updated upstream
                    title: 'gastrite_info_registro'.tr,
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailRow('gastrite_label_data'.tr, '${crise.data.day.toString().padLeft(2, '0')}/${crise.data.month.toString().padLeft(2, '0')}/${crise.data.year} ${'intl_at'.tr} ${_formatTime(crise.data)}'),
                      _buildDetailRow('gastrite_intensidade'.tr, '${_getIntensidadeLabelKey(crise.intensidadeDor).tr} (${crise.intensidadeDor}/10)'),
                      _buildDetailRow('gastrite_title'.tr, 'gastrite_title'.tr),
=======
                    title: 'crise_reg_info'.tr,
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailRow('crise_date'.tr, '${crise.data.day.toString().padLeft(2, '0')}/${crise.data.month.toString().padLeft(2, '0')}/${crise.data.year} às ${_formatTime(crise.data)}'),
                      _buildDetailRow('crise_pain_intensity'.tr, '${_getIntensidadeLabel(crise.intensidadeDor)} (${crise.intensidadeDor}/10)'),
                      _buildDetailRow('crise_reg_type'.tr, 'crise_title'.tr),
>>>>>>> Stashed changes
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sintomas e detalhes
                  _buildDetailSection(
                    title: '',
                    icon: Icons.description_rounded,
                    children: [
<<<<<<< Updated upstream
                      Text(
                        'gastrite_sintomas_label'.tr + ':',
=======
                        Text(
                        'evt_symptoms'.tr,
>>>>>>> Stashed changes
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crise.sintomas,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
<<<<<<< Updated upstream
                      Text(
                        'gastrite_label_alimentos'.tr + ':',
=======
                        Text(
                        'crise_food_ingested'.tr,
>>>>>>> Stashed changes
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crise.alimentosIngeridos,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  
                  if (crise.medicacao.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
<<<<<<< Updated upstream
                      title: 'evento_medicacao_title'.tr,
=======
                      title: 'evt_medication'.tr,
>>>>>>> Stashed changes
                      icon: Icons.medication_rounded,
                      children: [
                        Text(
                          crise.medicacao,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: crise.alivioMedicacao ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
<<<<<<< Updated upstream
                              '${'gastrite_alivio_title'.tr}: ${crise.alivioMedicacao ? 'common_yes'.tr : 'common_no'.tr}',
=======
                              'crise_relief_after'.trParams({'value': crise.alivioMedicacao ? 'menst_yes'.tr : 'menst_no'.tr}),
>>>>>>> Stashed changes
                              style: TextStyle(
                                color: crise.alivioMedicacao ? Colors.green : Colors.red,
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  
                  if (crise.observacoes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
<<<<<<< Updated upstream
                      title: 'gastrite_observacoes_label'.tr,
=======
                      title: 'crise_notes_label'.tr,
>>>>>>> Stashed changes
                      icon: Icons.note_alt_rounded,
                      children: [
                        Text(
                          crise.observacoes,
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
<<<<<<< Updated upstream
                      label: Text('evento_fechar'.tr),
=======
                      label: Text('common_close'.tr),
>>>>>>> Stashed changes
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
                      onPressed: () {
                        Navigator.pop(context);
                        Get.toNamed(
                          Routes.CRISE_GASTRITE_FORM,
                          arguments: {'crise': crise, 'isEditing': true},
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
<<<<<<< Updated upstream
                      label: Text('menstruacao_editar'.tr),
=======
                      label: Text('menst_edit'.tr),
>>>>>>> Stashed changes
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
          if (title.isNotEmpty) ...[
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
          ],
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

}
