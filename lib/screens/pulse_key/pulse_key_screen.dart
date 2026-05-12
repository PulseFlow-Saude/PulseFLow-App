import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/patient_notification_prefs.dart';
import '../../widgets/pulse_bottom_navigation.dart' show PulseNavItem;
import '../../widgets/pulse_side_menu.dart';

class PulseKeyScreen extends StatefulWidget {
  const PulseKeyScreen({super.key});

  @override
  State<PulseKeyScreen> createState() => _PulseKeyScreenState();
}

class _PulseKeyScreenState extends State<PulseKeyScreen> {
  String _currentCode = '';
  int _timeRemaining = 120;
  final bool _isActive = true;
  DateTime? _lastCodeGeneration;
  Timer? _timer;
  Timer? _connectionTimer;
  final ApiService _apiService = ApiService();
  final AuthService _authService = Get.find<AuthService>();
  bool _isSendingCode = false;
  bool _isMedicoConectado = false;
  String? _medicoNome;
  String? _medicoEspecialidade;
  int _tempoConectado = 0;
  bool _isLoadingConexao = false;
  bool _isDesconectando = false;
  bool _accessEmailSessionHandled = false;

  @override
  void initState() {
    super.initState();
    // Gerar código imediatamente de forma síncrona para exibir na tela
    final now = DateTime.now();
    final random = Random();
    final newCode = (100000 + random.nextInt(900000)).toString();
    
    setState(() {
      _currentCode = newCode;
      _lastCodeGeneration = now;
      _timeRemaining = 120;
    });
    
    // Enviar código para backend de forma assíncrona
    _sendCodeToBackend(newCode, now.add(const Duration(minutes: 2)));
    _startTimer();
    _checkConnection();
    _startConnectionTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isActive) {
        setState(() {
          _timeRemaining--;
          if (_timeRemaining <= 0) {
            _generateNewCode();
            _timeRemaining = 120;
          }
        });
      }
    });
  }

  void _generateNewCode() async {
    final now = DateTime.now();
    final random = Random();
    final newCode = (100000 + random.nextInt(900000)).toString();
    final expiresAt = now.add(const Duration(minutes: 2));
    
    setState(() {
      _currentCode = newCode;
      _lastCodeGeneration = now;
      _isSendingCode = true;
    });

    // Enviar código para o backend
    await _sendCodeToBackend(newCode, expiresAt);
  }

  Future<void> _sendCodeToBackend(String code, DateTime expiresAt) async {
    if (mounted) {
      setState(() {
        _isSendingCode = true;
      });
    }
    
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser == null || currentUser.id == null) {
        if (mounted) {
          Get.snackbar(
            'pk_warning'.tr,
            'pk_warning_user_unauth'.tr,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      final accessLogEmail =
          await PatientNotificationPrefs.isAccessLogEmailEnabled();
      await _apiService.sendAccessCode(
        patientId: currentUser.id!,
        accessCode: code,
        expiresAt: expiresAt,
        accessLogEmail: accessLogEmail,
      );
      
      print('✅ [PulseKeyScreen] Código sincronizado com sucesso');
      
    } catch (e) {
      // Não bloquear a funcionalidade - o código ainda funciona localmente
      if (mounted) {
        String message;
        String fullError = e.toString();
        
        // Debug: mostrar erro completo no console
        print('⚠️ [PulseKeyScreen] Erro de sincronização (código ainda funciona): $fullError');
        
        // Detectar tipo de erro específico (usar .tr em literal para resolver tradução)
        if (fullError.contains('Token de autenticação não encontrado') ||
            fullError.contains('Sessão expirada')) {
          message = 'pk_sync_error_session'.tr;
        } else if (fullError.contains('ngrok está offline') ||
                   fullError.contains('ERR_NGROK_3200') ||
                   fullError.contains('Túnel ngrok está offline') ||
                   fullError.contains('Endpoint público offline') ||
                   fullError.contains('Endpoint público indisponível')) {
          message = 'pk_sync_error_ngrok'.tr;
        } else if (fullError.contains('Servidor não está acessível') ||
                   fullError.contains('URL do servidor inválida') ||
                   fullError.contains('não foi possível conectar ao servidor') ||
                   fullError.contains('Connection refused') ||
                   fullError.contains('Network is unreachable')) {
          message = 'pk_sync_error_server_unreachable'.tr;
        } else if (fullError.contains('CORS')) {
          message = 'pk_sync_error_cors'.tr;
        } else if (fullError.contains('401') || fullError.contains('Unauthorized')) {
          message = 'pk_sync_error_unauthorized'.tr;
        } else if (fullError.contains('403') || fullError.contains('Forbidden')) {
          message = 'pk_sync_error_forbidden'.tr;
        } else if (fullError.contains('ngrok offline') ||
                   fullError.contains('Túnel ngrok offline') ||
                   fullError.contains('ERR_NGROK_3200') ||
                   fullError.contains('Endpoint público offline')) {
          message = 'pk_sync_error_ngrok_short'.tr;
        } else if (fullError.contains('404') || fullError.contains('not found')) {
          message = 'pk_sync_error_404'.tr;
        } else if (fullError.contains('500') || fullError.contains('Internal Server Error')) {
          message = 'pk_sync_error_500'.tr;
        } else if (fullError.contains('Tempo de espera esgotado') ||
                   fullError.contains('Timeout')) {
          message = 'pk_sync_error_timeout'.tr;
        } else {
          message = 'pk_sync_error_generic'.tr;
        }
        
        // Mostrar aviso (não erro) já que o código ainda funciona
        Get.snackbar(
          'pk_sync_warning'.tr,
          message,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _currentCode));
    Get.snackbar(
      'pk_copied'.tr,
      'pk_copied_msg'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _checkConnection() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.id == null) return;

    final wasConnected = _isMedicoConectado;

    setState(() {
      _isLoadingConexao = true;
    });

    try {
      final conexao = await _apiService.verificarConexaoMedico(currentUser!.id!);

      if (mounted && conexao != null) {
        final nowConnected = conexao['conectado'] == true;
        final medico = conexao['medico'] as Map<String, dynamic>?;
        final nome = medico?['nome'] as String?;
        final esp = medico?['especialidade'] as String?;

        setState(() {
          _isMedicoConectado = nowConnected;
          if (nowConnected) {
            _medicoNome = nome;
            _medicoEspecialidade = esp;
            _tempoConectado = conexao['tempoConectado'] as int? ?? 0;
          } else {
            _medicoNome = null;
            _medicoEspecialidade = null;
            _tempoConectado = 0;
          }
          _isLoadingConexao = false;
        });

        if (!wasConnected && nowConnected) {
          _onMedicoAcabouDeConectar(
            patientId: currentUser.id!,
            nome: nome,
            esp: esp,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConexao = false;
        });
      }
    }
  }

  void _onMedicoAcabouDeConectar({
    required String patientId,
    String? nome,
    String? esp,
  }) {
    if (_accessEmailSessionHandled) return;
    _accessEmailSessionHandled = true;
    unawaited(() async {
      try {
        if (!await PatientNotificationPrefs.isAccessLogEmailEnabled()) {
          return;
        }
        await _apiService.notificarPacienteAcessoMedicoConectado(
          patientId: patientId,
          medicoNome: nome,
          medicoEspecialidade: esp,
        );
      } catch (_) {}
    }());
  }
  
  void _startConnectionTimer() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnection();
      if (_isMedicoConectado) {
        setState(() {
          _tempoConectado += 5;
        });
      }
    });
  }
  
  Future<void> _desconectarMedico() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.id == null) return;
    
    setState(() {
      _isDesconectando = true;
    });
    
    try {
      final sucesso = await _apiService.desconectarMedico(currentUser!.id!);
      
      if (mounted) {
        if (sucesso) {
          setState(() {
            _isMedicoConectado = false;
            _medicoNome = null;
            _medicoEspecialidade = null;
            _tempoConectado = 0;
            _accessEmailSessionHandled = false;
          });
          
          Get.snackbar(
            'pk_disconnected'.tr,
            'pk_disconnected_msg'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'common_error'.tr,
            'pk_disconnect_error'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
        setState(() {
          _isDesconectando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDesconectando = false;
        });
        Get.snackbar(
          'common_error'.tr,
          'pk_disconnect_error_msg'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
  
  String _formatConnectionTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      drawer: const PulseSideMenu(activeItem: PulseNavItem.pulseKey),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: _isMedicoConectado
                    ? _buildConexaoAtivaView(isSmallScreen)
                    : _buildCodigoView(isSmallScreen, screenWidth),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCodigoView(bool isSmallScreen, double screenWidth) {
    return Column(
      children: [
        _buildCodeSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 20 : 32),
        _buildTimer(),
        SizedBox(height: isSmallScreen ? 20 : 24),
        _buildInfoSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 16 : 24),
        _buildInstructionsSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 20 : 40),
      ],
    );
  }
  
  Widget _buildConexaoAtivaView(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 20 : 40),
        _buildMedicoConectadoSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 24 : 32),
        _buildConexaoInfoSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 20 : 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                'pk_title'.tr,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCodeSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Código principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _currentCode.isEmpty
                    ? SizedBox(
                        height: isSmallScreen ? 36 : 48,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentCode,
                        style: AppTheme.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 36 : 48,
                          letterSpacing: isSmallScreen ? 6 : 8,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              if (_isSendingCode && _currentCode.isNotEmpty) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Botão copiar
          GestureDetector(
            onTap: _currentCode.isEmpty ? null : () => _copyCode(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 24, 
                vertical: isSmallScreen ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Text(
                    'pk_copy'.tr,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _timeRemaining < 30 
            ? Colors.red.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _timeRemaining < 30 
              ? Colors.red.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: _timeRemaining < 30 ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${'pk_expires'.tr} ${_formatTime(_timeRemaining)}',
            style: AppTheme.titleMedium.copyWith(
              color: _timeRemaining < 30 ? Colors.red : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.8),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'pk_info'.tr,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoItemSimple(
            Icons.timer,
            'pk_valid_2min'.tr,
            'pk_code_expires'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          _buildInfoItemSimple(
            Icons.security,
            'pk_secure_access'.tr,
            'pk_logs_registered'.tr,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItemSimple(IconData icon, String title, String subtitle, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: isSmallScreen ? 14 : 16,
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.white.withOpacity(0.8),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'pk_how_to_use'.tr,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInstructionStep(
            '1',
            'pk_step1'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          _buildInstructionStep(
            '2',
            'pk_step2'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          _buildInstructionStep(
            '3',
            'pk_step3'.tr,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 20 : 24,
          height: isSmallScreen ? 20 : 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Widget _buildMedicoConectadoSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services,
              color: Colors.green,
              size: isSmallScreen ? 40 : 50,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Text(
            'pk_doctor_connected'.tr,
            style: AppTheme.headlineSmall.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 20 : 24,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          if (_medicoNome != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Flexible(
                    child: Text(
                      _medicoNome!,
                      style: AppTheme.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
          ],
          
          if (_medicoEspecialidade != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    color: Colors.white.withOpacity(0.9),
                    size: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Flexible(
                    child: Text(
                      _medicoEspecialidade!,
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.orange,
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Text(
                  _formatConnectionTime(_tempoConectado),
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConexaoInfoSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.9),
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                'pk_about_connection'.tr,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          _buildInfoItem(
            Icons.security,
            'pk_secure_connection'.tr,
            'pk_secure_connection_desc'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoItem(
            Icons.visibility,
            'pk_temp_access'.tr,
            'pk_temp_access_desc'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoItem(
            Icons.block,
            'pk_you_control'.tr,
            'pk_you_control_desc'.tr,
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 24 : 32),
          
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isDesconectando ? null : _desconectarMedico,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 16 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.transparent,
                ),
              child: _isDesconectando
                  ? SizedBox(
                      height: isSmallScreen ? 20 : 24,
                      width: isSmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off,
                          size: isSmallScreen ? 22 : 24,
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Text(
                          'pk_disconnect'.tr,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String title, String subtitle, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: isSmallScreen ? 18 : 20,
        ),
        SizedBox(width: isSmallScreen ? 12 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 15 : 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isSmallScreen ? 13 : 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

