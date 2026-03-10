import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'reset_password_controller.dart';
import '../../widgets/language_icon_button.dart';

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
      final isSmallHeight = size.height < 700;
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: isSmallHeight ? 3 : 2,
            child: _buildLogoSection(size),
          ),
          Expanded(
            flex: isSmallHeight ? 5 : 4,
            child: _buildFormSection(size),
          ),
        ],
      );
    }
  }

  Widget _buildLogoSection(Size size) {
    final isSmallHeight = size.height < 700;
    final logoSize = isSmallHeight
        ? (size.width * 0.22).clamp(50.0, 90.0)
        : (size.width * 0.35).clamp(80.0, 140.0);
    final spacing = isSmallHeight ? 6.0 : size.height * 0.015;
    final titleFontSize = isSmallHeight
        ? (size.width * 0.045).clamp(16.0, 22.0)
        : (size.width * 0.05).clamp(18.0, 28.0);
    final hintFontSize = isSmallHeight
        ? (size.width * 0.032).clamp(11.0, 14.0)
        : (size.width * 0.035).clamp(12.0, 16.0);

<<<<<<< Updated upstream
    return Stack(
      children: [
        Center(
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
              ],
            ),
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: LanguageIconButton(),
        ),
      ],
=======
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(size.width * 0.06, 16, size.width * 0.06, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/pulseflow2.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: spacing),
            Text(
              'auth_reset_title'.tr,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'auth_reset_hint'.tr,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: hintFontSize,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          'reset_logo_title'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: isSmallHeight ? 6 : 10),
        Text(
          'reset_header_title'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
=======
                                    'auth_new_password'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
>>>>>>> Stashed changes
            fontSize: isSmallHeight ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00324A),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallHeight ? 4 : 8),
        Text(
<<<<<<< Updated upstream
          'reset_header_subtitle'.tr,
=======
          'auth_new_password_hint'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          labelText: 'reset_code_label'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'reset_code_hint'.tr,
=======
          labelText: 'auth_verification_code'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'auth_code_hint'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'reset_code_required'.tr;
          }
          if (value.length != 6) {
            return 'reset_code_digits'.tr;
          }
          return null;
        },
=======
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'auth_code_required'.tr;
                                        }
                                        if (value.length != 6) {
                                          return 'auth_code_6_digits'.tr;
                                        }
                                        return null;
                                      },
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          labelText: 'reset_new_password'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'reset_new_password_hint'.tr,
=======
          labelText: 'auth_new_password'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'auth_new_password_placeholder'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            return 'reset_new_password_required'.tr;
          }
          if (value.length < 6) {
            return 'reset_new_password_min'.tr;
=======
            return 'auth_password_required'.tr;
          }
          if (value.length < 6) {
            return 'auth_password_min'.tr;
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          labelText: 'reset_confirm_label'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'reset_confirm_hint'.tr,
=======
          labelText: 'auth_confirm_password'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'auth_confirm_password_hint'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            return 'reset_confirm_required'.tr;
          }
          if (value != Get.find<ResetPasswordController>().newPasswordController.text) {
            return 'reset_passwords_match'.tr;
=======
            return 'auth_password_confirm_required'.tr;
          }
          if (value != Get.find<ResetPasswordController>().newPasswordController.text) {
            return 'auth_passwords_dont_match'.tr;
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                    'reset_btn'.tr,
=======
                    'auth_reset_title'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
              ? 'reset_resending'.tr
              : 'reset_resend_code'.tr,
=======
              ? 'auth_resending'.tr
              : 'auth_resend'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
              'reset_back'.tr,
=======
              'auth_back'.tr,
>>>>>>> Stashed changes
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