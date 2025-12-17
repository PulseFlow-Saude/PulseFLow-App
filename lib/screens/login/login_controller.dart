import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/auth_service.dart';
import '../../utils/controller_mixin.dart';
import 'paciente_controller.dart'; // Ajuste conforme o caminho


class LoginController extends GetxController with SafeControllerMixin {
  final AuthService _authService = Get.find<AuthService>();
  final _storage = const FlutterSecureStorage();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Adicionar controllers ao gerenciamento seguro
    addControllers([emailController, passwordController]);
    // Limpar controllers de forma segura
    clearControllers();
    // Carregar credenciais salvas
    _loadSavedCredentials();
  }

  // Carrega credenciais salvas se "Lembrar-me" estiver ativo
  Future<void> _loadSavedCredentials() async {
    try {
      final savedRememberMe = await _storage.read(key: 'remember_me');
      if (savedRememberMe == 'true') {
        rememberMe.value = true;
        
        final savedEmail = await _storage.read(key: 'saved_email');
        final savedPassword = await _storage.read(key: 'saved_password');
        
        if (savedEmail != null && savedPassword != null) {
          emailController.text = savedEmail;
          passwordController.text = savedPassword;
        }
      }
    } catch (e) {
      // Silenciosamente falha se não conseguir carregar
    }
  }

  // Salva credenciais se "Lembrar-me" estiver ativo
  Future<void> saveCredentials() async {
    try {
      if (rememberMe.value) {
        await _storage.write(key: 'remember_me', value: 'true');
        await _storage.write(key: 'saved_email', value: emailController.text.trim());
        await _storage.write(key: 'saved_password', value: passwordController.text);
      } else {
        // Remove credenciais salvas se "Lembrar-me" estiver desativado
        await _storage.delete(key: 'remember_me');
        await _storage.delete(key: 'saved_email');
        await _storage.delete(key: 'saved_password');
      }
    } catch (e) {
      // Silenciosamente falha se não conseguir salvar
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {

    try {
      isLoading.value = true;
      
      // Salvar credenciais se "Lembrar-me" estiver ativo
      await saveCredentials();
      
      // Novo fluxo: login inicial, gera e envia código 2FA
      final patientId = await _authService.loginWith2FA(
        emailController.text.trim(),
        passwordController.text,
      );
      
      // Verifica se o usuário é admin (não precisa de 2FA)
      final patient = await _authService.getPatientById(patientId);
      // Salva no controller global
      final pacienteController = Get.find<PacienteController>();
       pacienteController.setPatientId(patientId);
      if (patient != null && patient.isAdmin) {
        // Usuário admin: finaliza login diretamente
        await _authService.verify2FACode(patientId, ''); // código vazio para admin
        // Redirecionar para tela home
        Get.offAllNamed('/home');
      } else {
        // Usuário normal: redireciona direto para verificação 2FA
        Get.toNamed('/verify-2fa', arguments: {'patientId': patientId, 'method': 'email'});
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Limpa credenciais salvas (útil para logout)
  Future<void> clearSavedCredentials() async {
    try {
      await _storage.delete(key: 'remember_me');
      await _storage.delete(key: 'saved_email');
      await _storage.delete(key: 'saved_password');
      rememberMe.value = false;
    } catch (e) {
      // Silenciosamente falha se não conseguir limpar
    }
  }
} 

