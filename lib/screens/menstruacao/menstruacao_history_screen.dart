import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/menstruacao.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/intl_locale.dart';
import '../../routes/app_routes.dart';
import '../institutional/settings_controller.dart';
import '../../widgets/menstruacao_calendar.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class MenstruacaoHistoryScreen extends StatefulWidget {
  const MenstruacaoHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MenstruacaoHistoryScreen> createState() => _MenstruacaoHistoryScreenState();
}

class _MenstruacaoHistoryScreenState extends State<MenstruacaoHistoryScreen>
    with TickerProviderStateMixin {
  final List<Menstruacao> _menstruacoes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showCalendar = true; // Controla se mostra calendário ou lista

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
    
    _loadMenstruacoes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadMenstruacoes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.id == null) {
        throw 'Usuário não autenticado';
      }

      final menstruacoes = await DatabaseService().getMenstruacoesByPacienteId(currentUser!.id!);
      
      setState(() {
        _menstruacoes.clear();
        _menstruacoes.addAll(menstruacoes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.history),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00324A),
        systemOverlayStyle: AppTheme.blueSystemOverlayStyle,
          elevation: 0,
        title: Text(
          'menst_history_title'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: const PulseDrawerButton(iconSize: 22),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadMenstruacoes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF00324A),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                      padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                            'menst_cycles_registered'.tr,
                                style: AppTheme.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          const SizedBox(height: 4),
                              Text(
                            '${_menstruacoes.length} ${'menst_cycles_tracked'.tr}',
                            style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_menstruacoes.length}',
                        style: AppTheme.titleMedium.copyWith(
                              color: Colors.white,
                          fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          
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
                padding: const EdgeInsets.all(20),
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                        ? _buildErrorState()
                        : _menstruacoes.isEmpty
                            ? _buildEmptyState()
                            : _showCalendar
                                ? _buildCalendarView()
                                : _buildMenstruacoesList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00324A),
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00324A).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
            BoxShadow(
              color: const Color(0xFF00324A).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
          ),
        ],
      ),
        child: FloatingActionButton.extended(
          onPressed: () => Get.toNamed(Routes.MENSTRUACAO_FORM),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, size: 20),
          ),
          label: Text(
            'menst_new_cycle'.tr,
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
            ),
      ),
      // bottomNavigationBar removido - tela tem sidebar
      // bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
    ));
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
                  const Color(0xFFF472B6).withOpacity(0.05),
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
                  'menst_loading'.tr,
                  style: AppTheme.titleMedium.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'menst_loading_sub'.tr,
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
                  'menst_error_load'.tr,
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
                    onPressed: _loadMenstruacoes,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text('menst_try_again'.tr),
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
                  const Color(0xFFF472B6).withOpacity(0.05),
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
                    Icons.favorite_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'menst_no_cycle'.tr,
                  style: AppTheme.titleLarge.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'menst_no_cycle_sub'.tr,
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
                    onPressed: () => Get.toNamed(Routes.MENSTRUACAO_FORM),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: Text('menst_register_first'.tr),
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


  Widget _buildCalendarView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: MenstruacaoCalendar(
            menstruacoes: _menstruacoes,
            onDaySelected: (day) => _showDayDetails(day),
          ),
        ),
      ),
    );
  }

  Widget _buildMenstruacoesList() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
      children: [
        for (int i = 0; i < _menstruacoes.length; i++) ...[
            _buildMenstruacaoCard(_menstruacoes[i], i),
          if (i < _menstruacoes.length - 1) const SizedBox(height: 16),
        ],
      ],
      ),
    );
  }

  Widget _buildMenstruacaoCard(Menstruacao menstruacao, int index) {
    final statusColor = _getStatusColor(menstruacao.status);
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
        child: InkWell(
        borderRadius: BorderRadius.circular(16),
          onTap: () => _showMenstruacaoDetails(menstruacao),
        child: Padding(
          padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com status e data
                Row(
                  children: [
                  Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(menstruacao.status),
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                        Text(
                                _translateStatus(menstruacao.status),
                                style: AppTheme.bodySmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const Spacer(),
                    Text(
                      _formatDate(menstruacao.dataInicio),
                      style: AppTheme.bodySmall.copyWith(
                      color: const Color(0xFF00324A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
              const SizedBox(height: 16),
                
                // Título
                Text(
                  'menst_cycle_title'.tr,
                style: AppTheme.titleMedium.copyWith(
                  color: const Color(0xFF00324A),
                  fontWeight: FontWeight.w700,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações principais
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                    color: const Color(0xFF64B5F6).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Período
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                            color: const Color(0xFF00324A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            ),
                          child: const Icon(
                              Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF00324A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'menst_period'.tr,
                                  style: AppTheme.bodySmall.copyWith(
                                  color: const Color(0xFF00324A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat('dd/MM').format(menstruacao.dataInicio)} - ${DateFormat('dd/MM').format(menstruacao.dataFim)}',
                                  style: AppTheme.bodyMedium.copyWith(
                                  color: const Color(0xFF00324A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Duração
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            ),
                          child: const Icon(
                              Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFF64B5F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'menst_duration'.tr,
                                  style: AppTheme.bodySmall.copyWith(
                                  color: const Color(0xFF00324A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${menstruacao.duracaoEmDias} ${'menst_days'.tr}',
                                  style: AppTheme.bodyMedium.copyWith(
                                  color: const Color(0xFF00324A),
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
                
              const SizedBox(height: 16),
                
                // Footer com data e ação
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(menstruacao.dataInicio),
                      style: AppTheme.bodySmall.copyWith(
                      color: const Color(0xFF00324A).withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                      color: const Color(0xFF00324A),
                      borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'menst_view_details'.tr,
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                        const Icon(
                            Icons.arrow_forward_ios_rounded,
                          size: 10,
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
    );
  }

  String _translateFluxo(String fluxo) {
    switch (fluxo) {
      case 'Leve':
        return 'menst_flow_light'.tr;
      case 'Moderado':
        return 'menst_flow_moderate'.tr;
      case 'Intenso':
        return 'menst_flow_heavy'.tr;
      default:
        return fluxo.isEmpty ? 'menst_not_defined'.tr : fluxo;
    }
  }

  String _translateHumor(String humor) {
    switch (humor.toLowerCase()) {
      case 'feliz':
        return 'menst_mood_happy'.tr;
      case 'normal':
        return 'menst_mood_normal'.tr;
      case 'triste':
        return 'menst_mood_sad'.tr;
      case 'ansioso':
        return 'menst_mood_anxious'.tr;
      case 'raiva':
        return 'menst_mood_angry'.tr;
      case 'cansado':
        return 'menst_mood_tired'.tr;
      default:
        return humor.isEmpty ? 'menst_not_defined'.tr : humor;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Ativa':
        return 'menst_status_active'.tr;
      case 'Próxima':
        return 'menst_status_next'.tr;
      case 'Finalizada':
        return 'menst_status_finished'.tr;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ativa':
        return Colors.red;
      case 'Próxima':
        return Colors.orange;
      case 'Finalizada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Ativa':
        return Icons.favorite_rounded;
      case 'Próxima':
        return Icons.schedule_rounded;
      case 'Finalizada':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'common_today'.tr;
    } else if (dateOnly == yesterday) {
      return 'common_yesterday'.tr;
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  void _showMenstruacaoDetails(Menstruacao menstruacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMenstruacaoDetailsModal(menstruacao),
    );
  }

  void _showDayDetails(DateTime day) {
    try {
      final menstruacao = _menstruacoes.firstWhere(
        (m) => day.isAfter(m.dataInicio.subtract(const Duration(days: 1))) &&
               day.isBefore(m.dataFim.add(const Duration(days: 1))),
      );

      // Sempre mostrar detalhes do dia específico
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      DiaMenstruacao? dia = menstruacao.diasPorData != null 
          ? menstruacao.diasPorData![dayKey]
          : null;
      
      // Se não há dados específicos, criar dados padrão baseados na posição no ciclo
      dia ??= _createDefaultDayData(day, menstruacao);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDayDetailsModal(day, dia, menstruacao),
      );
    } catch (e) {
      // Se não encontrar menstruação para o dia, não faz nada
    }
  }

  Widget _buildMenstruacaoDetailsModal(Menstruacao menstruacao) {
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
                    Icons.favorite_rounded,
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
                    'menst_details_cycle'.tr,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 22,
                      fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'menst_cycle_title'.tr,
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
                    title: 'menst_cycle_info'.tr,
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailRow('menst_start_date'.tr, DateFormat('dd/MM/yyyy às HH:mm').format(menstruacao.dataInicio)),
                      _buildDetailRow('menst_end_date'.tr, DateFormat('dd/MM/yyyy às HH:mm').format(menstruacao.dataFim)),
                      _buildDetailRow('menst_total_duration'.tr, '${menstruacao.duracaoEmDias} ${'menst_days'.tr}'),
                      _buildDetailRow('menst_status'.tr, _translateStatus(menstruacao.status)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Dados por dia
                  if (menstruacao.diasPorData != null && menstruacao.diasPorData!.isNotEmpty) ...[
                    _buildDetailSection(
                      title: 'menst_daily_data'.tr,
                      icon: Icons.calendar_view_day_rounded,
                      children: [
                        ...menstruacao.diasPorData!.entries.map((entry) {
                          final dia = entry.value;
                          final data = DateTime.parse(entry.key);
                          final isFirstDay = data == menstruacao.dataInicio;
                          final isLastDay = data == menstruacao.dataFim;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('dd/MM/yyyy - EEEE', Get.find<SettingsController>().effectiveLocale.toString()).format(data),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isFirstDay)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'menst_start'.tr,
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (isLastDay && !isFirstDay)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'menst_end'.tr,
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDayDetailRow(
                                      icon: Icons.water_drop_rounded,
                                      title: 'menst_flow'.tr,
                                      value: _translateFluxo(dia.fluxo),
                                      valueColor: _getFluxoColor(dia.fluxo),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDayDetailRow(
                                      icon: Icons.health_and_safety_rounded,
                                      title: 'menst_cramp'.tr,
                                      value: dia.teveColica ? 'menst_yes'.tr : 'menst_no'.tr,
                                      valueColor: dia.teveColica ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDayDetailRow(
                                icon: Icons.mood_rounded,
                                title: 'menst_mood'.tr,
                                value: _translateHumor(dia.humor),
                                valueColor: _getHumorColor(dia.humor),
                              ),
                              if (entry != menstruacao.diasPorData!.entries.last) ...[
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
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
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                        fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                      ),
                ),
              ],
                    ),
                    const SizedBox(height: 16),
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
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: valueColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }





  Widget _buildCycleSummary(Menstruacao menstruacao) {
    final statusColor = _getStatusColor(menstruacao.status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00324A),
            const Color(0xFF00324A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00324A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      'menst_cycle_summary'.tr,
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(menstruacao.dataInicio)} - ${DateFormat('dd/MM/yyyy').format(menstruacao.dataFim)}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _translateStatus(menstruacao.status),
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.schedule_rounded,
                  label: 'menst_duration'.tr,
                  value: '${menstruacao.duracaoEmDias} ${'menst_days'.tr}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.trending_up_rounded,
                  label: 'menst_data'.tr,
                  value: '${menstruacao.diasPorData?.length ?? 0} ${'menst_days'.tr}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCycleDetails(Menstruacao menstruacao) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'menst_detailed_info'.tr,
          style: AppTheme.titleMedium.copyWith(
            color: const Color(0xFF00324A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildModernDetailCard(
          icon: Icons.play_circle_outline_rounded,
          title: 'menst_start_date'.tr,
          value: DateFormat('dd/MM/yyyy').format(menstruacao.dataInicio),
          color: const Color(0xFF10B981),
        ),
        
        _buildModernDetailCard(
          icon: Icons.stop_circle_outlined,
          title: 'menst_end_date'.tr,
          value: DateFormat('dd/MM/yyyy').format(menstruacao.dataFim),
          color: const Color(0xFFEF4444),
        ),
        
        _buildModernDetailCard(
          icon: Icons.schedule_rounded,
          title: 'menst_total_duration'.tr,
          value: '${menstruacao.duracaoEmDias} ${'menst_days'.tr}',
          color: const Color(0xFF3B82F6),
        ),
        
        _buildModernDetailCard(
          icon: Icons.info_outline_rounded,
          title: 'menst_current_status'.tr,
          value: _translateStatus(menstruacao.status),
          color: _getStatusColor(menstruacao.status),
        ),
      ],
    );
  }

  Widget _buildModernDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
            padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
              icon,
                  color: color,
                  size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                  title,
                style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                      style: AppTheme.titleMedium.copyWith(
                        color: const Color(0xFF00324A),
                  fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildDayInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
                child: Column(
                      children: [
                        Icon(
            icon,
            color: color,
                          size: 16,
                        ),
          const SizedBox(height: 6),
                        Text(
            label,
                          style: AppTheme.bodySmall.copyWith(
              color: const Color(0xFF00324A).withOpacity(0.7),
              fontWeight: FontWeight.w500,
                          ),
                        ),
          const SizedBox(height: 2),
                    Text(
            value,
                      style: AppTheme.bodySmall.copyWith(
              color: color,
                        fontWeight: FontWeight.w700,
                      ),
            textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }

  Color _getFluxoColor(String fluxo) {
    switch (fluxo) {
      case 'Leve':
        return const Color(0xFF10B981);
      case 'Moderado':
        return const Color(0xFFF59E0B);
      case 'Intenso':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF00324A);
    }
  }


  Widget _buildDayDetailsModal(DateTime day, DiaMenstruacao? dia, Menstruacao menstruacao) {
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
                    Icons.calendar_today_rounded,
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
                        'menst_details_day'.tr,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                        Text(
                        DateFormat('dd/MM/yyyy - EEEE', Get.find<SettingsController>().effectiveLocale.toString()).format(day),
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
                  // Informações do dia
                  _buildDetailSection(
                    title: 'menst_day_data'.tr,
                    icon: Icons.water_drop_rounded,
                      children: [
                      if (dia != null) ...[
                        _buildDetailRow('menst_flow'.tr, _translateFluxo(dia.fluxo)),
                        _buildDetailRow('menst_cramp'.tr, dia.teveColica ? 'menst_yes'.tr : 'menst_no'.tr),
                        _buildDetailRow('menst_mood'.tr, _translateHumor(dia.humor)),
                      ] else ...[
                        _buildDetailRow('menst_status'.tr, 'menst_no_specific_data'.tr),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                      children: [
                        const Icon(
                                Icons.info_outline_rounded,
                            color: Color(0xFF64748B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'menst_day_data_msg'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                          ),
                        ),
                      ],
                    ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informações do ciclo
                  _buildDetailSection(
                    title: 'menst_cycle_info'.tr,
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailRow('menst_start_date'.tr, DateFormat('dd/MM/yyyy às HH:mm').format(menstruacao.dataInicio)),
                      _buildDetailRow('menst_end_date'.tr, DateFormat('dd/MM/yyyy às HH:mm').format(menstruacao.dataFim)),
                      _buildDetailRow('menst_total_duration'.tr, '${menstruacao.duracaoEmDias} ${'menst_days'.tr}'),
                      _buildDetailRow('menst_cycle_status'.tr, _translateStatus(menstruacao.status)),
                      
                      const SizedBox(height: 16),
                      
                      // Posição do dia no ciclo
                      _buildDetailRow('menst_position_in_cycle'.tr, _getDayPositionInCycle(day, menstruacao)),
                      _buildDetailRow('menst_remaining_days'.tr, _getRemainingDays(day, menstruacao)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Estatísticas do ciclo
                  _buildDetailSection(
                    title: 'menst_statistics'.tr,
                    icon: Icons.analytics_rounded,
                    children: [
                      _buildDetailRow('menst_total_days'.tr, '${menstruacao.duracaoEmDias} ${'menst_days'.tr}'),
                      _buildDetailRow('menst_days_with_data'.tr, menstruacao.diasPorData != null ? '${menstruacao.diasPorData!.length} ${'menst_days'.tr}' : '0 ${'menst_days'.tr}'),
                      _buildDetailRow('menst_progress'.tr, '${_getCycleProgress(day, menstruacao)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Color _getHumorColor(String humor) {
    switch (humor.toLowerCase()) {
      case 'feliz':
        return const Color(0xFF10B981);
      case 'triste':
        return const Color(0xFF3B82F6);
      case 'ansioso':
        return const Color(0xFFF59E0B);
      case 'raiva':
        return const Color(0xFFEF4444);
      case 'cansado':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF1E293B);
    }
  }

  String _getDayPositionInCycle(DateTime day, Menstruacao menstruacao) {
    final dayDifference = day.difference(menstruacao.dataInicio).inDays + 1;
    if (dayDifference == 1) {
      return 'menst_day_start'.tr;
    } else if (day == menstruacao.dataFim) {
      return 'menst_day_end'.trParams({'n': dayDifference.toString()});
    } else {
      return 'menst_day_n'.trParams({'n': dayDifference.toString()});
    }
  }

  String _getRemainingDays(DateTime day, Menstruacao menstruacao) {
    if (day.isBefore(menstruacao.dataInicio)) {
      final daysUntilStart = menstruacao.dataInicio.difference(day).inDays;
      return 'menst_days_until_start'.trParams({'n': daysUntilStart.toString()});
    } else if (day.isAfter(menstruacao.dataFim)) {
      return 'menst_cycle_finished'.tr;
    } else {
      final remainingDays = menstruacao.dataFim.difference(day).inDays;
      return remainingDays > 0 ? 'menst_days_remaining'.trParams({'n': remainingDays.toString()}) : 'menst_last_day'.tr;
    }
  }

  int _getCycleProgress(DateTime day, Menstruacao menstruacao) {
    if (day.isBefore(menstruacao.dataInicio)) {
      return 0;
    } else if (day.isAfter(menstruacao.dataFim)) {
      return 100;
    } else {
      final totalDays = menstruacao.duracaoEmDias;
      final currentDay = day.difference(menstruacao.dataInicio).inDays + 1;
      return ((currentDay / totalDays) * 100).round();
    }
  }


  DiaMenstruacao _createDefaultDayData(DateTime day, Menstruacao menstruacao) {
    final dayPosition = day.difference(menstruacao.dataInicio).inDays + 1;
    final isFirstDay = day == menstruacao.dataInicio;
    final isLastDay = day == menstruacao.dataFim;
    
    // Determinar fluxo baseado na posição no ciclo
    String fluxo;
    if (isFirstDay) {
      fluxo = 'Intenso'; // Primeiro dia geralmente tem fluxo mais intenso
    } else if (isLastDay) {
      fluxo = 'Leve'; // Último dia geralmente tem fluxo mais leve
    } else if (dayPosition <= 2) {
      fluxo = 'Intenso'; // Primeiros dias mais intensos
    } else if (dayPosition <= 4) {
      fluxo = 'Moderado'; // Dias intermediários moderados
    } else {
      fluxo = 'Leve'; // Últimos dias mais leves
    }
    
    // Determinar cólica baseado na posição (mais comum no início)
    bool teveColica = isFirstDay || dayPosition <= 2;
    
    // Humor padrão baseado na posição
    String humor;
    if (isFirstDay || isLastDay) {
      humor = 'Cansado'; // Início e fim podem ser mais cansativos
    } else {
      humor = 'Normal'; // Dias intermediários mais normais
    }
    
    return DiaMenstruacao(
      fluxo: fluxo,
      teveColica: teveColica,
      humor: humor,
    );
  }

}


