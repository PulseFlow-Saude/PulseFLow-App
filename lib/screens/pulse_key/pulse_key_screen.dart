import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
  bool _isActive = true;
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
            'Aviso',
            'Usuário não autenticado. O código está disponível mas não será sincronizado.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      await _apiService.sendAccessCode(
        patientId: currentUser.id!,
        accessCode: code,
        expiresAt: expiresAt,
      );
      
      print('✅ [PulseKeyScreen] Código sincronizado com sucesso');
      
    } catch (e) {
      // Não bloquear a funcionalidade - o código ainda funciona localmente
      if (mounted) {
        String errorMessage = 'Não foi possível sincronizar com o servidor.';
        String fullError = e.toString();
        
        // Debug: mostrar erro completo no console
        print('⚠️ [PulseKeyScreen] Erro de sincronização (código ainda funciona): $fullError');
        
        // Detectar tipo de erro específico
        if (fullError.contains('Token de autenticação não encontrado') || 
            fullError.contains('Sessão expirada')) {
          errorMessage = 'Sessão expirada. O código está disponível mas não será sincronizado.';
        } else if (fullError.contains('ngrok está offline') || 
                   fullError.contains('ERR_NGROK_3200') ||
                   fullError.contains('Túnel ngrok está offline')) {
          errorMessage = 'Túnel ngrok está offline.\n\nO código está disponível localmente, mas não será sincronizado até que o túnel seja reiniciado no servidor.';
        } else if (fullError.contains('Servidor não está acessível') ||
                   fullError.contains('URL do servidor inválida') || 
                   fullError.contains('não foi possível conectar ao servidor') ||
                   fullError.contains('Connection refused') ||
                   fullError.contains('Network is unreachable')) {
          // Para erros de conexão, mostrar aviso mais amigável
          errorMessage = 'Servidor não acessível. O código está disponível localmente.\n\nVerifique a conexão com o servidor nas configurações.';
        } else if (fullError.contains('CORS')) {
          errorMessage = 'Erro de configuração do servidor (CORS). O código está disponível localmente.';
        } else if (fullError.contains('401') || fullError.contains('Unauthorized')) {
          errorMessage = 'Sessão expirada. O código está disponível mas não será sincronizado.';
        } else if (fullError.contains('403') || fullError.contains('Forbidden')) {
          errorMessage = 'Acesso negado. O código está disponível localmente.';
        } else if (fullError.contains('ngrok offline') || 
                   fullError.contains('Túnel ngrok offline') ||
                   fullError.contains('ERR_NGROK_3200')) {
          errorMessage = 'Túnel ngrok offline. O código está disponível localmente.\n\nPara sincronizar, inicie o ngrok e atualize a URL no arquivo .env.';
        } else if (fullError.contains('404') || fullError.contains('not found')) {
          errorMessage = 'Endpoint não encontrado. O código está disponível localmente.';
        } else if (fullError.contains('500') || fullError.contains('Internal Server Error')) {
          errorMessage = 'Erro no servidor. O código está disponível localmente.';
        } else if (fullError.contains('Tempo de espera esgotado') || 
                   fullError.contains('Timeout')) {
          errorMessage = 'Servidor não respondeu. O código está disponível localmente.';
        }
        
        // Mostrar aviso (não erro) já que o código ainda funciona
        Get.snackbar(
          'Aviso de Sincronização',
          errorMessage,
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
      'Código copiado!',
      'O código foi copiado para a área de transferência',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _checkConnection() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.id == null) return;
    
    setState(() {
      _isLoadingConexao = true;
    });
    
    try {
      final conexao = await _apiService.verificarConexaoMedico(currentUser!.id!);
      
      if (mounted && conexao != null) {
        setState(() {
          _isMedicoConectado = conexao['conectado'] == true;
          if (_isMedicoConectado) {
            final medico = conexao['medico'] as Map<String, dynamic>?;
            _medicoNome = medico?['nome'] as String?;
            _medicoEspecialidade = medico?['especialidade'] as String?;
            _tempoConectado = conexao['tempoConectado'] as int? ?? 0;
          } else {
            _medicoNome = null;
            _medicoEspecialidade = null;
            _tempoConectado = 0;
          }
          _isLoadingConexao = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConexao = false;
        });
      }
    }
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
          });
          
          Get.snackbar(
            'Médico desconectado',
            'O médico foi desconectado com sucesso',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'Erro',
            'Não foi possível desconectar o médico',
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
          'Erro',
          'Erro ao desconectar médico',
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
                'Pulse Key',
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
                    'Copiar',
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
            'Expira em: ${_formatTime(_timeRemaining)}',
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
                'Informações',
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
            'Válido por 2 minutos',
            'Código expira automaticamente',
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          _buildInfoItemSimple(
            Icons.security,
            'Acesso seguro',
            'Logs de acesso registrados',
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
                'Como usar',
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
            'Compartilhe o código com seu médico',
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          _buildInstructionStep(
            '2',
            'Médico insere o código na plataforma',
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          _buildInstructionStep(
            '3',
            'Acesso temporário aos seus dados',
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
            'Médico Conectado',
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
                'Sobre a Conexão',
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
            'Conexão Segura',
            'Seu médico está visualizando seus dados de forma segura através do código de acesso',
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoItem(
            Icons.visibility,
            'Acesso Temporário',
            'O médico pode visualizar seus dados enquanto estiver conectado',
            isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoItem(
            Icons.block,
            'Você tem controle',
            'Você pode desconectar o médico a qualquer momento usando o botão abaixo',
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
                          'Desconectar Médico',
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
              SizedBox(height: 4),
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

