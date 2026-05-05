import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_icon_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
    return GetBuilder<LoginController>(
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
          Expanded(
            flex: 1,
            child: _buildLogoSection(context, size),
          ),
          Expanded(
            flex: 1,
            child: _buildFormSection(context, isLandscape, size),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildLogoSection(context, size),
          ),
          Expanded(
            flex: 5,
            child: _buildFormSection(context, isLandscape, size),
          ),
        ],
      );
    }
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
        Positioned(
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
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
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
                    _buildWelcomeText(),
                    SizedBox(height: isLandscape ? 24 : size.height * 0.03),
                    _buildEmailField(size),
                    const SizedBox(height: 16),
                    _buildPasswordField(size),
                    const SizedBox(height: 12),
                    _buildRememberMeAndForgotPassword(size),
                    const SizedBox(height: 24),
                    _buildLoginButton(size),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildRegisterButton(size),
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

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth_welcome'.tr,
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
          'auth_enter_to_continue'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmailField(Size size) {
    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    return TextFormField(
      controller: Get.find<LoginController>().emailController,
      keyboardType: TextInputType.emailAddress,
      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'auth_email'.tr,
        labelStyle: AppTheme.bodyMedium,
        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
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
          return 'auth_email_required'.tr;
        }
        if (!GetUtils.isEmail(value)) {
          return 'auth_email_invalid'.tr;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(Size size) {
    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    return Obx(() => TextFormField(
          controller: Get.find<LoginController>().passwordController,
          obscureText: Get.find<LoginController>().obscurePassword.value,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'auth_password'.tr,
            labelStyle: AppTheme.bodyMedium,
            prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
            suffixIcon: IconButton(
              icon: Icon(
                Get.find<LoginController>().obscurePassword.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: Get.find<LoginController>().togglePasswordVisibility,
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

  Widget _buildRememberMeAndForgotPassword(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Obx(() => Checkbox(
                    value: Get.find<LoginController>().rememberMe.value,
                    onChanged: (value) async {
                      Get.find<LoginController>().rememberMe.value = value ?? false;
                      if (value == true) {
                        await Get.find<LoginController>().saveCredentials();
                      } else {
                        await Get.find<LoginController>().clearSavedCredentials();
                      }
                    },
                    activeColor: AppTheme.primaryBlue,
                    checkColor: Colors.white,
                    side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.45)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )),
              Flexible(
                child: Text(
                  'auth_remember_me'.tr,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Get.toNamed('/forgot-password'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'auth_forgot_password'.tr,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(Size size) {
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
            onPressed: Get.find<LoginController>().isLoading.value
                ? null
                : () {
                    if (!_formKey.currentState!.validate()) return;
                    Get.find<LoginController>().login();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Get.find<LoginController>().isLoading.value
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
                      const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'auth_login'.tr,
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'auth_or'.tr,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1, height: 1)),
      ],
    );
  }

  Widget _buildRegisterButton(Size size) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Get.toNamed('/registration'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'auth_create_account'.tr,
          style: AppTheme.titleSmall.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
