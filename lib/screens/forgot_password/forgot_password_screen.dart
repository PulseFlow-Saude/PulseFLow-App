import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'forgot_password_controller.dart';
import '../../widgets/language_icon_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
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

    return GetBuilder<ForgotPasswordController>(
      init: ForgotPasswordController(),
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
    final fontSize = isSmallHeight
        ? (size.width * 0.045).clamp(16.0, 22.0)
        : (size.width * 0.05).clamp(18.0, 28.0);

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(size.width * 0.06, 16, size.width * 0.06, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/oryon_health_logo_signin.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: spacing),
                Text(
                  'auth_forgot_title'.tr,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
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
    );
  }

  Widget _buildFormSection(Size size) {
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
        key: Get.find<ForgotPasswordController>().formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.04),
                _buildHeader(size),
                SizedBox(height: size.height * 0.04),
                _buildEmailField(size),
                SizedBox(height: size.height * 0.04),
                _buildSendCodeButton(size),
                SizedBox(height: size.height * 0.025),
                _buildBackButton(size),
                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth_recover_password'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00324A),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'auth_code_sent_email'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(Size size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: Get.find<ForgotPasswordController>().emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: 'auth_email'.tr,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: 'auth_email_hint'.tr,
          prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF00324A)),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
    );
  }

  Widget _buildSendCodeButton(Size size) {
    return Obx(() => Container(
      width: double.infinity,
      height: 54,
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
        onPressed: Get.find<ForgotPasswordController>().isLoading.value
            ? null
            : Get.find<ForgotPasswordController>().sendResetCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Get.find<ForgotPasswordController>().isLoading.value
            ? SizedBox(
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
                  Icon(Icons.send, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'auth_send_code'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    ));
  }

  Widget _buildBackButton(Size size) {
    return Container(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF00324A), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, color: const Color(0xFF00324A), size: 20),
            SizedBox(width: 8),
            Text(
              'auth_back_login'.tr,
              style: TextStyle(
                color: const Color(0xFF00324A),
                fontSize: 16,
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