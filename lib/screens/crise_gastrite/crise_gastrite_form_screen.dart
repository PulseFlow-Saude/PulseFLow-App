import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/crise_gastrite.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class CriseGastriteFormScreen extends StatefulWidget {
  final CriseGastrite? criseGastrite;

  const CriseGastriteFormScreen({Key? key, this.criseGastrite}) : super(key: key);

  @override
  State<CriseGastriteFormScreen> createState() => _CriseGastriteFormScreenState();
}

class _CriseGastriteFormScreenState extends State<CriseGastriteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sintomasController = TextEditingController();
  final _alimentosController = TextEditingController();
  final _medicacaoController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _intensidadeDor = 0;
  bool _alivioMedicacao = false;
  bool _isLoading = false;
  CriseGastrite? _criseAtual;
  bool _isEditing = false;

  final List<String> _sintomasComuns = [
    'Náusea',
    'Queimação',
    'Dor epigástrica',
    'Vômito',
    'Perda de apetite',
    'Sensação de estômago cheio',
    'Arrotos frequentes',
    'Má digestão',
  ];

  final List<String> _medicacoesComuns = [
    'Omeprazol',
    'Pantoprazol',
    'Ranitidina',
    'Famotidina',
    'Domperidona',
    'Metoclopramida',
    'Simeticona',
    'Buscopan',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final args = Get.arguments;

    if (widget.criseGastrite != null) {
      _criseAtual = widget.criseGastrite;
      _isEditing = true;
    }

    if (args != null) {
      if (args is Map && args['crise'] is CriseGastrite) {
        _criseAtual = args['crise'] as CriseGastrite;
        _isEditing = args['isEditing'] == true;
      } else if (args is CriseGastrite) {
        _criseAtual = args;
        _isEditing = true;
      }
    }

    if (_criseAtual != null && _criseAtual!.id != null) {
      _isEditing = true;
    }

    if (_criseAtual != null) {
      _populateForm(_criseAtual!);
    }
  }

  void _populateForm(CriseGastrite crise) {
    _selectedDate = crise.data;
    _intensidadeDor = crise.intensidadeDor;
    _sintomasController.text = crise.sintomas;
    _alimentosController.text = crise.alimentosIngeridos;
    _medicacaoController.text = crise.medicacao;
    _alivioMedicacao = crise.alivioMedicacao;
    _observacoesController.text = crise.observacoes;
  }

  @override
  void dispose() {
    _sintomasController.dispose();
    _alimentosController.dispose();
    _medicacaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getIntensidadeLabelKey(int intensidade) {
    switch (intensidade) {
<<<<<<< Updated upstream
      case 0: return 'pain_no';
      case 1: case 2: return 'pain_mild';
      case 3: case 4: return 'pain_moderate';
      case 5: case 6: return 'pain_moderate_severe';
      case 7: case 8: return 'pain_severe';
      case 9: return 'pain_very_severe';
      case 10: return 'pain_unbearable';
      default: return 'pain_no';
=======
      case 0:
        return 'crise_pain_none'.tr;
      case 1:
      case 2:
        return 'crise_pain_mild'.tr;
      case 3:
      case 4:
        return 'crise_pain_moderate'.tr;
      case 5:
      case 6:
        return 'crise_pain_moderate_intense'.tr;
      case 7:
      case 8:
        return 'crise_pain_intense'.tr;
      case 9:
        return 'crise_pain_very_intense'.tr;
      case 10:
        return 'crise_pain_unbearable'.tr;
      default:
        return 'crise_pain_none'.tr;
>>>>>>> Stashed changes
    }
  }

  Color _getIntensidadeColor(int intensidade) {
    if (intensidade == 0) return Colors.green;
    if (intensidade <= 3) return Colors.green;
    if (intensidade <= 6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveCrise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.id == null) {
        throw 'Usuário não autenticado';
      }

      final crise = CriseGastrite(
        id: _criseAtual?.id,
        pacienteId: currentUser!.id,
        data: _selectedDate,
        intensidadeDor: _intensidadeDor,
        sintomas: _sintomasController.text.trim(),
        alimentosIngeridos: _alimentosController.text.trim(),
        medicacao: _medicacaoController.text.trim(),
        alivioMedicacao: _alivioMedicacao,
        observacoes: _observacoesController.text.trim(),
        createdAt: _criseAtual?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing && _criseAtual?.id != null) {
        await DatabaseService().updateCriseGastrite(crise);
        _criseAtual = crise;
      } else {
        await DatabaseService().createCriseGastrite(crise);
        _criseAtual = crise;
      }

      _showSuccessAlert();
      if (!_isEditing) {
        _clearForm();
      }
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
<<<<<<< Updated upstream
        '${'gastrite_error_save'.tr}: $e',
=======
        'crise_save_error'.trParams({'e': e.toString()}),
>>>>>>> Stashed changes
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          // Header azul como outras telas
          _buildHeader(),
          
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título da seção
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00324A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
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
<<<<<<< Updated upstream
                                    _isEditing ? 'gastrite_title_edit'.tr : 'gastrite_title_new'.tr,
=======
                                    _isEditing ? 'crise_form_edit'.tr : 'crise_new_full'.tr,
>>>>>>> Stashed changes
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00324A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
<<<<<<< Updated upstream
                                    'gastrite_subtitle_short'.tr,
=======
                                    'crise_form_section'.tr,
>>>>>>> Stashed changes
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF00324A).withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                        
                        // Data da Crise
                        _buildModernTextField(
<<<<<<< Updated upstream
                          label: 'gastrite_label_data'.tr,
=======
                          label: 'crise_date_label'.tr,
>>>>>>> Stashed changes
                          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          icon: Icons.calendar_today,
                          onTap: _selectDate,
                        ),
                        const SizedBox(height: 12),

                        // Intensidade da Dor
                        _buildIntensidadeField(),
                        const SizedBox(height: 12),

                        // Sintomas
                        _buildModernTextFormField(
                          controller: _sintomasController,
<<<<<<< Updated upstream
                          label: 'gastrite_label_sintomas'.tr,
                          hint: 'gastrite_hint_sintomas'.tr,
=======
                          label: 'crise_symptoms_label'.tr,
                          hint: 'crise_symptoms_hint'.tr,
>>>>>>> Stashed changes
                          icon: Icons.health_and_safety,
                          isRequired: true,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        // Alimentos Ingeridos
                        _buildModernTextFormField(
                          controller: _alimentosController,
<<<<<<< Updated upstream
                          label: 'gastrite_label_alimentos'.tr,
                          hint: 'gastrite_hint_alimentos'.tr,
=======
                          label: 'crise_food_label'.tr,
                          hint: 'crise_food_hint'.tr,
>>>>>>> Stashed changes
                          icon: Icons.restaurant,
                          isRequired: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        // Medicação
                        _buildModernTextFormField(
                          controller: _medicacaoController,
<<<<<<< Updated upstream
                          label: 'gastrite_label_medicacao'.tr,
                          hint: 'gastrite_hint_medicacao'.tr,
=======
                          label: 'crise_med_label'.tr,
                          hint: 'crise_med_hint'.tr,
>>>>>>> Stashed changes
                          icon: Icons.medication,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        // Alívio após Medicação
                        _buildAlivioField(),
                        const SizedBox(height: 12),

                        // Observações Adicionais
                        _buildModernTextFormField(
                          controller: _observacoesController,
<<<<<<< Updated upstream
                          label: 'gastrite_label_observacoes'.tr,
                          hint: 'gastrite_hint_observacoes'.tr,
=======
                          label: 'crise_notes_label'.tr,
                          hint: 'crise_notes_hint'.tr,
>>>>>>> Stashed changes
                          icon: Icons.note_alt,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        
                      // Botões de ação
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar removido - tela tem sidebar
      // bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.menu),
    ));
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
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
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 22),
          const SizedBox(width: 12),
          
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
<<<<<<< Updated upstream
                  _isEditing ? 'gastrite_title_edit'.tr : 'gastrite_title'.tr,
=======
                  _isEditing ? 'crise_form_edit'.tr : 'crise_form_title'.tr,
>>>>>>> Stashed changes
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
<<<<<<< Updated upstream
                  'gastrite_subtitle'.tr,
=======
                  'crise_form_sub'.tr,
>>>>>>> Stashed changes
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() => const SizedBox.shrink();

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) => const SizedBox.shrink();

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _clearForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
<<<<<<< Updated upstream
              'gastrite_clear'.tr,
=======
              'common_clear'.tr,
>>>>>>> Stashed changes
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveCrise,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00324A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
<<<<<<< Updated upstream
                    _isEditing ? 'gastrite_update'.tr : 'gastrite_save'.tr,
=======
                    _isEditing ? 'common_update'.tr : 'common_save'.tr,
>>>>>>> Stashed changes
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com ícone
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00324A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
<<<<<<< Updated upstream
                        'gastrite_success'.tr,
=======
                        'crise_success'.tr,
>>>>>>> Stashed changes
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                        _isEditing
<<<<<<< Updated upstream
                            ? 'gastrite_success_updated'.tr
                            : 'gastrite_success_saved'.tr,
=======
                            ? 'crise_updated_msg'.tr
                            : 'crise_success_msg'.tr,
>>>>>>> Stashed changes
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF374151),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00324A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
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

  void _clearForm() {
    setState(() {
      _sintomasController.clear();
      _alimentosController.clear();
      _medicacaoController.clear();
      _observacoesController.clear();
      _intensidadeDor = 0;
      _alivioMedicacao = false;
      _selectedDate = DateTime.now();
      _criseAtual = null;
      _isEditing = false;
    });
  }

  Widget _buildAlivioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
