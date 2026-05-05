import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import '../../widgets/language_icon_button.dart';
import 'registration_controller.dart';
import 'terms_screen.dart';

class ProfessionalRegistrationScreen extends StatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  State<ProfessionalRegistrationScreen> createState() => _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState extends State<ProfessionalRegistrationScreen> with TickerProviderStateMixin {
  late final RegistrationController controller;
  final RxBool isCepLoading = false.obs;
  final RxString cepError = ''.obs;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    try {
      Get.delete<RegistrationController>();
    } catch (e) {
    }
    controller = Get.put(RegistrationController());
    
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    Get.delete<RegistrationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
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
            flex: 2,
            child: _buildFormSection(context, isLandscape, size),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildLogoSection(context, size),
          ),
          Expanded(
            flex: 7,
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
    final bottomPad = math.max(mq.viewInsets.bottom, mq.padding.bottom);
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad * 0.5, 12, horizontalPad, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (controller.currentStep.value > 0) {
                      controller.previousStep();
                    } else {
                      Get.back();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: _buildHeaderTitles(),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            child: Obx(() => _buildStepIndicator(controller.currentStep.value)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              final step = controller.currentStep.value;
              if (step == 0) {
                return _buildAccountStep(context, size, horizontalPad, bottomPad);
              }
              if (step == 1) {
                return _buildPersonalStep(context, size, horizontalPad, bottomPad);
              }
              return _buildAddressStep(context, size, horizontalPad, bottomPad);
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, bottomPad + 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Obx(() => _buildStepActions(size)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitles() {
    return Column(
      children: [
        Text(
          'reg_title'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.titleLarge.copyWith(color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlue.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'reg_subtitle'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int activeStep) {
    final labels = [
      'reg_account_info'.tr,
      'reg_personal_info'.tr,
      'reg_address'.tr,
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Row(
        children: List.generate(RegistrationController.totalSteps, (i) {
          final done = i < activeStep;
          final current = i == activeStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done || current ? AppTheme.primaryBlue : Colors.grey.shade300,
                          boxShadow: current
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: current ? Colors.white : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                          color: current ? AppTheme.primaryBlue : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < RegistrationController.totalSteps - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepActions(Size size) {
    final step = controller.currentStep.value;
    return Row(
      children: [
        if (step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isLoading.value ? null : controller.previousStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'auth_back'.tr,
                style: AppTheme.titleSmall.copyWith(color: AppTheme.primaryBlue),
              ),
            ),
          ),
        if (step > 0) const SizedBox(width: 12),
        Expanded(
          flex: step > 0 ? 1 : 1,
          child: step < RegistrationController.totalSteps - 1
              ? _gradientButton(
                  label: 'common_next'.tr,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: controller.isLoading.value ? null : controller.nextStep,
                  loading: false,
                )
              : Obx(
                  () => _gradientButton(
                    label: 'reg_btn_create'.tr,
                    icon: Icons.person_add_rounded,
                    onPressed: controller.isLoading.value ? null : _submitForm,
                    loading: controller.isLoading.value,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return Container(
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
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
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMiniStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccountStep(BuildContext context, Size size, double horizontalPad, double bottomPad) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 16 + bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: controller.accountFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMiniStepTitle('reg_account_info'.tr, 'reg_account_sub'.tr),
                _buildTextField(
                  context,
                  controller: controller.nameController,
                  label: 'reg_full_name'.tr,
                  icon: Icons.person_outline,
                  validator: controller.validateName,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.emailController,
                  label: 'auth_email'.tr,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: controller.passwordController,
                  label: 'auth_password'.tr,
                  validator: controller.validatePassword,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: controller.confirmPasswordController,
                  label: 'reg_confirm_password'.tr,
                  validator: controller.validateConfirmPassword,
                ),
                const SizedBox(height: 16),
                _buildProfilePhotoField(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalStep(BuildContext context, Size size, double horizontalPad, double bottomPad) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 16 + bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: controller.personalFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMiniStepTitle('reg_personal_info'.tr, 'reg_personal_sub'.tr),
                _buildTextField(
                  context,
                  controller: controller.cpfController,
                  label: 'profile_cpf'.tr,
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [controller.cpfMask],
                  validator: controller.validateCPF,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.rgController,
                  label: 'profile_rg'.tr,
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.text,
                  inputFormatters: [controller.rgMask],
                  validator: controller.validateRG,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.phoneController,
                  label: 'profile_phone'.tr,
                  icon: Icons.phone_iphone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [controller.phoneMask],
                  validator: controller.validatePhone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.nationalityController,
                  label: 'reg_nationality'.tr,
                  icon: Icons.flag_outlined,
                  validator: (value) => controller.validateRequired(value, 'reg_nationality'.tr),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.birthDateController,
                  label: 'profile_birth_date'.tr,
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: () => controller.selectDate(context),
                  validator: controller.validateBirthDate,
                ),
                const SizedBox(height: 16),
                Obx(() => _buildDropdownField(
                      context,
                      value: controller.gender.value,
                      label: 'reg_gender'.tr,
                      icon: Icons.transgender,
                      items: controller.genders,
                      onChanged: (String? newValue) {
                        controller.gender.value = newValue;
                      },
                      validator: (v) => controller.validateDropdown(v, 'reg_gender'.tr),
                    )),
                const SizedBox(height: 16),
                Obx(() => _buildDropdownField(
                      context,
                      value: controller.maritalStatus.value,
                      label: 'reg_marital_status'.tr,
                      icon: Icons.family_restroom_outlined,
                      items: controller.maritalStatuses,
                      onChanged: (String? newValue) {
                        controller.maritalStatus.value = newValue;
                      },
                      validator: (v) => controller.validateDropdown(v, 'reg_marital_status'.tr),
                    )),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.heightController,
                  label: 'reg_height'.tr,
                  icon: Icons.height_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: controller.validateHeight,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.weightController,
                  label: 'reg_weight'.tr,
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: controller.validateWeight,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.professionController,
                  label: 'reg_profession'.tr,
                  icon: Icons.work_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressStep(BuildContext context, Size size, double horizontalPad, double bottomPad) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 16 + bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: controller.addressFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMiniStepTitle('reg_address'.tr, 'reg_address_sub'.tr),
                _buildTextField(
                  context,
                  controller: controller.cepController,
                  label: 'reg_cep'.tr,
                  icon: Icons.location_on_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [controller.cepMask],
                  validator: controller.validateCEP,
                  onChanged: (value) {
                    if (value.length == 9) {
                      _buscarEnderecoPorCep(value);
                    } else {
                      cepError.value = '';
                    }
                  },
                  suffixIcon: Obx(() => isCepLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const SizedBox.shrink()),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.streetController,
                  label: 'reg_street'.tr,
                  icon: Icons.alt_route,
                  validator: (value) => controller.validateRequired(value, 'reg_street'.tr),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.numberController,
                  label: 'reg_number'.tr,
                  icon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => controller.validateRequired(value, 'reg_number'.tr),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.complementController,
                  label: 'reg_complement'.tr,
                  icon: Icons.add_location_alt_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.neighborhoodController,
                  label: 'reg_neighborhood'.tr,
                  icon: Icons.location_city_outlined,
                  validator: (value) => controller.validateRequired(value, 'reg_neighborhood'.tr),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: controller.cityController,
                  label: 'reg_city'.tr,
                  icon: Icons.apartment_outlined,
                  validator: (value) => controller.validateRequired(value, 'reg_city'.tr),
                ),
                const SizedBox(height: 16),
                Obx(() => _buildDropdownField(
                      context,
                      value: controller.state.value,
                      label: 'reg_state'.tr,
                      icon: Icons.map_outlined,
                      items: controller.states,
                      onChanged: (String? newValue) {
                        controller.state.value = newValue;
                      },
                      validator: (v) => controller.validateDropdown(v, 'reg_state'.tr),
                    )),
                const SizedBox(height: 24),
                _buildMiniStepTitle('reg_terms'.tr, 'reg_terms_sub'.tr),
                _buildCheckboxTile(
                  context,
                  value: controller.acceptTerms,
                  title: 'reg_accept_terms'.tr,
                  linkText: 'reg_terms_link'.tr,
                  onLinkTap: () => Get.to(() => const TermsScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    bool readOnly = false,
    Function()? onTap,
  }) {
    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodyMedium,
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.primaryBlue.withValues(alpha: 0.9))
            : null,
        suffixIcon: suffixIcon,
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
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    final obscure = true.obs;
    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    return Obx(() => TextFormField(
          controller: controller,
          obscureText: obscure.value,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTheme.bodyMedium,
            prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
            suffixIcon: IconButton(
              icon: Icon(
                obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => obscure.value = !obscure.value,
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
          validator: validator,
        ));
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final borderColor = AppTheme.primaryBlue.withValues(alpha: 0.22);
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodyMedium,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
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
      style: AppTheme.bodyLarge.copyWith(
        fontWeight: FontWeight.w500,
        color: AppTheme.primaryBlue,
      ),
      items: items.map((String itemValue) {
        return DropdownMenuItem<String>(
          value: itemValue,
          child: Text(
            itemValue.tr,
            overflow: TextOverflow.visible,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
    );
  }

  Widget _buildCheckboxTile(
    BuildContext context, {
    required RxBool value,
    required String title,
    String? linkText,
    Function()? onLinkTap,
  }) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Checkbox(
                value: value.value,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    value.value = newValue;
                  }
                },
                activeColor: AppTheme.primaryBlue,
                checkColor: Colors.white,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.45)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: linkText != null
                ? RichText(
                    text: TextSpan(
                      text: title,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: linkText,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.primaryBlue,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                        ),
                      ],
                    ),
                  )
                : Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoField(BuildContext context, RegistrationController controller) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    final titleSize = isSmallScreen ? size.width * 0.035 : size.width * 0.04;
    final subtitleSize = isSmallScreen ? size.width * 0.03 : size.width * 0.032;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: AppTheme.primaryBlue,
                size: iconSize.clamp(18.0, 24.0),
              ),
              SizedBox(width: size.width * 0.02),
              Flexible(
                child: Text(
                  'reg_photo_profile'.tr,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize.clamp(14.0, 18.0),
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  'reg_photo_optional'.tr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: subtitleSize.clamp(10.0, 14.0),
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          
          Obx(() => controller.profilePhoto.value != null
              ? _buildPhotoPreview(context, controller)
              : Center(child: _buildPhotoPlaceholder(context, controller))),
          
          SizedBox(height: size.height * 0.01),
          Text(
            'reg_photo_hint'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: subtitleSize.clamp(11.0, 14.0),
            ),
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(BuildContext context, RegistrationController controller) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final photoSize = isSmallScreen ? size.width * 0.25 : size.width * 0.3;
    final iconSize = isSmallScreen ? size.width * 0.035 : size.width * 0.04;
    final fontSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    
    return Column(
      children: [
        Container(
          width: photoSize.clamp(100.0, 140.0),
          height: photoSize.clamp(100.0, 140.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(photoSize.clamp(100.0, 140.0) / 2),
            border: Border.all(
              color: AppTheme.primaryBlue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(photoSize.clamp(100.0, 140.0) / 2),
            child: Image.file(
              controller.profilePhoto.value!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: size.width * 0.03,
          runSpacing: size.height * 0.01,
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.showImageSourceDialog(context),
              icon: Icon(Icons.edit, size: iconSize.clamp(16.0, 20.0)),
              label: Text(
                'reg_photo_change'.tr,
                style: TextStyle(fontSize: fontSize.clamp(12.0, 16.0)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                  vertical: buttonPadding * 0.5,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: controller.removeProfilePhoto,
              icon: Icon(Icons.delete, size: iconSize.clamp(16.0, 20.0)),
              label: Text(
                'reg_photo_remove'.tr,
                style: TextStyle(fontSize: fontSize.clamp(12.0, 16.0)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                  vertical: buttonPadding * 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context, RegistrationController controller) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final photoSize = isSmallScreen ? size.width * 0.25 : size.width * 0.3;
    final iconSize = isSmallScreen ? size.width * 0.1 : size.width * 0.12;
    final fontSize = isSmallScreen ? size.width * 0.03 : size.width * 0.032;
    
    return GestureDetector(
      onTap: () => controller.showImageSourceDialog(context),
      child: Container(
        width: photoSize.clamp(100.0, 140.0),
        height: photoSize.clamp(100.0, 140.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(photoSize.clamp(100.0, 140.0) / 2),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Icon(
                Icons.add_a_photo,
                size: iconSize.clamp(30.0, 50.0),
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Center(
              child: Text(
                'reg_photo_add'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: fontSize.clamp(10.0, 14.0),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarEnderecoPorCep(String cep) async {
    final cleanedCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedCep.length != 8) return;

    isCepLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanedCep/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == true) {
          cepError.value = 'reg_cep_not_found'.tr;
        } else {
          controller.streetController.text = data['logradouro'] ?? '';
          controller.neighborhoodController.text = data['bairro'] ?? '';
          controller.cityController.text = data['localidade'] ?? '';
          controller.state.value = data['uf'] ?? '';
          cepError.value = '';
        }
      }
    } catch (e) {
      cepError.value = 'reg_cep_error'.tr;
    } finally {
      isCepLoading.value = false;
    }
  }

  Future<void> _submitForm() async {
    if (!(controller.addressFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!controller.acceptTerms.value) {
      Get.snackbar(
        'reg_terms_not_accepted'.tr,
        'reg_terms_must_accept'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await controller.register();
  }
}