import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'reset_password_controller.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return GetBuilder<ResetPasswordController>(
      init: ResetPasswordController(),
      builder: (controller) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00324A),
                  const Color(0xFF00324A).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(isLandscape, size),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isLandscape, Size size) {
    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildLogoSection(size),
          ),
          Expanded(
            flex: 1,
            child: _buildFormSection(size),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 1,
            child: _buildLogoSection(size),
          ),
          Expanded(
            flex: 4,
            child: _buildFormSection(size),
          ),
        ],
      );
    }
  }

  Widget _buildLogoSection(Size size) {
    final isSmallHeight = size.height < 700;
    final logoSize = isSmallHeight
        ? (size.width * 0.25).clamp(60.0, 100.0)
        : (size.width * 0.35).clamp(80.0, 140.0);
    final spacing = isSmallHeight ? 4.0 : size.height * 0.015;

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/pulseflow2.png',
              width: logoSize,
              height: logoSize,
                          fit: BoxFit.contain,
                        ),
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Text(
                          'Redefinir Senha',
                textAlign: TextAlign.center,
                maxLines: 2,
                          style: TextStyle(
                  fontSize: (size.width * 0.05).clamp(18.0, 28.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.visible,
                          ),
                        ),
            SizedBox(height: spacing * 0.5),
                        Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                          child: Text(
                            'Digite o código recebido e sua nova senha',
                            textAlign: TextAlign.center,
                maxLines: 2,
                            style: TextStyle(
                  fontSize: (size.width * 0.035).clamp(12.0, 16.0),
                              color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                            ),
                overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
    );
  }

  Widget _buildFormSection(Size size) {
    final isSmallHeight = size.height < 700;
    final paddingVertical = isSmallHeight ? 16.0 : 24.0;
    final spacing = isSmallHeight ? 8.0 : 12.0;
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
      child: Form(
        key: Get.find<ResetPasswordController>().formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: paddingVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: isSmallHeight ? 1 : 2,
                child: SizedBox.shrink(),
              ),
              _buildHeader(size),
              SizedBox(height: spacing),
              _buildCodeField(size),
              SizedBox(height: spacing),
              _buildNewPasswordField(size),
              SizedBox(height: spacing),
              _buildConfirmPasswordField(size),
              SizedBox(height: spacing * 1.5),
              _buildResetPasswordButton(size),
              SizedBox(height: spacing),
              _buildResendCodeButton(size),
              SizedBox(height: spacing),
              _buildBackButton(size),
              Flexible(
                flex: isSmallHeight ? 1 : 2,
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
                              children: [
        Text(
                                    'Nova Senha',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
            fontSize: isSmallHeight ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00324A),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallHeight ? 4 : 8),
        Text(
          'Digite o código e defina sua nova senha',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: isSmallHeight ? 13 : 16,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Container(
      height: isSmallHeight ? 50 : 54,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: Get.find<ResetPasswordController>().codeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
        style: TextStyle(
          fontSize: isSmallHeight ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Código de Verificação',
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'Digite o código de 6 dígitos',
          prefixIcon: Icon(Icons.security, color: const Color(0xFF00324A)),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallHeight ? 12 : 16,
          ),
          counterText: '',
        ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, digite o código';
                                        }
                                        if (value.length != 6) {
                                          return 'O código deve ter 6 dígitos';
                                        }
                                        return null;
                                      },
      ),
    );
  }

  Widget _buildNewPasswordField(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Obx(() => Container(
      height: isSmallHeight ? 50 : 54,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: Get.find<ResetPasswordController>().newPasswordController,
        obscureText: Get.find<ResetPasswordController>().obscurePassword.value,
        style: TextStyle(
          fontSize: isSmallHeight ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Nova Senha',
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'Digite sua nova senha',
          prefixIcon: Icon(Icons.lock_outlined, color: const Color(0xFF00324A)),
          suffixIcon: IconButton(
            icon: Icon(
              Get.find<ResetPasswordController>().obscurePassword.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            color: Colors.grey[600],
            ),
            onPressed: Get.find<ResetPasswordController>().togglePasswordVisibility,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallHeight ? 12 : 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, digite a nova senha';
          }
          if (value.length < 6) {
            return 'A senha deve ter pelo menos 6 caracteres';
          }
          return null;
        },
      ),
    ));
  }

  Widget _buildConfirmPasswordField(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Obx(() => Container(
      height: isSmallHeight ? 50 : 54,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: Get.find<ResetPasswordController>().confirmPasswordController,
        obscureText: Get.find<ResetPasswordController>().obscureConfirmPassword.value,
        style: TextStyle(
          fontSize: isSmallHeight ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Confirmar Nova Senha',
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'Confirme sua nova senha',
          prefixIcon: Icon(Icons.lock_outlined, color: const Color(0xFF00324A)),
          suffixIcon: IconButton(
            icon: Icon(
              Get.find<ResetPasswordController>().obscureConfirmPassword.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            color: Colors.grey[600],
            ),
            onPressed: Get.find<ResetPasswordController>().toggleConfirmPasswordVisibility,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF00324A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallHeight ? 12 : 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, confirme a nova senha';
          }
          if (value != Get.find<ResetPasswordController>().newPasswordController.text) {
            return 'As senhas não coincidem';
          }
          return null;
        },
      ),
    ));
  }

  Widget _buildResetPasswordButton(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Obx(() => Container(
      width: double.infinity,
      height: isSmallHeight ? 48 : 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00324A),
            const Color(0xFF00324A).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00324A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: Get.find<ResetPasswordController>().isLoading.value
            ? null
            : Get.find<ResetPasswordController>().resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Get.find<ResetPasswordController>().isLoading.value
            ? SizedBox(
                width: isSmallHeight ? 20 : 24,
                height: isSmallHeight ? 20 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset, color: Colors.white, size: isSmallHeight ? 18 : 20),
                  SizedBox(width: 8),
                  Text(
                    'Redefinir Senha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallHeight ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    ));
  }

  Widget _buildResendCodeButton(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Obx(() => Container(
      width: double.infinity,
      height: isSmallHeight ? 48 : 54,
      child: OutlinedButton.icon(
        onPressed: Get.find<ResetPasswordController>().isResending.value
            ? null
            : Get.find<ResetPasswordController>().resendCode,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF00324A), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Get.find<ResetPasswordController>().isResending.value
            ? SizedBox(
                width: isSmallHeight ? 18 : 20,
                height: isSmallHeight ? 18 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00324A)),
                ),
              )
            : Icon(Icons.refresh, color: const Color(0xFF00324A), size: isSmallHeight ? 18 : 20),
        label: Text(
          Get.find<ResetPasswordController>().isResending.value
              ? 'Reenviando...'
              : 'Reenviar código',
          style: TextStyle(
            color: const Color(0xFF00324A),
            fontSize: isSmallHeight ? 14 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ));
  }

  Widget _buildBackButton(Size size) {
    final isSmallHeight = size.height < 700;
    
    return Container(
      width: double.infinity,
      height: isSmallHeight ? 48 : 54,
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF00324A), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, color: const Color(0xFF00324A), size: isSmallHeight ? 18 : 20),
            SizedBox(width: 8),
            Text(
              'Voltar',
              style: TextStyle(
                color: const Color(0xFF00324A),
                fontSize: isSmallHeight ? 14 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}