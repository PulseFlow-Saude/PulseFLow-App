import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/patient.dart';
import '../../utils/residence_date_format.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../../services/health_service.dart';
import '../../services/health_data_service.dart';
import '../../services/health_data_test_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final HealthService _healthService = HealthService();
  final HealthDataService _healthDataService = HealthDataService();
  final HealthDataTestService _healthDataTestService = HealthDataTestService();
  final ImagePicker _imagePicker = ImagePicker();

  // Estados observáveis
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isRequestingHealthPermissions = false.obs;
  final _healthDataAccessGranted = false.obs;
  final _heartRate = 0.0.obs;
  final _sleepQuality = 0.0.obs;
  final _dailySteps = 0.obs;
  final _isEditing = false.obs;

  // Dados do paciente
  final _patient = Rxn<Patient>();
  final _profilePhoto = Rxn<String>();

  // Controladores de texto
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final birthDateController = TextEditingController();
  final cpfController = TextEditingController();
  final rgController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isRequestingHealthPermissions => _isRequestingHealthPermissions.value;
  bool get healthDataAccessGranted => _healthDataAccessGranted.value;
  double get heartRate => _heartRate.value;
  double get sleepQuality => _sleepQuality.value;
  int get dailySteps => _dailySteps.value;
  Patient? get patient => _patient.value;
  String? get profilePhoto => _profilePhoto.value;
  bool get isEditing => _isEditing.value;
  String get birthDateDisplay => ResidenceDateFormat.formatDate(
        _patient.value?.birthDate,
        _patient.value?.residenceCountry,
      );

  @override
  void onInit() {
    super.onInit();
    _loadPatientData();
    _checkHealthPermissions();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    cpfController.dispose();
    rgController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();
    super.onClose();
  }

  // Verifica permissões do HealthKit na inicialização
  Future<void> _checkHealthPermissions() async {
    try {
      final inApp = await _healthService.isAppleHealthInAppEnabled();
      if (!inApp) {
        _healthDataAccessGranted.value = false;
        await _loadHealthDataFromDatabase();
        return;
      }

      // iOS: o plugin devolve `null` para leitura em hasPermissions (privacidade Apple) —
      // não dá para distinguir "nunca pediu" de "já concedeu". Pedimos autorização e seguimos.
      if (Platform.isIOS) {
        final granted = await _healthService.requestPermissions();
        if (granted) {
          _healthDataAccessGranted.value = true;
          await _loadHealthData();
        } else {
          _healthDataAccessGranted.value = false;
          await _loadHealthDataFromDatabase();
          // Não desligar a integração in-app no iOS: falha pode ser técnica; o utilizador pode voltar a tentar.
        }
        return;
      }

      final hasPermissions = await _healthService.hasPermissions();
      if (hasPermissions) {
        _healthDataAccessGranted.value = true;
        await _loadHealthData();
      } else {
        final granted = await _healthService.requestPermissions();

        if (granted) {
          _healthDataAccessGranted.value = true;
          await _loadHealthData();

          Get.snackbar(
            'profile_success'.tr,
            'profile_success_health'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          await _healthService.setAppleHealthInAppEnabled(false);
          _healthDataAccessGranted.value = false;
          await _loadHealthDataFromDatabase();
        }
      }
    } catch (e) {
      await _loadHealthDataFromDatabase();
    }
  }

  // Carrega dados de saúde do banco de dados
  Future<void> _loadHealthDataFromDatabase() async {
    try {
      if (_patient.value == null) return;
      
      
      // Busca dados dos últimos 7 dias
      final healthData = await _healthDataService.getHealthDataLastDays(_patient.value!.id!, 7);
      
      if (healthData.isNotEmpty) {
        // Extrai dados mais recentes
        final heartRateData = healthData.where((d) => d.dataType == 'heartRate').toList();
        final sleepData = healthData.where((d) => d.dataType == 'sleep').toList();
        final stepsData = healthData.where((d) => d.dataType == 'steps').toList();
        
        if (heartRateData.isNotEmpty) {
          _heartRate.value = heartRateData.first.value;
        }
        
        if (sleepData.isNotEmpty) {
          _sleepQuality.value = sleepData.first.value * 10; // Converte horas para percentual
        }
        
        if (stepsData.isNotEmpty) {
          _dailySteps.value = stepsData.first.value.round();
        }
        
      } else {
      }
      
    } catch (e) {
    }
  }

  // Carrega os dados do paciente
  Future<void> _loadPatientData() async {
    try {
      _isLoading.value = true;
      await _authService.refreshCurrentUser();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _patient.value = currentUser;
        _profilePhoto.value = currentUser.profilePhoto;
        _populateControllers(currentUser);
      }
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_load'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void enterEditingMode() {
    _isEditing.value = true;
  }

  void cancelEditing() {
    _restoreFormFields();
    _isEditing.value = false;
  }

  void _restoreFormFields() {
    final current = _patient.value;
    if (current == null) return;
    _populateControllers(current);
  }

  /// Residência EUA: exibir apenas SSN, sem CPF/RG.
  bool patientShowsUsSocialSecurity(Patient? p) =>
      (p?.residenceCountry ?? '').toUpperCase() == 'US';

  static String formatSsnDisplay(String digitsOrMasked) {
    final d = digitsOrMasked.replaceAll(RegExp(r'\D'), '');
    if (d.length != 9) return digitsOrMasked.trim();
    return '${d.substring(0, 3)}-${d.substring(3, 5)}-${d.substring(5)}';
  }

  void _populateControllers(Patient data) {
    nameController.text = data.name;
    emailController.text = data.email;
    phoneController.text = data.phone ?? '';
    birthDateController.text = ResidenceDateFormat.formatDate(
      data.birthDate,
      data.residenceCountry,
    );
    if (patientShowsUsSocialSecurity(data)) {
      final ssn = data.socialSecurityNumber?.trim();
      cpfController.text = (ssn != null && ssn.isNotEmpty)
          ? ProfileController.formatSsnDisplay(ssn)
          : '';
      rgController.text = '';
    } else {
      cpfController.text = data.cpf;
      rgController.text = data.rg;
    }
    emergencyContactController.text = data.emergencyContact ?? '';
    emergencyPhoneController.text = data.emergencyPhone ?? '';
  }

  // Seleciona foto da galeria
  Future<void> selectPhotoFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        _profilePhoto.value = image.path;
        await _saveProfilePhoto(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_photo'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Tira foto com a câmera
  Future<void> takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        _profilePhoto.value = image.path;
        await _saveProfilePhoto(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_camera'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Salva a foto do perfil
  Future<void> _saveProfilePhoto(String photoPath) async {
    final currentPatient = _patient.value;
    if (currentPatient == null) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_user'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Converter a foto para base64
      final base64Photo = await _convertImageToBase64(photoPath);
      
      // Atualiza o estado local PRIMEIRO para refletir as mudanças imediatamente
      final updatedPatient = Patient(
        id: currentPatient.id,
        name: currentPatient.name,
        email: currentPatient.email,
        password: currentPatient.password,
        phone: currentPatient.phone,
        secondaryPhone: currentPatient.secondaryPhone,
        birthDate: currentPatient.birthDate,
        cpf: currentPatient.cpf,
        rg: currentPatient.rg,
        gender: currentPatient.gender,
        maritalStatus: currentPatient.maritalStatus,
        nationality: currentPatient.nationality,
        residenceCountry: currentPatient.residenceCountry,
        socialSecurityNumber: currentPatient.socialSecurityNumber,
        address: currentPatient.address,
        height: currentPatient.height,
        weight: currentPatient.weight,
        profession: currentPatient.profession,
        acceptedTerms: currentPatient.acceptedTerms,
        profilePhoto: base64Photo, // Salvar como base64
        emergencyContact: currentPatient.emergencyContact,
        emergencyPhone: currentPatient.emergencyPhone,
        fcmToken: currentPatient.fcmToken,
        isAdmin: currentPatient.isAdmin,
        twoFactorCode: currentPatient.twoFactorCode,
        twoFactorExpires: currentPatient.twoFactorExpires,
        passwordResetCode: currentPatient.passwordResetCode,
        passwordResetExpires: currentPatient.passwordResetExpires,
        passwordResetRequired: currentPatient.passwordResetRequired,
        createdAt: currentPatient.createdAt,
        updatedAt: DateTime.now(),
      );

      _patient.value = updatedPatient;
      _authService.currentUser = updatedPatient;

      // Atualiza no banco de dados em background
      _updatePhotoInBackground(currentPatient.id!, base64Photo);

      Get.snackbar(
        'profile_success'.tr,
        'profile_success_photo'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_process_photo'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Converte imagem para base64
  Future<String> _convertImageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      rethrow;
    }
  }

  // Atualiza a foto no banco de dados em background
  Future<void> _updatePhotoInBackground(String patientId, String photoBase64) async {
    try {
      await _databaseService.updatePatientField(patientId, 'profilePhoto', photoBase64);
    } catch (e) {
      // Não mostra erro para o usuário pois a foto já foi atualizada localmente
    }
  }

  // Salva as alterações do paciente
  Future<void> savePatientData() async {
    _isSaving.value = true;

    final currentPatient = _patient.value;
    if (currentPatient == null) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_user'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _isSaving.value = false;
      return;
    }

    // Validações básicas
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_name'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _isSaving.value = false;
      return;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_email'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _isSaving.value = false;
      return;
    }

    final isUs = patientShowsUsSocialSecurity(currentPatient);

    // Cria o paciente atualizado
    final updatedPatient = Patient(
      id: currentPatient.id,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: currentPatient.password,
      phone: phoneController.text.trim().isEmpty ? '' : phoneController.text.trim(),
      secondaryPhone: currentPatient.secondaryPhone,
      birthDate: currentPatient.birthDate,
      cpf: isUs
          ? currentPatient.cpf
          : (cpfController.text.trim().isEmpty ? '' : cpfController.text.trim()),
      rg: isUs
          ? currentPatient.rg
          : (rgController.text.trim().isEmpty ? '' : rgController.text.trim()),
      gender: currentPatient.gender,
      maritalStatus: currentPatient.maritalStatus,
      nationality: currentPatient.nationality,
      residenceCountry: currentPatient.residenceCountry,
      socialSecurityNumber: currentPatient.socialSecurityNumber,
      address: currentPatient.address,
      height: currentPatient.height,
      weight: currentPatient.weight,
      profession: currentPatient.profession,
      acceptedTerms: currentPatient.acceptedTerms,
      profilePhoto: _profilePhoto.value ?? currentPatient.profilePhoto,
      emergencyContact: emergencyContactController.text.trim().isEmpty ? null : emergencyContactController.text.trim(),
      emergencyPhone: emergencyPhoneController.text.trim().isEmpty ? null : emergencyPhoneController.text.trim(),
      fcmToken: currentPatient.fcmToken,
      isAdmin: currentPatient.isAdmin,
      twoFactorCode: currentPatient.twoFactorCode,
      twoFactorExpires: currentPatient.twoFactorExpires,
      passwordResetCode: currentPatient.passwordResetCode,
      passwordResetExpires: currentPatient.passwordResetExpires,
      passwordResetRequired: currentPatient.passwordResetRequired,
      createdAt: currentPatient.createdAt,
      updatedAt: DateTime.now(),
    );

    // Atualiza o estado local PRIMEIRO para refletir as mudanças imediatamente
    _patient.value = updatedPatient;
    _authService.currentUser = updatedPatient;
    _profilePhoto.value = updatedPatient.profilePhoto;
    _populateControllers(updatedPatient);
    _isEditing.value = false;

    // Atualiza no banco de dados em background (sem bloquear a UI)
    _updateDatabaseInBackground(currentPatient.id!, updatedPatient);

    // Cria notificação de perfil atualizado
    try {
      final apiService = ApiService();
      await apiService.criarNotificacaoPerfilAtualizado();
    } catch (e) {
    }

    Get.snackbar(
      'profile_success'.tr,
      'profile_success_updated'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    _isSaving.value = false;
  }

  // Atualiza o banco de dados em background
  Future<void> _updateDatabaseInBackground(String patientId, Patient updatedPatient) async {
    try {
      
      // Atualiza campos individuais
      await _databaseService.updatePatientField(patientId, 'name', updatedPatient.name);
      await _databaseService.updatePatientField(patientId, 'email', updatedPatient.email);
      await _databaseService.updatePatientField(patientId, 'phone', updatedPatient.phone);
      await _databaseService.updatePatientField(patientId, 'cpf', updatedPatient.cpf);
      await _databaseService.updatePatientField(patientId, 'rg', updatedPatient.rg);
      await _databaseService.updatePatientField(patientId, 'emergencyContact', updatedPatient.emergencyContact);
      await _databaseService.updatePatientField(patientId, 'emergencyPhone', updatedPatient.emergencyPhone);
      
      if (updatedPatient.profilePhoto != null) {
        await _databaseService.updatePatientField(patientId, 'profilePhoto', updatedPatient.profilePhoto);
      }
      
    } catch (e) {
      // Não mostra erro para o usuário pois os dados já foram atualizados localmente
    }
  }

  // Solicita acesso aos dados de saúde
  Future<void> requestHealthDataAccess() async {
    try {
      _isRequestingHealthPermissions.value = true;

      await _healthService.setAppleHealthInAppEnabled(true);

      // Solicita permissões reais do HealthKit
      final granted = await _healthService.requestPermissions();
      
      if (granted) {
        _healthDataAccessGranted.value = true;

        // Carrega dados reais do HealthKit
        await _loadHealthData();

        Get.snackbar(
          'profile_success'.tr,
          'profile_success_health_granted'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        if (Platform.isAndroid) {
          await _healthService.setAppleHealthInAppEnabled(false);
        }
        _healthDataAccessGranted.value = false;
        Get.snackbar(
          'profile_permission_denied'.tr,
          'profile_permission_health'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        'profile_error_health_request'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isRequestingHealthPermissions.value = false;
    }
  }

  // Carrega dados de saúde do HealthKit
  Future<void> _loadHealthData() async {
    try {
      print('📱 [ProfileController] Iniciando carregamento de dados do HealthKit...');

      if (!await _healthService.isAppleHealthInAppEnabled()) {
        print('📱 [ProfileController] Integração Apple Health desligada no app.');
        await _loadHealthDataFromDatabase();
        return;
      }

      // No iOS, hasPermissions para READ é indeterminado no HealthKit — não usar como bloqueio.
      if (!Platform.isIOS) {
        final hasPermissions = await _healthService.hasPermissions();
        print('📱 [ProfileController] Permissões: $hasPermissions');

        if (!hasPermissions) {
          print('📱 [ProfileController] Solicitando permissões...');
          final granted = await _healthService.requestPermissions();
          if (!granted) {
            print('⚠️ [ProfileController] Permissões negadas pelo utilizador');
          }
        }
      }

      // Busca dados reais do HealthKit
      print('📱 [ProfileController] Buscando dados do HealthKit...');
      final healthData = await _healthService.getAllHealthData();
      
      print('📱 [ProfileController] Dados recebidos:');
      print('  - HeartRate: ${healthData['heartRate']?.length ?? 0} pontos');
      print('  - Sleep: ${healthData['sleep']?.length ?? 0} pontos');
      print('  - Steps: ${healthData['steps']?.length ?? 0} pontos');
      
      // Extrai dados de frequência cardíaca (último valor = mais recente)
      if (healthData['heartRate'] != null && healthData['heartRate']!.isNotEmpty) {
        final lastHeartRate = healthData['heartRate']!.last.y;
        print('📱 [ProfileController] Última frequência cardíaca: $lastHeartRate bpm');
        _heartRate.value = lastHeartRate;
      } else {
        print('⚠️ [ProfileController] Nenhum dado de frequência cardíaca encontrado');
      }
      
      // Extrai dados de sono (último valor = mais recente)
      if (healthData['sleep'] != null && healthData['sleep']!.isNotEmpty) {
        final lastSleep = healthData['sleep']!.last.y;
        print('📱 [ProfileController] Últimas horas de sono: $lastSleep horas');
        _sleepQuality.value = lastSleep * 10; // Converte horas para percentual (assumindo 10h = 100%)
      } else {
        print('⚠️ [ProfileController] Nenhum dado de sono encontrado');
      }
      
      // Extrai dados de passos (último valor = mais recente)
      if (healthData['steps'] != null && healthData['steps']!.isNotEmpty) {
        final lastSteps = healthData['steps']!.last.y;
        print('📱 [ProfileController] Últimos passos: $lastSteps');
        _dailySteps.value = lastSteps.round();
      } else {
        print('⚠️ [ProfileController] Nenhum dado de passos encontrado');
      }
      
      print('📱 [ProfileController] Valores finais:');
      print('  - HeartRate: ${_heartRate.value} bpm');
      print('  - Sleep: ${_sleepQuality.value}%');
      print('  - Steps: ${_dailySteps.value}');
      
      // Salva dados no banco de dados
      if (_patient.value != null) {
        try {
          print('📱 [ProfileController] Salvando dados no banco...');
          await _healthDataService.saveHealthDataFromHealthKit(_patient.value!.id!);
          print('✅ [ProfileController] Dados salvos com sucesso');
        } catch (e) {
          print('❌ [ProfileController] Erro ao salvar dados no banco: $e');
          // Não falha o carregamento se não conseguir salvar no banco
        }
      } else {
        print('⚠️ [ProfileController] Paciente não encontrado, não é possível salvar dados');
      }
      
    } catch (e, stackTrace) {
      print('❌ [ProfileController] Erro ao carregar dados do HealthKit: $e');
      print('❌ [ProfileController] Stack trace: $stackTrace');
      // Em caso de erro, usa dados simulados
      _heartRate.value = 72.0;
      _sleepQuality.value = 85.0;
      _dailySteps.value = 8500;
    }
  }

  // Conecta ao Samsung Health (placeholder)
  Future<void> connectToSamsungHealth() async {
    Get.snackbar(
      'profile_coming_soon'.tr,
      'profile_samsung_coming'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // Desconecta do Apple Health (desliga leitura no app; no Android revoga Health Connect)
  Future<void> disconnectFromAppleHealth() async {
    try {
      await _healthService.setAppleHealthInAppEnabled(false);
      await _healthService.revokeOsHealthPermissionsIfAndroid();

      _healthDataAccessGranted.value = false;
      _heartRate.value = 0.0;
      _sleepQuality.value = 0.0;
      _dailySteps.value = 0;

      await _loadHealthDataFromDatabase();

      final iosHint = 'profile_apple_health_disconnect_ios_hint'.tr;
      final androidHint = 'profile_apple_health_disconnect_android_hint'.tr;

      Get.snackbar(
        'profile_disconnected'.tr,
        Platform.isIOS ? iosHint : androidHint,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: const Color(0xFF1E293B),
        duration: const Duration(seconds: 8),
        margin: const EdgeInsets.all(12),
        mainButton: TextButton(
          onPressed: () async {
            await openAppSettings();
          },
          child: Text(
            'profile_open_settings'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF00324A),
            ),
          ),
        ),
      );
    } catch (e) {
      _healthDataAccessGranted.value = false;
      Get.snackbar(
        'auth_error'.tr,
        '${'profile_error_health_request'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: const Color(0xFF1E293B),
      );
    }
  }

  // Sincroniza dados de saúde
  Future<void> syncHealthData() async {
    try {
      if (_patient.value == null) {
        Get.snackbar(
          'auth_error'.tr,
          'profile_error_user'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (!await _healthService.isAppleHealthInAppEnabled()) {
        Get.snackbar(
          'profile_warning'.tr,
          'profile_apple_health_sync_off'.tr,
          backgroundColor: Colors.orange.shade100,
          colorText: const Color(0xFF1E293B),
        );
        return;
      }

      _isRequestingHealthPermissions.value = true;

      // No iOS, hasPermissions com leitura devolve indeterminado no plugin; não bloquear sync aqui.
      if (Platform.isIOS) {
        await _healthService.requestPermissions();
      } else {
        var ok = await _healthService.hasPermissions();
        if (!ok) {
          ok = await _healthService.requestPermissions();
        }
        if (!ok) {
          Get.snackbar(
            'profile_permission_needed'.tr,
            'profile_permission_required'.tr,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }

      // Sincroniza dados (salva dados do HealthKit no banco)
      await _healthDataService.saveHealthDataFromHealthKit(_patient.value!.id!);
      
      // Recarrega dados
      await _loadHealthData();
      
      Get.snackbar(
        'profile_success'.tr,
        'profile_sync_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        '${'profile_error_sync'.tr}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isRequestingHealthPermissions.value = false;
    }
  }


  // Testa a integração com dados de saúde
  Future<void> testHealthDataIntegration() async {
    try {
      if (_patient.value == null) {
        Get.snackbar(
          'auth_error'.tr,
          'profile_error_user'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (!await _healthService.isAppleHealthInAppEnabled()) {
        Get.snackbar(
          'profile_warning'.tr,
          'profile_apple_health_sync_off'.tr,
          backgroundColor: Colors.orange.shade100,
          colorText: const Color(0xFF1E293B),
        );
        return;
      }

      _isRequestingHealthPermissions.value = true;
      
      Get.snackbar(
        'profile_test'.tr,
        'profile_test_start'.tr,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      
      // Executa todos os testes
      await _healthDataTestService.runAllTests(_patient.value!.id!);
      
      Get.snackbar(
        'profile_success'.tr,
        'profile_test_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } catch (e) {
      Get.snackbar(
        'auth_error'.tr,
        '${'profile_test_error'.tr}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isRequestingHealthPermissions.value = false;
    }
  }

  // Desconecta do Samsung Health (placeholder)
  Future<void> disconnectFromSamsungHealth() async {
    Get.snackbar(
      'profile_coming_soon'.tr,
      'profile_samsung_coming'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
}
