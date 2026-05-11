import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/menstruacao.dart';
import '../../utils/intl_locale.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../institutional/settings_controller.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';

class MenstruacaoFormScreen extends StatefulWidget {
  final Menstruacao? menstruacao;

  const MenstruacaoFormScreen({Key? key, this.menstruacao}) : super(key: key);

  @override
  State<MenstruacaoFormScreen> createState() => _MenstruacaoFormScreenState();
}

class _MenstruacaoFormScreenState extends State<MenstruacaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _pacienteId;
  late DateTime _dataInicio;
  late DateTime _dataFim;
  bool _isLoading = false;
  bool _showCalendar = true;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime _currentMonth = DateTime.now();
  
  // Dados por dia
  Map<String, DiaMenstruacao> _diasPorData = {};

  @override
  void initState() {
    super.initState();
    _pacienteId = AuthService.instance.currentUser!.id!;
    
    if (widget.menstruacao != null) {
      // Modo edição - já tem dados
      _dataInicio = widget.menstruacao!.dataInicio;
      _dataFim = widget.menstruacao!.dataFim;
      _showCalendar = false;
      _diasPorData = Map.from(widget.menstruacao!.diasPorData!);
    } else {
      // Modo criação - mostrar calendário
      _showCalendar = true;
      _selectedStartDate = null;
      _selectedEndDate = null;
    }
  }

  void _onDateSelected(DateTime date) {
    if (_selectedStartDate == null) {
      // Primeira seleção - data de início
      setState(() {
        _selectedStartDate = date;
        _selectedEndDate = null;
      });
    } else if (_selectedEndDate == null) {
      // Segunda seleção - data de fim
      if (date.isAfter(_selectedStartDate!) || date.isAtSameMomentAs(_selectedStartDate!)) {
        setState(() {
          _selectedEndDate = date;
          _dataInicio = _selectedStartDate!;
          _dataFim = _selectedEndDate!;
        });
      _initializeDiasPorData();
        
        // Pequeno delay para mostrar o feedback visual antes de mudar de tela
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showCalendar = false;
            });
          }
        });
      } else {
        // Data anterior à de início - reiniciar seleção
        setState(() {
          _selectedStartDate = date;
          _selectedEndDate = null;
        });
      }
    }
  }

  void _initializeDiasPorData() {
    _diasPorData.clear();
    final duracao = _dataFim.difference(_dataInicio).inDays + 1;
    
    for (int i = 0; i < duracao; i++) {
      final data = _dataInicio.add(Duration(days: i));
      final dataStr = DateFormat('yyyy-MM-dd').format(data);
      _diasPorData[dataStr] = DiaMenstruacao(
        fluxo: '', // Campo vazio para o usuário definir
        teveColica: false, // Mantém false como padrão (não teve cólica)
        humor: '', // Campo vazio para o usuário definir
      );
    }
  }

  void _showDayDetailsModal(int dayIndex) {
    final data = _dataInicio.add(Duration(days: dayIndex));
    final dataStr = DateFormat('yyyy-MM-dd').format(data);
    final dia = _diasPorData[dataStr]!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDayDetailsModalWithTempData(data, dia, dataStr),
    );
  }

  Future<void> _selectDataInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = picked;
        // Ajustar data fim se necessário
        if (_dataFim.isBefore(_dataInicio)) {
          _dataFim = _dataInicio.add(const Duration(days: 5));
        }
        _initializeDiasPorData();
      });
    }
  }

  Future<void> _selectDataFim(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim,
      firstDate: _dataInicio,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _dataFim) {
      setState(() {
        _dataFim = picked;
        _initializeDiasPorData();
      });
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com gradiente
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'menst_registered'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'menst_registered_msg'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Botão de fechar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fechar o dialog
                            Get.offAllNamed('/menstruacao-history'); // Voltar para o calendário
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'menst_view_calendar'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMenstruacao() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_dataFim.isBefore(_dataInicio)) {
        Get.snackbar('common_error'.tr, 'menst_error_end_date'.tr,
            backgroundColor: AppTheme.error, colorText: Colors.white);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final novaMenstruacao = Menstruacao(
        id: widget.menstruacao?.id,
        pacienteId: _pacienteId,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        diasPorData: _diasPorData,
        createdAt: widget.menstruacao?.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.menstruacao == null) {
          await DatabaseService().createMenstruacao(novaMenstruacao);
        } else {
          await DatabaseService().updateMenstruacao(novaMenstruacao);
        }
        
        // Mostrar notificação de sucesso
        _showSuccessAlert();
        
      } catch (e) {
        Get.snackbar('common_error'.tr, '${'menst_error_save'.tr}: $e',
            backgroundColor: AppTheme.error, colorText: Colors.white);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PulseBlueScaffold(
      drawer: PulseSideMenu(activeItem: PulseNavItem.menu),
      header: PulseBlueLeadTitleHeader(
        title: widget.menstruacao == null ? 'menst_new_cycle'.tr : 'menst_edit_cycle'.tr,
        subtitle: 'menst_register_sub'.tr,
        trailing: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
        ),
      ),
      body: _showCalendar ? _buildCalendarView() : _buildDetailsView(),
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header moderno com gradiente sutil
              Container(
                width: double.infinity,
            padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                  AppTheme.lightBlue,
                  AppTheme.lightBlue.withOpacity(0.7),
                    ],
                  ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                // Ícone e título modernos
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
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
                            'menst_select_period'.tr,
                      style: AppTheme.titleLarge.copyWith(
                              color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                              fontSize: 22,
                      ),
                    ),
                          const SizedBox(height: 4),
                    Text(
                            'menst_tap_dates'.tr,
                      style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                // Instrução dinâmica moderna
                    Container(
                  padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedStartDate != null && _selectedEndDate != null
                          ? [
                              AppTheme.success.withOpacity(0.1),
                              AppTheme.success.withOpacity(0.05),
                            ]
                          : [
                              AppTheme.primaryBlue.withOpacity(0.1),
                              AppTheme.primaryBlue.withOpacity(0.05),
                            ],
                    ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                      color: _selectedStartDate != null && _selectedEndDate != null
                          ? AppTheme.success.withOpacity(0.3)
                          : AppTheme.primaryBlue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedStartDate != null && _selectedEndDate != null
                              ? AppTheme.success
                              : AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedStartDate == null 
                              ? Icons.touch_app_rounded
                              : _selectedEndDate == null
                                  ? Icons.touch_app_rounded
                                  : Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedStartDate == null 
                              ? 'menst_tap_start'.tr
                              : _selectedEndDate == null
                                  ? 'menst_tap_end'.tr
                                  : 'menst_period_success'.tr,
                          style: AppTheme.bodyLarge.copyWith(
                            color: _selectedStartDate != null && _selectedEndDate != null
                                ? AppTheme.success
                                : AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_selectedStartDate != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                        _buildModernDateIndicator('menst_start'.tr, _selectedStartDate!),
                          Container(
                            width: 1,
                          height: 50,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.secondaryBlue,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        _buildModernDateIndicator('menst_end'.tr, _selectedEndDate),
                        ],
                      ),
                    ),
                ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

          // Calendário moderno
          Container(
            padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildModernCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            // Header com período selecionado profissional
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        ),
                        const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                              'menst_period_selected'.tr,
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(_dataInicio)} - ${DateFormat('dd/MM/yyyy').format(_dataFim)}',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showCalendar = true;
                            _selectedStartDate = null;
                            _selectedEndDate = null;
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 16),
                        label: Text(
                          'menst_change'.tr,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
              ),

              const SizedBox(height: 16),

                  // Informações do ciclo profissional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfessionalStatItem('menst_duration'.tr, '${_dataFim.difference(_dataInicio).inDays + 1} ${'menst_days'.tr}'),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.secondaryBlue.withOpacity(0.3),
                        ),
                        _buildProfessionalStatItem('menst_days'.tr, '${_dataFim.difference(_dataInicio).inDays + 1}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Dados por Dia profissional
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Header profissional
                      Row(
                        children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_view_day_rounded,
                          color: Colors.white,
                            size: 20,
                        ),
                          ),
                          const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                              'menst_daily_details'.tr,
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          Text(
                              'menst_tap_edit'.tr,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'menst_edit'.tr,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Cards dos dias
                  for (int i = 0; i < _dataFim.difference(_dataInicio).inDays + 1; i++) ...[
                    _buildDaySummaryCard(i),
                    if (i < _dataFim.difference(_dataInicio).inDays) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão Salvar melhorado
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                        children: [
                          const Icon(
                        Icons.info_outline,
                        color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'menst_edit_hint'.tr,
                          style: AppTheme.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMenstruacao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'menst_register_complete'.tr,
                                style: AppTheme.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDateIndicator(String label, DateTime? date) {
    return Column(
                  children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: date != null 
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.lightBlue,
                      AppTheme.lightBlue.withOpacity(0.7),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: date != null 
                  ? AppTheme.primaryBlue
                  : AppTheme.secondaryBlue.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: date != null ? [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              date != null ? '${date.day}' : '--',
              style: AppTheme.titleLarge.copyWith(
                color: date != null ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM', Get.find<SettingsController>().effectiveLocale.toString()).format(date),
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildModernCalendar() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    
    return Column(
      children: [
        // Header do calendário moderno
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeFirst(DateFormat('MMMM yyyy', Get.find<SettingsController>().effectiveLocale.toString()).format(_currentMonth)),
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'menst_select_period_hint'.tr,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondaryBlue.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                          });
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppTheme.secondaryBlue.withOpacity(0.15),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                          });
                        },
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Dias da semana modernos
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.secondaryBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: ['menst_dow_sun', 'menst_dow_mon', 'menst_dow_tue', 'menst_dow_wed', 'menst_dow_thu', 'menst_dow_fri', 'menst_dow_sat'].map((key) =>
              Expanded(
                child: Center(
                  child: Text(
                    key.tr,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Grid do calendário moderno
        ...List.generate(6, (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: List.generate(7, (day) {
                final dayNumber = week * 7 + day - firstDayWeekday + 2;
                if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                  return const Expanded(child: SizedBox(height: 50));
                }
                
                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final isSelectedStart = _selectedStartDate != null && 
                    date.isAtSameMomentAs(_selectedStartDate!);
                final isSelectedEnd = _selectedEndDate != null && 
                    date.isAtSameMomentAs(_selectedEndDate!);
                final isInRange = _selectedStartDate != null && _selectedEndDate != null &&
                    date.isAfter(_selectedStartDate!.subtract(const Duration(days: 1))) &&
                    date.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
                final isToday = date.isAtSameMomentAs(DateTime.now());
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onDateSelected(date),
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        gradient: isSelectedStart || isSelectedEnd
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.primaryBlue.withOpacity(0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : isInRange
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue.withOpacity(0.12),
                                      AppTheme.primaryBlue.withOpacity(0.08),
                                    ],
                                  )
                                : isToday
                                    ? LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue.withOpacity(0.08),
                                          AppTheme.primaryBlue.withOpacity(0.04),
                                        ],
                                      )
                                    : null,
                        color: isSelectedStart || isSelectedEnd || isInRange || isToday
                            ? null
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelectedStart || isSelectedEnd
                              ? AppTheme.primaryBlue.withOpacity(0.3)
                              : isToday
                                  ? AppTheme.primaryBlue.withOpacity(0.3)
                                  : Colors.transparent,
                          width: isSelectedStart || isSelectedEnd ? 2 : 1.5,
                        ),
                        boxShadow: isSelectedStart || isSelectedEnd ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ] : isToday ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: AppTheme.bodyLarge.copyWith(
                            color: isSelectedStart || isSelectedEnd
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimary,
                            fontWeight: isSelectedStart || isSelectedEnd
                                ? FontWeight.w700
                                : isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDaySummaryCard(int index) {
    final data = _dataInicio.add(Duration(days: index));
    final dataStr = DateFormat('yyyy-MM-dd').format(data);
    final dia = _diasPorData[dataStr]!;
    
    return GestureDetector(
      onTap: () => _showDayDetailsModal(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Data com design profissional
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${data.day}',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', Get.find<SettingsController>().effectiveLocale.toString()).format(data),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Resumo dos dados profissional
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dia da semana
                  Text(
                    DateFormat('EEEE', Get.find<SettingsController>().effectiveLocale.toString()).format(data),
                    style: AppTheme.titleSmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Primeira linha: Fluxo e Cólica
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfessionalSummaryItem('menst_flow'.tr, dia.fluxo.isEmpty ? 'menst_not_defined'.tr : _translateFluxo(dia.fluxo), _getFluxoColor(dia.fluxo)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildProfessionalSummaryItem('menst_cramp'.tr, dia.teveColica ? 'menst_yes'.tr : 'menst_no'.tr, 
                            dia.teveColica ? const Color(0xFFEF4444) : AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Segunda linha: Humor ocupando toda a largura
                  _buildProfessionalSummaryItem('menst_mood'.tr, dia.humor.isEmpty ? 'menst_not_defined'.tr : _translateHumor(dia.humor), AppTheme.textSecondary),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.primaryBlue,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
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

  Color _getFluxoColor(String fluxo) {
    switch (fluxo) {
      case 'Leve':
        return const Color(0xFF10B981);
      case 'Moderado':
        return const Color(0xFFF59E0B);
      case 'Intenso':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF); // Cor cinza para valores não definidos
    }
  }

  Widget _buildDayDetailsModalWithTempData(DateTime data, DiaMenstruacao dia, String dataStr) {
    // Variáveis temporárias para edição
    String tempFluxo = dia.fluxo;
    bool tempTeveColica = dia.teveColica;
    String tempHumor = dia.humor;
    
    return StatefulBuilder(
      builder: (context, setModalState) {
    return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header azul como outras telas
              Container(
      width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Botão de fechar
                    Container(
      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Título
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.day} de ${DateFormat('MMMM', Get.find<SettingsController>().effectiveLocale.toString()).format(data)}',
                            style: AppTheme.titleLarge.copyWith(
        color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE', Get.find<SettingsController>().effectiveLocale.toString()).format(data),
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
          ),
        ],
      ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        // Instrução
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                          ),
                          child: Row(
            children: [
              Container(
                                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                                  Icons.edit_calendar_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
              Expanded(
                                child: Text(
                                  'menst_configure_day'.tr,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ),

                        const SizedBox(height: 24),
    
                        // Seção de Fluxo
                        Container(
                          width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                                    padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.water_drop_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'menst_flow_menstrual'.tr,
                    style: AppTheme.titleMedium.copyWith(
                                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTempFluxoSection(tempFluxo, (value) {
                                tempFluxo = value;
                                setModalState(() {});
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Seção de Sintomas
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
                          ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                    Text(
                                    'menst_symptoms_mood'.tr,
                                    style: AppTheme.titleMedium.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildTempColicaSection(tempTeveColica, (value) {
                                    tempTeveColica = value;
                                    setModalState(() {});
                                  })),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildTempHumorSection(tempHumor, (value) {
                                    tempHumor = value;
                                    setModalState(() {});
                                  })),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botões de ação
          Row(
            children: [
              Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.secondaryBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'common_cancel'.tr,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
              Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Salvar apenas quando clicar no botão
                                  setState(() {
                                    _diasPorData[dataStr] = DiaMenstruacao(
                                      fluxo: tempFluxo,
                                      teveColica: tempTeveColica,
                                      humor: tempHumor,
                                    );
                                  });
                                  Navigator.pop(context);
                                  
                                  // Mostrar notificação bonita de sucesso
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('menst_saved_day'.trParams({'day': data.day.toString()})),
                                        ],
                                      ),
                                      backgroundColor: AppTheme.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: AppTheme.primaryButtonStyle,
                                child: Text(
                                  'menst_save'.tr,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        ],
      ),
        );
      },
    );
  }


  Widget _buildProfessionalStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }





  Widget _buildTempFluxoSection(String tempFluxo, Function(String) onChanged) {
    final fluxoOptions = [
      {'value': 'Leve', 'key': 'menst_flow_light', 'color': const Color(0xFF10B981)},
      {'value': 'Moderado', 'key': 'menst_flow_moderate', 'color': const Color(0xFFF59E0B)},
      {'value': 'Intenso', 'key': 'menst_flow_heavy', 'color': const Color(0xFFEF4444)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'menst_flow'.tr,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: fluxoOptions.map((option) {
            final isSelected = tempFluxo == option['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option['value'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (option['color'] as Color).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? option['color'] as Color
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: Text(
                        (option['key'] as String).tr,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                          color: isSelected 
                              ? option['color'] as Color
                          : const Color(0xFF6B7280),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTempColicaSection(bool tempTeveColica, Function(bool) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'menst_cramp'.tr,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onChanged(!tempTeveColica),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: tempTeveColica 
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tempTeveColica 
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tempTeveColica ? Icons.favorite : Icons.favorite_border,
                  color: tempTeveColica ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  tempTeveColica ? 'menst_yes'.tr : 'menst_no'.tr,
                  style: AppTheme.bodyMedium.copyWith(
                    color: tempTeveColica ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempHumorSection(String tempHumor, Function(String) onChanged) {
    final humorOptions = [
      {'value': 'Feliz', 'key': 'menst_mood_happy', 'emoji': '😊'},
      {'value': 'Normal', 'key': 'menst_mood_normal', 'emoji': '😐'},
      {'value': 'Triste', 'key': 'menst_mood_sad', 'emoji': '😢'},
      {'value': 'Ansioso', 'key': 'menst_mood_anxious', 'emoji': '😰'},
      {'value': 'Raiva', 'key': 'menst_mood_angry', 'emoji': '😠'},
      {'value': 'Cansado', 'key': 'menst_mood_tired', 'emoji': '😴'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'menst_mood'.tr,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          ),
          child: DropdownButton<String>(
            value: tempHumor.isEmpty ? null : tempHumor,
            hint: Text(
              'menst_select_mood'.tr,
              style: AppTheme.bodySmall.copyWith(
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            isExpanded: true,
            underline: Container(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            items: humorOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'] as String,
                child: Row(
                  children: [
                    Text(
                      option['emoji'] as String,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (option['key'] as String).tr,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}


