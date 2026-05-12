import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/round_progress_indicator.dart';
import 'widgets/biometric_first_login_sheet.dart';

class Verify2FAScreen extends StatefulWidget {
  final String patientId;
  final String method;
  
  const Verify2FAScreen({
    super.key,
    required this.patientId,
    required this.method,
  });

  @override
  State<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends State<Verify2FAScreen> 
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  late String _patientId;
  String? _patientEmail;
  /// Senha do passo anterior (só em memória) para opcionalmente guardar login biométrico.
  String? _loginPassword;
  /// Modo EMAIL_2FA_SKIP_SMTP: código visível na UI (sem SMTP).
  String? _plaintextCode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    
    // Extrair parâmetros dos argumentos
    _extractParameters();
    _plaintextCode ??=
        AuthService.instance.plaintext2FACodeForTesting;

    // Carregar email do paciente
    _loadPatientEmail();
  }

  void _extractParameters() {
    final arguments = Get.arguments;
    
    if (arguments != null && arguments is Map) {
      _patientId = arguments['patientId'] as String? ?? '';
      final pc = arguments['plaintextCode'];
      if (pc is String && pc.isNotEmpty) {
        _plaintextCode = pc;
      }
      final lp = arguments['loginPassword'];
      if (lp is String && lp.isNotEmpty) {
        _loginPassword = lp;
      }
    }
    
    if (_patientId.isEmpty) {
      final parameters = Get.parameters;
      _patientId = parameters['patientId'] ?? '';
    }

    if (_patientId.isEmpty) {
      _patientId = widget.patientId;
    }
  }

  Future<void> _loadPatientEmail() async {
    if (_patientId.isNotEmpty) {
      try {
        final patient = await AuthService.instance.getPatientById(_patientId);
        if (patient != null && mounted) {
          setState(() {
            _patientEmail = patient.email;
          });
        }
      } catch (e) {
      }
    }
  }

  Future<void> _resendCode() async {
    if (_patientId.isEmpty) {
      setState(() {
        _error = 'auth_2fa_invalid_session'.tr;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isResending = true;
      _error = null;
    });
    
    try {
      await AuthService.instance.resend2FACode(_patientId, method: widget.method);
      final plain = AuthService.instance.plaintext2FACodeForTesting;
      if (!mounted) return;
      setState(() {
        _plaintextCode = plain ?? _plaintextCode;
      });
      Get.snackbar(
        'auth_2fa_code_resent'.tr,
        plain != null
            ? 'auth_2fa_skip_smtp_resend_snackbar'.trParams({'code': plain})
            : 'auth_2fa_code_resent_msg'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: plain != null ? 12 : 3),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${'auth_2fa_resend_error'.tr}: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isSmallScreen = size.width < 480;
    
    return Scaffold(
      body: Container(
        decoration: AppTheme.blueScreenGradientDecoration,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(isLandscape, isSmallScreen, size),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLandscape, bool isSmallScreen, Size size) {
    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            child: _buildTopBrandSection(size),
          ),
          Expanded(
            child: _buildFormSection(isSmallScreen, size, isLandscape),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildTopBrandSection(size),
        ),
        Expanded(
          flex: 5,
          child: _buildFormSection(isSmallScreen, size, isLandscape),
        ),
      ],
    );
  }

  Widget _buildTopBrandSection(Size size) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 700),
        tween: Tween(begin: 0.95, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/oryon_health_logo_signin.png',
          width: size.shortestSide < 420 ? 140 : 176,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFormSection(bool isSmallScreen, Size size, bool isLandscape) {
    final mq = MediaQuery.of(context);
    final bottomPad = (isLandscape ? 20.0 : 24.0) + mq.padding.bottom;
    final horizontalPad = isSmallScreen ? 20.0 : 28.0;

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPad, 24, horizontalPad, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.25),
                          AppTheme.primaryBlue.withValues(alpha: 0.9),
                          AppTheme.secondaryBlue.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isLoading ? null : Get.back,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppTheme.primaryBlue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.verified_user_rounded,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.92),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'auth_2fa_title'.tr,
                    textAlign: TextAlign.center,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth_2fa_sent'.tr,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'auth_2fa_enter_code'.tr,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_patientEmail != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _patientEmail!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_plaintextCode != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'auth_2fa_skip_smtp_title'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'auth_2fa_skip_smtp_hint'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            _plaintextCode!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'auth_2fa_enter_code'.tr,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isSmallScreen ? 6 : 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.24),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.24),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onFieldSubmitted: (_) => _submitCode(),
                    onChanged: (value) {
                      if (value.length != 6) return;
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    validator: (value) {
                      final sanitizedValue = value?.trim() ?? '';
                      if (sanitizedValue.isEmpty) {
                        return 'auth_2fa_code_hint'.tr;
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(sanitizedValue)) {
                        return 'auth_code_6_digits'.tr;
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: isSmallScreen ? 50 : 54,
                    child: Container(
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
                            color: AppTheme.primaryBlue.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const RoundProgressIndicator(
                                dimension: 22,
                                strokeWidth: 2.8,
                                color: Colors.white,
                              )
                            else
                              const Icon(Icons.verified_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              _isLoading ? 'auth_2fa_verifying'.tr : 'auth_2fa_verify'.tr,
                              style: AppTheme.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _isResending ? null : _resendCode,
                    icon: _isResending
                        ? RoundProgressIndicator(
                            dimension: 18,
                            strokeWidth: 2.6,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                          ),
                    label: Text(
                      _isResending ? 'auth_resending'.tr : 'auth_resend'.tr,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientId.isEmpty) {
      setState(() {
        _error = 'auth_2fa_invalid_session'.tr;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.instance.verify2FACode(
        _patientId,
        _codeController.text.trim(),
      );
      if (!mounted) return;

      final offer = await AuthService.instance.shouldOfferBiometricSetupAfterFirst2FA();
      final pwd = _loginPassword;
      if (offer && pwd != null && pwd.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (ctx) {
            return BiometricFirstLoginSheet(
              email: _patientEmail ?? '',
              password: pwd,
              onFinished: () {
                Navigator.of(ctx).pop();
                Get.offAllNamed('/home');
              },
            );
          },
        );
      } else {
        if (offer) {
          await AuthService.instance.markBiometricFirstLoginPromptShown();
        }
        Get.offAllNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
}