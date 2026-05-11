import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/evento_clinico.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_health_record_form_widgets.dart';
import '../../widgets/pulse_side_menu.dart';

class EventoClinicoFormScreen extends StatefulWidget {
  final String? pacienteId;

  const EventoClinicoFormScreen({super.key, this.pacienteId});

  @override
  State<EventoClinicoFormScreen> createState() => _EventoClinicoFormScreenState();
}

class _EventoClinicoFormScreenState extends State<EventoClinicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _medicacaoController = TextEditingController();
  final _sintomasController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();
  
  String? _selectedTipo;
  int _intensidadeDor = 0;
  DateTime _selectedDate = DateTime.now();

  static const List<String> _tipoKeys = [
    'evento_tipo_crise',
    'evento_tipo_cronico',
    'evento_tipo_psicologico',
    'evento_tipo_medicacao',
    'evento_tipo_outros',
  ];

  final List<String> _especialidades = [
    'Acupuntura',
    'Alergia e imunologia',
    'Anestesiologia',
    'Angiologia',
    'Cardiologia',
    'Cirurgia cardiovascular',
    'Cirurgia da mão',
    'Cirurgia de cabeça e pescoço',
    'Cirurgia do aparelho digestivo',
    'Cirurgia geral',
    'Cirurgia oncológica',
    'Cirurgia pediátrica',
    'Cirurgia plástica',
    'Cirurgia torácica',
    'Cirurgia vascular',
    'Clínica médica',
    'Coloproctologia',
    'Dermatologia',
    'Endocrinologia e metabologia',
    'Endoscopia',
    'Gastroenterologia',
    'Genética médica',
    'Geriatria',
    'Ginecologia e obstetrícia',
    'Hematologia e hemoterapia',
    'Homeopatia',
    'Infectologia',
    'Mastologia',
    'Medicina de emergência',
    'Medicina de família e comunidade',
    'Medicina do trabalho',
    'Medicina do tráfego',
    'Medicina esportiva',
    'Medicina física e reabilitação',
    'Medicina intensiva',
    'Medicina legal e perícia médica',
    'Medicina nuclear',
    'Medicina preventiva e social',
    'Nefrologia',
    'Neurocirurgia',
    'Neurologia',
    'Nutrologia',
    'Oftalmologia',
    'Oncologia clínica',
    'Ortopedia e traumatologia',
    'Otorrinolaringologia',
    'Patologia',
    'Patologia clínica/medicina laboratorial',
    'Pediatria',
    'Pneumologia',
    'Psiquiatria',
    'Radiologia e diagnóstico por imagem',
    'Radioterapia',
    'Reumatologia',
    'Urologia',
  ];

  String _getIntensidadeLabelKey(int intensidade) {
    switch (intensidade) {
      case 0:
        return 'evt_pain_none'.tr;
      case 1:
      case 2:
        return 'evt_pain_light'.tr;
      case 3:
      case 4:
        return 'evt_pain_moderate'.tr;
      case 5:
      case 6:
        return 'evt_pain_mod_intense'.tr;
      case 7:
      case 8:
        return 'evt_pain_intense'.tr;
      case 9:
        return 'evt_pain_very_intense'.tr;
      case 10:
        return 'evt_pain_unbearable'.tr;
      default:
        return 'evt_pain_none'.tr;
    }
  }

  Color _getIntensidadeColor(int intensidade) {
    if (intensidade == 0) return Colors.green;
    if (intensidade <= 3) return Colors.green;
    if (intensidade <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _medicacaoController.dispose();
    _sintomasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PulseBlueScaffold(
      resizeToAvoidBottomInset: true,
      drawer: PulseSideMenu(activeItem: PulseNavItem.history),
      header: PulseBlueLeadTitleHeader(
        title: 'evt_form_title'.tr,
        subtitle: 'evt_form_sub'.tr,
      ),
      body: Form(
        key: _formKey,
        child: PulseHealthRecordMaxWidthAlign(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: PulseHealthRecordLayout.scrollPadding(context, bottom: 100),
            child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PulseRecordSectionIntro(
                              icon: Icons.medical_information_rounded,
                              title: 'evt_form_title'.tr,
                              subtitle: 'menu_eventos_sub'.tr,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _tituloController,
                              label: 'evt_title'.tr,
                              hint: 'evt_title_hint'.tr,
                              labelIcon: Icons.short_text_rounded,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownField(
                              label: 'evt_type_label'.tr,
                              labelIcon: Icons.category_rounded,
                              value: _selectedTipo,
                              items: _tipoKeys,
                              onChanged: (value) => setState(() => _selectedTipo = value),
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildIntensidadeField(),
                            const SizedBox(height: 12),
                            _buildDateTimeFields(),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _descricaoController,
                              label: 'evt_desc_label'.tr,
                              hint: 'evt_desc_hint'.tr,
                              labelIcon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _medicacaoController,
                              label: 'evt_medication_label'.tr,
                              hint: 'evt_medication_hint'.tr,
                              labelIcon: Icons.medication_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _sintomasController,
                              label: 'evt_symptoms_label'.tr,
                              hint: 'evt_symptoms_hint'.tr,
                              labelIcon: Icons.healing_rounded,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildIntensidadeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PulseRecordFieldLabelRow(
            icon: Icons.monitor_heart_rounded,
            label: 'evt_pain_intensity_label'.tr,
          ),
          const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: PulseHealthRecordFormStyles.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PulseHealthRecordFormStyles.sectionBorderColor),
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
                      '${_getIntensidadeLabelKey(_intensidadeDor).tr} ($_intensidadeDor/10)',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData labelIcon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PulseRecordFieldLabelRow(
          icon: labelIcon,
          label: label,
          isRequired: isRequired,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'common_required'.tr;
            }
            return null;
          },
          decoration: PulseHealthRecordFormStyles.modernInputDecoration(
            hintText: hint,
            verticalPadding: maxLines > 1 ? 14 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData labelIcon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    double? fontSize,
  }) {
    final double textSize = fontSize ?? 14.0;
    final bool isTipoEvento = label == 'evt_type_label'.tr;
    final borderGrey = Colors.grey[300]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PulseRecordFieldLabelRow(
          icon: labelIcon,
          label: label,
          isRequired: isRequired,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          validator: (value) {
            if (isRequired && value == null) {
              return 'common_required'.tr;
            }
            return null;
          },
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Text(
                item.tr,
                style: TextStyle(
                  fontSize: isTipoEvento ? 13.0 : textSize,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          decoration: InputDecoration(
            hintText: 'common_select_option'.tr,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: PulseHealthRecordFormStyles.fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item.tr),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    final formatted =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    return PulseRecordLabeledDateTile(
      label: 'evt_date'.tr,
      labelIcon: Icons.calendar_today_outlined,
      placeholderText: 'common_select_date'.tr,
      displayText: formatted,
      showTrailingChevron: true,
      onTap: _selectDate,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _clearForm,
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
              'common_clear'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
                ),
                const SizedBox(width: 12),
                Expanded(
          child: ElevatedButton(
            onPressed: _saveEventoClinico,
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
              'common_save'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
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


  void _clearForm() {
    setState(() {
      _tituloController.clear();
      _descricaoController.clear();
      _medicacaoController.clear();
      _sintomasController.clear();
      _selectedTipo = null;
      _intensidadeDor = 0;
      _selectedDate = DateTime.now();
    });
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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
                        'evt_registered'.tr,
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
                        'evt_registered_msg'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
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
                            Navigator.of(context).pop();
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
                            'common_continue'.tr,
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

  Future<void> _saveEventoClinico() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pacienteId = widget.pacienteId ?? AuthService.instance.currentUser?.id;
    if (pacienteId == null || pacienteId.isEmpty) {
      Get.snackbar(
        'common_error'.tr,
        'evt_patient_error'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // Obter o ID do paciente atual autenticado
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.id == null) {
        Get.snackbar(
          'common_error'.tr,
          'evt_auth_error'.tr,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final pacienteId = widget.pacienteId ?? currentUser!.id!;

      final eventoClinico = EventoClinico(
        paciente: pacienteId,
        titulo: _tituloController.text.trim(),
        especialidade: '',
        tipoEvento: _selectedTipo!,
        intensidadeDor: _intensidadeDor.toString(), // Usar o valor direto do slider
        dataHora: _selectedDate,
        descricao: _descricaoController.text.trim(),
        sintomas: _sintomasController.text.trim(),
        alivio: _medicacaoController.text.trim(),
      );

      await _databaseService.createEventoClinico(eventoClinico);

      // Mostrar aviso bonito de sucesso
      _showSuccessAlert();
      
      // Limpar campos automaticamente
      _clearForm();
    } catch (e, stackTrace) {
      print('❌ [EventoClinicoForm] Erro ao salvar evento clínico: $e');
      print('❌ [EventoClinicoForm] Stack trace: $stackTrace');
      
      String errorMessage = 'Erro ao salvar evento clínico';
      if (e.toString().contains('conexão') || e.toString().contains('connection')) {
        errorMessage = 'Erro de conexão com o banco de dados. Verifique sua conexão com a internet.';
      } else if (e.toString().contains('autenticado') || e.toString().contains('authentication')) {
        errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
      } else {
        errorMessage = 'Erro ao salvar evento clínico: ${e.toString()}';
      }
      
      Get.snackbar(
        'common_error'.tr,
        errorMessage,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
  }
}