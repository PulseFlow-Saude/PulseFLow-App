import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_theme.dart';
import '../../widgets/language_icon_button.dart';
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
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return GetBuilder<ResetPasswordController>(
      init: ResetPasswordController(),
      builder: (controller) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue,
                  const Color(0xFF001F2E),
                  AppTheme.primaryBlue.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(context, isLandscape, size),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isLandscape, Size size) {
    if (isLandscape) {
      return Row(
        children: [
          Expanded(flex: 1, child: _buildLogoSection(context, size)),
          Expanded(flex: 1, child: _buildFormSection(context, isLandscape, size)),
        ],
      );
    }
    return Column(
      children: [
        Expanded(flex: 2, child: _buildLogoSection(context, size)),
        Expanded(flex: 5, child: _buildFormSection(context, isLandscape, size)),
      ],
    );
  }

  Widget _buildLogoSection(BuildContext context, Size size) {
    final logoDim = math.min(size.shortestSide * 0.42, 200.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Image.asset(
            'assets/images/oryon_health_logo_signin.png',
            width: logoDim,
            height: logoDim,
            fit: BoxFit.contain,
          ),
        ),
        const Positioned(
          top: 4,
          right: 4,
          child: LanguageIconButton(),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, bool isLandscape, Size size) {
    final mq = MediaQuery.of(context);
    final bottomPad = math.max(mq.viewInsets.bottom, mq.padding.bottom) + 24;
    final horizontalPad = math.max(20.0, size.width * 0.07);

    final borderRadius = isLandscape
        ? const BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          );

    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    final c = Get.find<ResetPasswordController>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 28, horizontalPad, bottomPad),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isLandscape) const SizedBox(height: 8),
                    _buildHeader(),
                    SizedBox(height: isLandscape ? 24 : size.height * 0.03),
                    _buildCodeField(c, borderColor),
                    const SizedBox(height: 16),
                    _buildNewPasswordField(c, borderColor),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(c, borderColor),
                    const SizedBox(height: 24),
                    _buildResetPasswordButton(c),
                    const SizedBox(height: 16),
                    _buildResendCodeButton(c),
                    const SizedBox(height: 16),
                    _buildBackButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth_new_password'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.titleLarge.copyWith(color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlue.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'auth_new_password_hint'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCodeField(ResetPasswordController c, Color borderColor) {
    return TextFormField(
      controller: c.codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'auth_verification_code'.tr,
        hintText: 'auth_code_hint'.tr,
        labelStyle: AppTheme.bodyMedium,
        prefixIcon: Icon(Icons.verified_user_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.85)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.95), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth_code_required'.tr;
        }
        if (value.length != 6) {
          return 'auth_code_6_digits'.tr;
        }
        return null;
      },
    );
  }

  Widget _buildNewPasswordField(ResetPasswordController c, Color borderColor) {
    return Obx(() => TextFormField(
          controller: c.newPasswordController,
          obscureText: c.obscurePassword.value,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'auth_new_password'.tr,
            hintText: 'auth_new_password_placeholder'.tr,
            labelStyle: AppTheme.bodyMedium,
            prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
            suffixIcon: IconButton(
              icon: Icon(
                c.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: c.togglePasswordVisibility,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.85)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.95), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'auth_password_required'.tr;
            }
            if (value.length < 6) {
              return 'auth_password_min'.tr;
            }
            return null;
          },
        ));
  }

  Widget _buildConfirmPasswordField(ResetPasswordController c, Color borderColor) {
    return Obx(() => TextFormField(
          controller: c.confirmPasswordController,
          obscureText: c.obscureConfirmPassword.value,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'auth_confirm_password'.tr,
            hintText: 'auth_confirm_password_hint'.tr,
            labelStyle: AppTheme.bodyMedium,
            prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
            suffixIcon: IconButton(
              icon: Icon(
                c.obscureConfirmPassword.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: c.toggleConfirmPasswordVisibility,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.85)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.95), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'auth_password_confirm_required'.tr;
            }
            if (value != c.newPasswordController.text) {
              return 'auth_passwords_dont_match'.tr;
            }
            return null;
          },
        ));
  }

  Widget _buildResetPasswordButton(ResetPasswordController c) {
    return Obx(() => Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withValues(alpha: 0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: c.isLoading.value ? null : c.resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: c.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'auth_reset_btn'.tr,
                        style: AppTheme.titleSmall.copyWith(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

  Widget _buildResendCodeButton(ResetPasswordController c) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: c.isResending.value ? null : c.resendCode,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: c.isResending.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        c.isResending.value ? 'auth_resending'.tr : 'auth_resend'.tr,
                        style: AppTheme.titleSmall.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_rounded, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(
              'auth_back'.tr,
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
