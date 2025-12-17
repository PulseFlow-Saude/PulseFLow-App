import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
    
    // Extrair parâmetros dos argumentos
    _extractParameters();
    
    // Carregar email do paciente
    _loadPatientEmail();
  }

  void _extractParameters() {
    final arguments = Get.arguments;
    
    if (arguments != null && arguments is Map) {
      _patientId = arguments['patientId'] as String? ?? '';
    }
    
    if (_patientId.isEmpty) {
      final parameters = Get.parameters;
      _patientId = parameters['patientId'] ?? '';
    }
  }

  Future<void> _loadPatientEmail() async {
    if (_patientId.isNotEmpty) {
      try {
        final patient = await AuthService.instance.getPatientById(_patientId);
        if (patient != null) {
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
        _error = 'Dados de sessão inválidos';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _error = null;
    });
    
    try {
      await AuthService.instance.resend2FACode(_patientId, method: 'email');
      Get.snackbar(
        'Código reenviado!',
        'Código reenviado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao reenviar código: ${e.toString()}';
      });
    } finally {
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
    final isSmallScreen = size.width < 480;
    final isMediumScreen = size.width >= 480 && size.width < 768;
    final isLargeScreen = size.width >= 768;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF00324A), // Mudança: cor de fundo igual ao login
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : isMediumScreen ? 24 : 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: isSmallScreen ? size.width * 0.95 : 
                             isMediumScreen ? size.width * 0.8 : 
                             size.width > 600 ? 500 : size.width * 0.9,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : isMediumScreen ? 28 : 32, 
                        vertical: isSmallScreen ? 24 : isMediumScreen ? 32 : 40
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ícone animado
                            Container(
                              height: isSmallScreen ? 70 : isMediumScreen ? 75 : 80,
                              width: isSmallScreen ? 70 : isMediumScreen ? 75 : 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00324A).withValues(alpha: 0.3), // Mudança: cor igual ao login
                                    blurRadius: isSmallScreen ? 15 : 20,
                                    offset: Offset(0, isSmallScreen ? 6 : 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 35 : isMediumScreen ? 38 : 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Título
                            Text(
                              'Verificação em duas etapas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 20 : isMediumScreen ? 22 : 24,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            
                            // Subtítulo
                            Text(
                              'Enviamos um código de 6 dígitos para:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Email do paciente
                            if (_patientEmail != null)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20, 
                                  vertical: isSmallScreen ? 12 : 16
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00324A).withValues(alpha: 0.1), // Mudança: cor igual ao login
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  border: Border.all(
                                    color: const Color(0xFF00324A).withValues(alpha: 0.3), // Mudança: cor igual ao login
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_rounded,
                                      color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Expanded(
                                      child: Text(
                                        _patientEmail!,
                                        style: TextStyle(
                                          color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              'Insira o código abaixo para continuar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            
                            // Container do campo de código
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                border: Border.all(
                                  color: const Color(0xFF00324A), 
                                  width: isSmallScreen ? 1.5 : 2
                                ), // Mudança: cor igual ao login
                              ),
                              child: TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : isMediumScreen ? 22 : 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: isSmallScreen ? 6 : 8,
                                ),
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20, 
                                    vertical: isSmallScreen ? 14 : 16
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o código de verificação';
                                  }
                                  if (value.length != 6) {
                                    return 'O código deve ter 6 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            // Exibir erro se houver
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            
                            // Botão de verificar
                            Container(
                              height: isSmallScreen ? 48 : isMediumScreen ? 52 : 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00324A).withValues(alpha: 0.3), // Mudança: cor igual ao login
                                    blurRadius: isSmallScreen ? 12 : 15,
                                    offset: Offset(0, isSmallScreen ? 4 : 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        setState(() {
                                          _isLoading = true;
                                          _error = null;
                                        });
                                        try {
                                          final patient = await AuthService.instance.verify2FACode(
                                            _patientId,
                                            _codeController.text.trim(),
                                          );
                                          // Redirecionar para tela home após verificação bem-sucedida
                                          Get.offAllNamed('/home');
                                        } catch (e) {
                                          setState(() {
                                            _error = e.toString();
                                          });
                                        } finally {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      },
                                icon: _isLoading
                                    ? SizedBox(
                                        width: isSmallScreen ? 20 : 24,
                                        height: isSmallScreen ? 20 : 24,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                label: Text(
                                  _isLoading ? 'Verificando...' : 'Verificar código',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : isMediumScreen ? 17 : 18,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            
                            // Botão de reenviar código
                            TextButton.icon(
                              onPressed: _isResending ? null : _resendCode,
                              icon: _isResending
                                  ? SizedBox(
                                      width: isSmallScreen ? 14 : 16,
                                      height: isSmallScreen ? 14 : 16,
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF00324A), // Mudança: cor igual ao login
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                              label: Text(
                                _isResending ? 'Reenviando...' : 'Reenviar código',
                                style: TextStyle(
                                  color: const Color(0xFF00324A), // Mudança: cor igual ao login
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}