import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../utils/controller_mixin.dart';

class ForgotPasswordController extends GetxController with SafeControllerMixin {
  final AuthService _authService = Get.find<AuthService>();
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Adicionar controller ao gerenciamento seguro
    addController(emailController);
    // Limpar controller de forma segura
    clearControllers();
  }

  Future<void> sendResetCode() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      
      final email = emailController.text.trim();
      
      // Verificar se o e-mail existe no sistema
      final patient = await _authService.checkEmailExists(email);
      if (patient == null) {
        Get.snackbar(
          'forgot_email_not_found_title'.tr,
          'forgot_email_not_found_msg'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Gerar e enviar código de redefinição
      await _authService.sendPasswordResetCode(email);
      
      Get.snackbar(
        'forgot_code_sent_title'.tr,
        'forgot_code_sent_msg'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Navegar para tela de redefinição de senha
      Get.toNamed('/reset-password', arguments: {'email': email});
      
    } catch (e) {
      Get.snackbar(
        'forgot_error_title'.tr,
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 