<<<<<<< Updated upstream
          'gastrite_alivio_title'.tr,
=======
          'crise_relief_label'.tr,
>>>>>>> Stashed changes
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00324A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
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
                    Icons.healing_rounded,
                    color: const Color(0xFF00324A),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
<<<<<<< Updated upstream
                      'gastrite_alivio_question'.tr,
=======
                      'crise_relief_question'.tr,
>>>>>>> Stashed changes
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
<<<<<<< Updated upstream
                    'common_no'.tr,
=======
                    'menst_no'.tr,
>>>>>>> Stashed changes
                    style: TextStyle(
                      color: _alivioMedicacao ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _alivioMedicacao,
                    onChanged: (value) {
                      setState(() {
                        _alivioMedicacao = value;
                      });
                    },
                    activeColor: const Color(0xFF00324A),
                  ),
                  const SizedBox(width: 16),
                  Text(
<<<<<<< Updated upstream
                    'common_yes'.tr,
=======
                    'menst_yes'.tr,
>>>>>>> Stashed changes
                    style: TextStyle(
                      color: _alivioMedicacao ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00324A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF00324A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntensidadeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
<<<<<<< Updated upstream
          'gastrite_intensidade'.tr,
=======
          'evt_pain_intensity_label'.tr,
>>>>>>> Stashed changes
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00324A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
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
                    color: _getIntensidadeColor(_intensidadeDor),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_getIntensidadeLabelKey(_intensidadeDor).tr} (${_intensidadeDor}/10)',
                      style: TextStyle(
                        color: _getIntensidadeColor(_intensidadeDor),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getIntensidadeColor(_intensidadeDor),
                  inactiveTrackColor: _getIntensidadeColor(_intensidadeDor).withOpacity(0.3),
                  thumbColor: _getIntensidadeColor(_intensidadeDor),
                  overlayColor: _getIntensidadeColor(_intensidadeDor).withOpacity(0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _intensidadeDor.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    setState(() {
                      _intensidadeDor = value.round();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00324A),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
<<<<<<< Updated upstream
              return 'common_field_required'.tr;
=======
            return 'common_required'.tr;
>>>>>>> Stashed changes
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF00324A)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00324A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
