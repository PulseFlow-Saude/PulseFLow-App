import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io';
import 'dart:convert';
import '../../data/macro_professions.dart';
import '../../data/us_state_codes.dart';
import '../../data/world_nationality_display.dart';
import '../../models/patient.dart';
import '../../utils/patient_catalog_normalize.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../institutional/settings_controller.dart';
import '../../utils/controller_mixin.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationController extends GetxController with SafeControllerMixin {
  // Máscaras de formatação
  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final rgMask = MaskTextInputFormatter(
    mask: '##.###.###-#',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  /// ZIP dos EUA: 5 dígitos ou ZIP+4 (#####-####).
  final usZipMask = MaskTextInputFormatter(
    mask: '#####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final ssnMask = MaskTextInputFormatter(
    mask: '###-##-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final usPhoneMask = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  /// País de residência na etapa pessoal: Brasil (documentos BR) ou EUA (SSN).
  static const String kResidenceBrazil = 'BR';
  static const String kResidenceUs = 'US';

  // 1. Conta
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Foto de perfil
  final profilePhoto = Rxn<File>();
  final profilePhotoBase64 = RxnString();

  // 2. Pessoais
  final residenceCountry = kResidenceBrazil.obs;
  final cpfController = TextEditingController();
  final rgController = TextEditingController();
  final socialSecurityController = TextEditingController();
  final birthDateController = TextEditingController();
  final gender = RxnString();
  final maritalStatus = RxnString();
  /// Nacionalidade: nome EN do país (lista ISO em [kWorldNationalities]).
  final nationalityCountry = RxnString();
  /// Categoria macro de profissão — chave i18n em [kMacroProfessionKeys].
  final professionMacro = RxnString();
  final heightController = TextEditingController(); // Altura
  final weightController = TextEditingController(); // Peso

  // 3. Contato e Endereço
  final phoneController = TextEditingController();
  final secondaryPhoneController = TextEditingController();
  final cepController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final complementController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final cityController = TextEditingController();
  final state = RxnString();

  // 4. Consentimentos e Notificações
  final acceptTerms = false.obs;

  final isLoading = false.obs;
  final selectedDate = Rxn<DateTime>();

  /// Etapas: 0 conta, 1 pessoais, 2 endereço (+ termos na UI).
  final currentStep = 0.obs;
  static const int totalSteps = 3;

  late final GlobalKey<FormState> accountFormKey;
  late final GlobalKey<FormState> personalFormKey;
  late final GlobalKey<FormState> addressFormKey;

  // Listas para dropdowns (chaves de tradução)
  final List<String> genders = [
    'reg_gender_male',
    'reg_gender_female',
    'reg_gender_non_binary',
    'reg_gender_prefer_not'
  ];

  final List<String> maritalStatuses = [
    'reg_marital_single',
    'reg_marital_married',
    'reg_marital_divorced',
    'reg_marital_widowed',
    'reg_marital_stable_union',
    'reg_marital_separated'
  ];

  final List<String> states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  final List<String> usStates = kUsStateCodes;

  List<String> get macroProfessionKeys => kMacroProfessionKeys;

  List<String> get addressStateOptions =>
      residenceCountry.value == kResidenceBrazil ? states : usStates;

  final authService = Get.put(AuthService());

  void setResidenceCountry(String code) {
    if (residenceCountry.value == code) return;
    residenceCountry.value = code;
    cpfController.clear();
    rgController.clear();
    socialSecurityController.clear();
    phoneController.clear();
    cepController.clear();
    streetController.clear();
    numberController.clear();
    complementController.clear();
    neighborhoodController.clear();
    cityController.clear();
    state.value = null;
  }

  // Validators (usam chaves de tradução via validate*)
  final nameValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_name_required'.tr),
    MinLengthValidator(3, errorText: 'reg_name_min'.tr),
  ]);

  final emailValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_email_required'.tr),
    EmailValidator(errorText: 'reg_email_invalid'.tr),
  ]);

  final passwordValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_password_required'.tr),
    MinLengthValidator(8, errorText: 'reg_password_min'.tr),
    PatternValidator(r'[A-Z]', errorText: 'reg_password_upper'.tr),
    PatternValidator(r'[a-z]', errorText: 'reg_password_lower'.tr),
    PatternValidator(r'[0-9]', errorText: 'reg_password_digit'.tr),
    PatternValidator(r'[!@#$%^&*(),.?":{}|<>]', errorText: 'reg_password_special'.tr),
  ]);

  final confirmPasswordValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_confirm_required'.tr),
  ]);

  final cpfValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_cpf_required'.tr),
    PatternValidator(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$', errorText: 'reg_cpf_invalid'.tr),
  ]);

  final rgValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_rg_required'.tr),
  ]);

  final phoneValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_phone_required'.tr),
    PatternValidator(r'^\(\d{2}\) \d{5}-\d{4}$', errorText: 'reg_phone_invalid'.tr),
  ]);

  final cepValidator = MultiValidator([
    RequiredValidator(errorText: 'reg_cep_required'.tr),
    PatternValidator(r'^\d{5}-\d{3}$', errorText: 'reg_cep_invalid'.tr),
  ]);

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_name_required'.tr;
    }
    if (value.length < 3) {
      return 'reg_name_min'.tr;
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value)) {
      return 'reg_name_letters'.tr;
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_email_required'.tr;
    }
    if (!GetUtils.isEmail(value)) {
      return 'reg_email_invalid'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_password_required'.tr;
    }
    if (value.length < 8) {
      return 'reg_password_min'.tr;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'reg_password_upper'.tr;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'reg_password_lower'.tr;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'reg_password_digit'.tr;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'reg_password_special'.tr;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_confirm_required'.tr;
    }
    if (value != passwordController.text) {
      return 'reg_passwords_match'.tr;
    }
    return null;
  }

  String? validateCPF(String? value) {
    if (residenceCountry.value != kResidenceBrazil) return null;
    if (value == null || value.isEmpty) {
      return 'reg_cpf_required'.tr;
    }
    
    // Remove máscara para validação
    final cpf = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cpf.length != 11) {
      return 'reg_cpf_digits'.tr;
    }
    
    // Verifica se todos os dígitos são iguais (CPF inválido)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'reg_cpf_invalid'.tr;
    }
    
    // Validação dos dígitos verificadores
    int sum = 0;
    int remainder;
    
    // Primeiro dígito verificador
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    remainder = sum % 11;
    
    if (remainder < 2) {
      if (int.parse(cpf[9]) != 0) return 'reg_cpf_invalid'.tr;
    } else {
      if (int.parse(cpf[9]) != (11 - remainder)) return 'reg_cpf_invalid'.tr;
    }
    
    // Segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    
    if (remainder < 2) {
      if (int.parse(cpf[10]) != 0) return 'reg_cpf_invalid'.tr;
    } else {
      if (int.parse(cpf[10]) != (11 - remainder)) return 'reg_cpf_invalid'.tr;
    }
    
    return null;
  }

  String? validateRG(String? value) {
    if (residenceCountry.value != kResidenceBrazil) return null;
    if (value == null || value.isEmpty) {
      return 'reg_rg_required'.tr;
    }
    return null;
  }

  String? validateSSN(String? value) {
    if (residenceCountry.value != kResidenceUs) return null;
    if (value == null || value.isEmpty) {
      return 'reg_ssn_required'.tr;
    }
    final d = value.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length != 9) {
      return 'reg_ssn_invalid'.tr;
    }
    if (d == '000000000') {
      return 'reg_ssn_invalid'.tr;
    }
    final area = int.tryParse(d.substring(0, 3)) ?? 0;
    if (area == 0 || area == 666 || area >= 900) {
      return 'reg_ssn_invalid'.tr;
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_phone_required'.tr;
    }
    final phone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (residenceCountry.value == kResidenceBrazil) {
      if (phone.length != 11) {
        return 'reg_phone_digits'.tr;
      }
    } else {
      if (phone.length != 10) {
        return 'reg_phone_us_invalid'.tr;
      }
    }
    return null;
  }

  String? validateNationalitySelection(String? _) {
    if (nationalityCountry.value == null || nationalityCountry.value!.isEmpty) {
      return 'reg_nationality_required'.tr;
    }
    return null;
  }

  /// Usa [professionMacro] diretamente — o valor do FormField pode ficar dessincronizado com Obx/rebuilds.
  String? validateProfessionMacro([String? _]) {
    return validateDropdown(professionMacro.value, 'reg_profession'.tr);
  }

  String? validateRequired(String? value, String fieldKey) {
    if (value == null || value.isEmpty) {
      return 'reg_field_required'.trParams({'field': fieldKey.tr});
    }
    return null;
  }

  String? validateCEP(String? value) {
    if (residenceCountry.value != kResidenceBrazil) return null;
    if (value == null || value.isEmpty) {
      return 'reg_cep_required'.tr;
    }

    final cep = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cep.length != 8) {
      return 'reg_cep_digits'.tr;
    }

    return null;
  }

  String? validateUSZip(String? value) {
    if (residenceCountry.value != kResidenceUs) return null;
    if (value == null || value.isEmpty) {
      return 'reg_zip_required'.tr;
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 5 && digits.length != 9) {
      return 'reg_zip_invalid'.tr;
    }
    return null;
  }

  String? validateNeighborhoodAddress(String? value) {
    if (residenceCountry.value != kResidenceBrazil) return null;
    return validateRequired(value, 'reg_neighborhood'.tr);
  }

  String buildFormattedAddress() {
    final street = streetController.text.trim();
    final num = numberController.text.trim();
    final comp = complementController.text.trim();
    final nbh = neighborhoodController.text.trim();
    final city = cityController.text.trim();
    final st = state.value ?? '';
    final postal = cepController.text.trim();
    final compSeg = comp.isEmpty ? '' : ', $comp';
    if (residenceCountry.value == kResidenceBrazil) {
      return '$street, $num$compSeg - $nbh, $city - $st';
    }
    return '$street, $num$compSeg, $city, $st $postal';
  }

  String? validateDropdown(String? value, String fieldKey) {
    if (value == null || value.isEmpty) {
      return 'reg_select_field'.trParams({'field': fieldKey.tr});
    }
    return null;
  }

  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Campo opcional
    }
    
    final height = double.tryParse(value.replaceAll(',', '.'));
    if (height == null) {
      return 'reg_height_invalid'.tr;
    }
    
    if (height < 50 || height > 250) {
      return 'reg_height_range'.tr;
    }
    
    return null;
  }

  String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Campo opcional
    }
    
    final weight = double.tryParse(value.replaceAll(',', '.'));
    if (weight == null) {
      return 'reg_weight_invalid'.tr;
    }
    
    if (weight < 20 || weight > 300) {
      return 'reg_weight_range'.tr;
    }
    
    return null;
  }

  String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'reg_birth_required'.tr;
    }
    
    if (selectedDate.value == null) {
      return 'reg_birth_select'.tr;
    }
    
    final age = DateTime.now().difference(selectedDate.value!).inDays ~/ 365;
    if (age < 18) {
      return 'reg_birth_age'.tr;
    }
    
    return null;
  }

  Future<void> selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(
            const Duration(days: 365 * 18)), // Começa com 18 anos atrás
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        locale: Get.find<SettingsController>().effectiveLocale,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryBlue,
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
        selectedDate.value = picked;
        birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      }
    } catch (e) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_error_date'.trParams({'msg': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Selecionar foto da galeria
  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        profilePhoto.value = file;
        await _convertImageToBase64(file);
      }
    } catch (e) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_error_image'.trParams({'msg': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Tirar foto com a câmera
  Future<void> takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        profilePhoto.value = file;
        await _convertImageToBase64(file);
      }
    } catch (e) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_error_camera'.trParams({'msg': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Converter imagem para base64
  Future<void> _convertImageToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      profilePhotoBase64.value = 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_error_process_image'.trParams({'msg': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Remover foto de perfil
  void removeProfilePhoto() {
    profilePhoto.value = null;
    profilePhotoBase64.value = null;
  }

  // Mostrar opções para selecionar foto
  void showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'reg_photo_select_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1CB5E0)),
                title: Text('reg_gallery'.tr),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1CB5E0)),
                title: Text('reg_camera'.tr),
                onTap: () {
                  Navigator.pop(context);
                  takePhotoWithCamera();
                },
              ),
              if (profilePhoto.value != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('reg_remove_photo'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    removeProfilePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Valida todos os campos (útil quando apenas o formulário da etapa atual está montado).
  bool validateAllFieldsForSubmit() {
    if (validateName(nameController.text) != null) return false;
    if (validateEmail(emailController.text) != null) return false;
    if (validatePassword(passwordController.text) != null) return false;
    if (validateConfirmPassword(confirmPasswordController.text) != null) return false;
    if (validateCPF(cpfController.text) != null) return false;
    if (validateRG(rgController.text) != null) return false;
    if (validateSSN(socialSecurityController.text) != null) return false;
    if (validatePhone(phoneController.text) != null) return false;
    if (validateNationalitySelection(null) != null) return false;
    if (validateBirthDate(birthDateController.text) != null) return false;
    if (validateDropdown(gender.value, 'reg_gender'.tr) != null) return false;
    if (validateDropdown(maritalStatus.value, 'reg_marital_status'.tr) != null) return false;
    if (validateDropdown(professionMacro.value, 'reg_profession'.tr) != null) return false;
    if (validateHeight(heightController.text) != null) return false;
    if (validateWeight(weightController.text) != null) return false;
    if (validateCEP(cepController.text) != null) return false;
    if (validateUSZip(cepController.text) != null) return false;
    if (validateRequired(streetController.text, 'reg_street'.tr) != null) return false;
    if (validateRequired(numberController.text, 'reg_number'.tr) != null) return false;
    if (validateNeighborhoodAddress(neighborhoodController.text) != null) return false;
    if (validateRequired(cityController.text, 'reg_city'.tr) != null) return false;
    if (validateDropdown(
          state.value,
          residenceCountry.value == kResidenceBrazil ? 'reg_state' : 'reg_state_us',
        ) !=
        null) {
      return false;
    }
    return true;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void nextStep() {
    final step = currentStep.value;
    if (step == 0) {
      if (!(accountFormKey.currentState?.validate() ?? false)) return;
    } else if (step == 1) {
      if (!(personalFormKey.currentState?.validate() ?? false)) return;
    }
    if (step < totalSteps - 1) currentStep.value = step + 1;
  }

  Future<void> register() async {
    if (!(addressFormKey.currentState?.validate() ?? false)) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_please_fill'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!validateAllFieldsForSubmit()) {
      Get.snackbar(
        'reg_error'.tr,
        'reg_please_fill'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      isLoading.value = true;

      // Validar termos e autorizações
      if (!acceptTerms.value) {
        Get.snackbar(
          'reg_error'.tr,
          'reg_terms_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final isBr = residenceCountry.value == kResidenceBrazil;
      final ssnDigits = socialSecurityController.text.replaceAll(RegExp(r'[^\d]'), '');
      final natEn = nationalityCountry.value!.trim();
      final usePt = (Get.locale?.languageCode ?? '')
          .toLowerCase()
          .startsWith('pt');

      // Criar objeto Patient
      final patient = Patient(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        cpf: isBr ? cpfController.text.trim() : '',
        rg: isBr ? rgController.text.trim() : '',
        phone: phoneController.text.trim(),
        secondaryPhone: (() {
          final text = secondaryPhoneController.text.trim();
          return text.isEmpty ? null : text;
        })(),
        birthDate: selectedDate.value!,
        gender: PatientCatalogNormalize.persistGender(
          gender.value!,
          gender.value!.tr,
        ),
        maritalStatus: PatientCatalogNormalize.persistMarital(
          maritalStatus.value!,
          maritalStatus.value!.tr,
        ),
        nationality: nationalityDisplayLabel(natEn, usePortuguese: usePt),
        residenceCountry: residenceCountry.value,
        socialSecurityNumber:
            isBr ? null : (ssnDigits.isEmpty ? null : ssnDigits),
        address: buildFormattedAddress(),
        height: (() {
          final text = heightController.text.trim();
          if (text.isEmpty) return null;
          return double.tryParse(text.replaceAll(',', '.'));
        })(), // Incluir altura se preenchida
        weight: (() {
          final text = weightController.text.trim();
          if (text.isEmpty) return null;
          return double.tryParse(text.replaceAll(',', '.'));
        })(), // Incluir peso se preenchido
        profession: PatientCatalogNormalize.persistProfession(
          professionMacro.value!,
          professionMacro.value!.tr,
        ),
        acceptedTerms: acceptTerms.value,
        profilePhoto: profilePhotoBase64.value, // Incluir foto de perfil se existir
      );

      final createdPatient = await authService.register(patient);

      // Mostrar mensagem de sucesso
      Get.snackbar(
        'reg_success'.tr,
        'reg_success_welcome'.trParams({'name': createdPatient.name}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Aguardar a mensagem ser exibida
      await Future.delayed(const Duration(seconds: 2));

      // Fazer logout para garantir que o usuário precise fazer login
      await authService.logout();

      // Redirecionar para a tela de login
      Get.offAllNamed('/login');
        } catch (e) {
      Get.snackbar(
        'reg_error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    accountFormKey = GlobalKey<FormState>();
    personalFormKey = GlobalKey<FormState>();
    addressFormKey = GlobalKey<FormState>();
    
    // Adicionar todos os controllers ao gerenciamento seguro
    addControllers([
      nameController,
      emailController,
      passwordController,
      confirmPasswordController,
      cpfController,
      rgController,
      socialSecurityController,
      birthDateController,
      heightController,
      weightController,
      phoneController,
      secondaryPhoneController,
      cepController,
      streetController,
      numberController,
      complementController,
      neighborhoodController,
      cityController,
    ]);
    // Limpar controllers de forma segura
    clearControllers();
  }

  @override
  void onClose() {
    // Limpar recursos de imagem
    profilePhoto.value = null;
    profilePhotoBase64.value = null;
    super.onClose();
  }
}
