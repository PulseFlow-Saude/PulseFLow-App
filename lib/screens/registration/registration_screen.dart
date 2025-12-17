import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
            flex: 5,
            child: _buildFormSection(size),
          ),
        ],
      );
    }
  }

  Widget _buildLogoSection(Size size) {
    return Center(
      child: Image.asset(
        'assets/images/pulseflow2.png',
        width: size.width * 0.4,
        height: size.width * 0.4,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildFormSection(Size size) {
    final isSmallScreen = size.width < 400;
    final titleFontSize = isSmallScreen ? size.width * 0.065 : size.width * 0.055;
    final subtitleFontSize = isSmallScreen ? size.width * 0.035 : size.width * 0.032;
    
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.02,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFF00324A),
                    size: size.width * 0.05,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Registro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(20.0, 32.0),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00324A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        'Complete seus dados para começar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFontSize.clamp(12.0, 16.0),
                          color: Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: size.width * 0.12),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: controller.formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: 16,
                  ),
                  child: _buildRegistrationForm(size),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRegistrationForm(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: size.height * 0.02),
        _buildSectionHeader(
          icon: Icons.person_outline,
          title: 'Informações de Conta',
          subtitle: 'Dados básicos para acesso',
        ),
        SizedBox(height: size.height * 0.025),
        
        _buildTextField(
          controller: controller.nameController,
          label: 'Nome completo',
          icon: Icons.person_outline,
          validator: controller.validateName,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: controller.validateEmail,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildPasswordField(
          controller: controller.passwordController,
          label: 'Senha',
          validator: controller.validatePassword,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildPasswordField(
          controller: controller.confirmPasswordController,
          label: 'Confirmar Senha',
          validator: controller.validateConfirmPassword,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildProfilePhotoField(controller),
        SizedBox(height: size.height * 0.03),

        _buildSectionHeader(
          icon: Icons.assignment_ind_outlined,
          title: 'Informações Pessoais',
          subtitle: 'Dados de identificação',
        ),
        SizedBox(height: size.height * 0.025),
        
        _buildTextField(
          controller: controller.cpfController,
          label: 'CPF',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [controller.cpfMask],
          validator: controller.validateCPF,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.rgController,
          label: 'RG',
          icon: Icons.credit_card_outlined,
          keyboardType: TextInputType.text,
          inputFormatters: [controller.rgMask],
          validator: controller.validateRG,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.phoneController,
          label: 'Telefone',
          icon: Icons.phone_iphone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [controller.phoneMask],
          validator: controller.validatePhone,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.nationalityController,
          label: 'Nacionalidade',
          icon: Icons.flag_outlined,
          validator: (value) => controller.validateRequired(value, 'Nacionalidade'),
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.birthDateController,
          label: 'Data de Nascimento',
          icon: Icons.cake_outlined,
          readOnly: true,
          onTap: () => controller.selectDate(context),
          validator: controller.validateBirthDate,
        ),
        SizedBox(height: size.height * 0.02),
        
        Obx(() => _buildDropdownField(
          value: controller.gender.value,
          label: 'Sexo / Gênero',
          icon: Icons.transgender,
          items: controller.genders,
          onChanged: (String? newValue) { controller.gender.value = newValue; },
          validator: (v) => controller.validateDropdown(v, 'Sexo / Gênero'),
        )),
        SizedBox(height: size.height * 0.02),
        
        Obx(() => _buildDropdownField(
          value: controller.maritalStatus.value,
          label: 'Estado Civil',
          icon: Icons.family_restroom_outlined,
          items: controller.maritalStatuses,
          onChanged: (String? newValue) { controller.maritalStatus.value = newValue; },
          validator: (v) => controller.validateDropdown(v, 'Estado Civil'),
        )),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.heightController,
          label: 'Altura (cm)',
          icon: Icons.height_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: controller.validateHeight,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.weightController,
          label: 'Peso (kg)',
          icon: Icons.monitor_weight_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: controller.validateWeight,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.professionController,
          label: 'Profissão',
          icon: Icons.work_outline,
        ),
        SizedBox(height: size.height * 0.03),

        _buildSectionHeader(
          icon: Icons.home_outlined,
          title: 'Endereço',
          subtitle: 'Localização residencial',
        ),
        SizedBox(height: size.height * 0.025),
        
        _buildTextField(
          controller: controller.cepController,
          label: 'CEP',
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
            ? Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2)
              )
            : SizedBox.shrink()
          ),
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.streetController,
          label: 'Rua',
          icon: Icons.alt_route,
          validator: (value) => controller.validateRequired(value, 'Rua'),
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.numberController,
          label: 'Número',
          icon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          validator: (value) => controller.validateRequired(value, 'Número'),
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.complementController,
          label: 'Complemento',
          icon: Icons.add_location_alt_outlined,
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.neighborhoodController,
          label: 'Bairro',
          icon: Icons.location_city_outlined,
          validator: (value) => controller.validateRequired(value, 'Bairro'),
        ),
        SizedBox(height: size.height * 0.02),
        
        _buildTextField(
          controller: controller.cityController,
          label: 'Cidade',
          icon: Icons.apartment_outlined,
          validator: (value) => controller.validateRequired(value, 'Cidade'),
        ),
        SizedBox(height: size.height * 0.02),
        
        Obx(() => _buildDropdownField(
          value: controller.state.value,
          label: 'UF',
          icon: Icons.map_outlined,
          items: controller.states,
          onChanged: (String? newValue) { controller.state.value = newValue; },
          validator: (v) => controller.validateDropdown(v, 'UF'),
        )),
        SizedBox(height: size.height * 0.03),

        _buildSectionHeader(
          icon: Icons.gavel_outlined,
          title: 'Termos e Condições',
          subtitle: 'Autorizações necessárias',
        ),
        SizedBox(height: size.height * 0.025),
        
        _buildCheckboxTile(
          value: controller.acceptTerms,
          title: 'Aceito os ',
          linkText: 'termos de uso',
          onLinkTap: () => Get.to(() => const TermsScreen()),
        ),
        SizedBox(height: size.height * 0.04),

        _buildRegisterButton(size),
        SizedBox(height: size.height * 0.04),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.04;
    final titleSize = isSmallScreen ? size.width * 0.038 : size.width * 0.04;
    final subtitleSize = isSmallScreen ? size.width * 0.03 : size.width * 0.032;
    
    return Container(
      padding: EdgeInsets.all(padding),
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
            color: const Color(0xFF00324A).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize.clamp(16.0, 24.0)),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize.clamp(14.0, 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: subtitleSize.clamp(11.0, 14.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final fontSize = isSmallScreen ? size.width * 0.038 : size.width * 0.04;
    final labelSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    final padding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: fontSize.clamp(14.0, 18.0),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: labelSize.clamp(12.0, 16.0),
          ),
          prefixIcon: icon != null 
            ? Icon(
                icon,
                color: const Color(0xFF00324A),
                size: iconSize.clamp(18.0, 24.0),
              ) 
            : null,
          suffixIcon: suffixIcon,
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
            horizontal: padding,
            vertical: padding,
          ),
        ),
        validator: validator,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    final obscure = true.obs;
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final fontSize = isSmallScreen ? size.width * 0.038 : size.width * 0.04;
    final labelSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    final padding = isSmallScreen ? 12.0 : 16.0;
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure.value,
        style: TextStyle(
          fontSize: fontSize.clamp(14.0, 18.0),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: labelSize.clamp(12.0, 16.0),
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: const Color(0xFF00324A),
            size: iconSize.clamp(18.0, 24.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey[600],
              size: iconSize.clamp(18.0, 24.0),
            ),
            onPressed: () => obscure.value = !obscure.value,
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
            horizontal: padding,
            vertical: padding,
          ),
        ),
        validator: validator,
      ),
    ));
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final fontSize = isSmallScreen ? size.width * 0.038 : size.width * 0.04;
    final labelSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    final padding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: labelSize.clamp(12.0, 16.0),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF00324A),
            size: iconSize.clamp(18.0, 24.0),
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
            horizontal: padding,
            vertical: padding,
          ),
        ),
        style: TextStyle(
          fontSize: fontSize.clamp(14.0, 18.0),
          fontWeight: FontWeight.w500,
          color: const Color(0xFF00324A),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: fontSize.clamp(14.0, 18.0),
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF00324A)),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required RxBool value,
    required String title,
    String? linkText,
    Function()? onLinkTap,
  }) {
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final fontSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    final padding = isSmallScreen ? 10.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF00324A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00324A).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Obx(() => Checkbox(
            value: value.value,
            onChanged: (bool? newValue) {
              if (newValue != null) {
                value.value = newValue;
              }
            },
            activeColor: const Color(0xFF00324A),
          )),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: linkText != null
                ? RichText(
                    text: TextSpan(
                      text: title,
                      style: TextStyle(
                        color: const Color(0xFF222B45),
                        fontSize: fontSize.clamp(12.0, 16.0),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: linkText,
                          style: TextStyle(
                            color: const Color(0xFF00324A),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: fontSize.clamp(12.0, 16.0),
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                        ),
                      ],
                    ),
                  )
                : Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF222B45),
                      fontSize: fontSize.clamp(12.0, 16.0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoField(RegistrationController controller) {
    final size = MediaQuery.of(Get.context!).size;
    final isSmallScreen = size.width < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    final titleSize = isSmallScreen ? size.width * 0.035 : size.width * 0.04;
    final subtitleSize = isSmallScreen ? size.width * 0.03 : size.width * 0.032;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00324A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: const Color(0xFF00324A),
                size: iconSize.clamp(18.0, 24.0),
              ),
              SizedBox(width: size.width * 0.02),
              Flexible(
                child: Text(
                  'Foto de Perfil',
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
              Spacer(),
              Flexible(
                child: Text(
                  '(Opcional)',
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
            ? _buildPhotoPreview(controller)
            : Center(child: _buildPhotoPlaceholder(controller))
          ),
          
          SizedBox(height: size.height * 0.01),
          Text(
            'Adicione uma foto para personalizar seu perfil',
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

  Widget _buildPhotoPreview(RegistrationController controller) {
    final size = MediaQuery.of(Get.context!).size;
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
              color: const Color(0xFF00324A),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00324A).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
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
                'Alterar',
                style: TextStyle(fontSize: fontSize.clamp(12.0, 16.0)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00324A),
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
                'Remover',
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

  Widget _buildPhotoPlaceholder(RegistrationController controller) {
    final size = MediaQuery.of(Get.context!).size;
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
            color: const Color(0xFF00324A).withValues(alpha: 0.3),
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
                'Adicionar\nFoto',
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

  Widget _buildRegisterButton(Size size) {
    final isSmallScreen = size.width < 400;
    final buttonHeight = isSmallScreen ? size.height * 0.065 : size.height * 0.07;
    final fontSize = isSmallScreen ? size.width * 0.035 : size.width * 0.04;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    
    return Obx(() => Container(
      width: double.infinity,
      height: buttonHeight.clamp(48.0, 60.0),
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
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: controller.isLoading.value
            ? SizedBox(
                width: size.width * 0.06,
                height: size.width * 0.06,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: iconSize.clamp(18.0, 24.0),
                  ),
                  SizedBox(width: size.width * 0.02),
                  Flexible(
                    child: Text(
                      'CRIAR MINHA CONTA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize.clamp(14.0, 18.0),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
      ),
    ));
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
          cepError.value = 'CEP não encontrado';
        } else {
          controller.streetController.text = data['logradouro'] ?? '';
          controller.neighborhoodController.text = data['bairro'] ?? '';
          controller.cityController.text = data['localidade'] ?? '';
          controller.state.value = data['uf'] ?? '';
          cepError.value = '';
        }
      }
    } catch (e) {
      cepError.value = 'Erro ao buscar CEP';
    } finally {
      isCepLoading.value = false;
    }
  }

  void _submitForm() async {
    if (controller.formKey.currentState?.validate() ?? false) {
      if (!controller.acceptTerms.value) {
        Get.snackbar(
          'Termos não aceitos',
          'Você deve aceitar todos os termos para continuar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await controller.register();
    }
  }
}