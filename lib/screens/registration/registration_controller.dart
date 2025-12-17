import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/patient.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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

  // 1. Conta
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Foto de perfil
  final profilePhoto = Rxn<File>();
  final profilePhotoBase64 = RxnString();

  // 2. Pessoais
  final cpfController = TextEditingController();
  final rgController = TextEditingController();
  final birthDateController = TextEditingController();
  final gender = RxnString();
  final maritalStatus = RxnString();
  final nationalityController = TextEditingController();
  final heightController = TextEditingController(); // Altura
  final weightController = TextEditingController(); // Peso
  final professionController = TextEditingController(); // Profissão

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
  late final GlobalKey<FormState> formKey;

  // Listas para dropdowns
  final List<String> genders = [
    'Masculino',
    'Feminino',
    'Não binário',
    'Prefiro não informar'
  ];

  final List<String> maritalStatuses = [
    'Solteiro(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viúvo(a)',
    'União estável',
    'Separado(a)'
  ];

  final List<String> states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  final authService = Get.put(AuthService());

  // Validators
  final nameValidator = MultiValidator([
    RequiredValidator(errorText: 'Nome é obrigatório'),
    MinLengthValidator(3, errorText: 'Nome deve ter pelo menos 3 caracteres'),
  ]);

  final emailValidator = MultiValidator([
    RequiredValidator(errorText: 'Email é obrigatório'),
    EmailValidator(errorText: 'Email inválido'),
  ]);

  final passwordValidator = MultiValidator([
    RequiredValidator(errorText: 'Senha é obrigatória'),
    MinLengthValidator(8, errorText: 'Senha deve ter pelo menos 8 caracteres'),
    PatternValidator(r'[A-Z]', errorText: 'Senha deve conter pelo menos uma letra maiúscula'),
    PatternValidator(r'[a-z]', errorText: 'Senha deve conter pelo menos uma letra minúscula'),
    PatternValidator(r'[0-9]', errorText: 'Senha deve conter pelo menos um número'),
    PatternValidator(r'[!@#$%^&*(),.?":{}|<>]', errorText: 'Senha deve conter pelo menos um caractere especial'),
  ]);

  final confirmPasswordValidator = MultiValidator([
    RequiredValidator(errorText: 'Confirmação de senha é obrigatória'),
  ]);

  final cpfValidator = MultiValidator([
    RequiredValidator(errorText: 'CPF é obrigatório'),
    PatternValidator(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$', errorText: 'CPF inválido'),
  ]);

  final rgValidator = MultiValidator([
    RequiredValidator(errorText: 'RG é obrigatório'),
  ]);

  final phoneValidator = MultiValidator([
    RequiredValidator(errorText: 'Telefone é obrigatório'),
    PatternValidator(r'^\(\d{2}\) \d{5}-\d{4}$', errorText: 'Telefone inválido'),
  ]);

  final cepValidator = MultiValidator([
    RequiredValidator(errorText: 'CEP é obrigatório'),
    PatternValidator(r'^\d{5}-\d{3}$', errorText: 'CEP inválido'),
  ]);

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value)) {
      return 'Nome deve conter apenas letras';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um caractere especial';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    // Remove máscara para validação
    final cpf = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    
    // Verifica se todos os dígitos são iguais (CPF inválido)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
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
      if (int.parse(cpf[9]) != 0) return 'CPF inválido';
    } else {
      if (int.parse(cpf[9]) != (11 - remainder)) return 'CPF inválido';
    }
    
    // Segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    
    if (remainder < 2) {
      if (int.parse(cpf[10]) != 0) return 'CPF inválido';
    } else {
      if (int.parse(cpf[10]) != (11 - remainder)) return 'CPF inválido';
    }
    
    return null;
  }

  String? validateRG(String? value) {
    if (value == null || value.isEmpty) {
      return 'RG é obrigatório';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    // Remove máscara para validação
    final phone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (phone.length != 11) {
      return 'Telefone deve ter 11 dígitos';
    }
    
    return null;
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  String? validateCEP(String? value) {
    if (value == null || value.isEmpty) {
      return 'CEP é obrigatório';
    }
    
    // Remove máscara para validação
    final cep = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cep.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    
    return null;
  }

  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Selecione $fieldName';
    }
    return null;
  }

  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Campo opcional
    }
    
    final height = double.tryParse(value.replaceAll(',', '.'));
    if (height == null) {
      return 'Altura inválida';
    }
    
    if (height < 50 || height > 250) {
      return 'Altura deve estar entre 50 e 250 cm';
    }
    
    return null;
  }

  String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Campo opcional
    }
    
    final weight = double.tryParse(value.replaceAll(',', '.'));
    if (weight == null) {
      return 'Peso inválido';
    }
    
    if (weight < 20 || weight > 300) {
      return 'Peso deve estar entre 20 e 300 kg';
    }
    
    return null;
  }

  String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data de nascimento é obrigatória';
    }
    
    if (selectedDate.value == null) {
      return 'Selecione uma data válida';
    }
    
    final age = DateTime.now().difference(selectedDate.value!).inDays ~/ 365;
    if (age < 18) {
      return 'É necessário ter pelo menos 18 anos para se cadastrar';
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
        locale: const Locale('pt', 'BR'),
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
        // Força a validação do campo
        formKey.currentState?.validate();
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao selecionar data: ${e.toString()}',
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
        'Erro',
        'Erro ao selecionar imagem: $e',
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
        'Erro',
        'Erro ao tirar foto: $e',
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
        'Erro',
        'Erro ao processar imagem: $e',
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
              const Text(
                'Selecionar Foto de Perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1CB5E0)),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1CB5E0)),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  takePhotoWithCamera();
                },
              ),
              if (profilePhoto.value != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover Foto'),
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

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'Erro',
        'Por favor, preencha todos os campos obrigatórios corretamente',
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
          'Erro',
          'É necessário aceitar todos os termos e autorizações',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Criar objeto Patient
      final patient = Patient(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        cpf: cpfController.text.trim(),
        rg: rgController.text.trim(),
        phone: phoneController.text.trim(),
        secondaryPhone: (() {
          final text = secondaryPhoneController.text.trim();
          return text.isEmpty ? null : text;
        })(),
        birthDate: selectedDate.value!,
        gender: gender.value!,
        maritalStatus: maritalStatus.value!,
        nationality: nationalityController.text.trim(),
        address: '${streetController.text.trim()}, ${numberController.text.trim()} - ${neighborhoodController.text.trim()}, ${cityController.text.trim()} - ${state.value}',
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
        profession: (() {
          final text = professionController.text.trim();
          return text.isEmpty ? null : text;
        })(), // Incluir profissão se preenchida
        acceptedTerms: acceptTerms.value,
        profilePhoto: profilePhotoBase64.value, // Incluir foto de perfil se existir
      );

      final createdPatient = await authService.register(patient);

      if (createdPatient != null) {
        // Mostrar mensagem de sucesso
        Get.snackbar(
          'Sucesso',
          'Cadastro realizado com sucesso! Bem-vindo(a), ${createdPatient.name}!',
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
      } else {
        throw 'Erro ao criar conta: Não foi possível criar o usuário';
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
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
    // Inicializar o formKey
    formKey = GlobalKey<FormState>();
    
    // Adicionar todos os controllers ao gerenciamento seguro
    addControllers([
      nameController,
      emailController,
      passwordController,
      confirmPasswordController,
      cpfController,
      rgController,
      birthDateController,
      nationalityController,
      heightController,
      weightController,
      professionController,
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
