import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../utils/controller_mixin.dart';

class ResetPasswordController extends GetxController with SafeControllerMixin {
  final AuthService _authService = Get.find<AuthService>();
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final isLoading = false.obs;
  final isResending = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  
  String? email;

  @override
  void onInit() {
    super.onInit();
    // Pegar o e-mail passado como argumento
    email = Get.arguments?['email'] as String?;
    if (email == null) {
      Get.back();
      return;
    }
    
    // Adicionar controllers ao gerenciamento seguro
    addControllers([codeController, newPasswordController, confirmPasswordController]);
    // Limpar controllers de forma segura
    clearControllers();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      
      final code = codeController.text.trim();
      final newPassword = newPasswordController.text;
      
      // Redefinir senha
      await _authService.resetPassword(email!, code, newPassword);
      
      Get.snackbar(
        'Senha redefinida!',
        'Sua senha foi alterada com sucesso.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Voltar para tela de login
      Get.offAllNamed('/login');
      
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

  Future<void> resendCode() async {
    if (email == null) return;

    try {
      isResending.value = true;
      
      // Reenviar código de redefinição
      await _authService.sendPasswordResetCode(email!);
      
      Get.snackbar(
        'Código reenviado!',
        'Verifique seu e-mail novamente.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isResending.value = false;
    }
  }
} 