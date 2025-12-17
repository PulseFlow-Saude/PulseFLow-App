import 'dart:async';
import 'package:get/get.dart';
import '../api_service.dart';
import '../auth_service.dart';
import '../notification_service.dart';

/// Gerenciador de verificação de solicitações de acesso médico
class AccessRequestChecker {
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final Set<String> _shownRequests = {};

  /// Iniciar verificação periódica
  void startPeriodicCheck() {
    // Verificar após 5 segundos
    Future.delayed(const Duration(seconds: 5), () async {
      await _checkPendingRequests();
    });

    // Verificar a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkPendingRequests();
    });
  }

  /// Parar verificação periódica
  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
  }

  /// Verificar solicitações pendentes
  Future<void> _checkPendingRequests() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null || currentUser.id == null) {
        return;
      }

      final requests = await _apiService.buscarSolicitacoesPendentes(currentUser.id!);

      for (var request in requests) {
        final requestId = request['id'].toString();
        final doctorName = request['medicoNome'] ?? 'Um médico';
        final specialty = request['especialidade'] ?? '';

        if (!_shownRequests.contains(requestId)) {
          await _showAccessRequestNotification(
            doctorName: doctorName,
            specialty: specialty,
            requestId: requestId,
          );

          _shownRequests.add(requestId);
          await _apiService.marcarSolicitacaoVisualizada(requestId);
        }
      }
    } catch (e) {
      // Erro ao verificar solicitações
    }
  }

  /// Exibir notificação de solicitação de acesso
  Future<void> _showAccessRequestNotification({
    required String doctorName,
    required String specialty,
    required String requestId,
  }) async {
    try {
      final notificationService = Get.find<NotificationService>();
      await notificationService.showDoctorAccessRequestNotification(
        doctorName: doctorName,
        specialty: specialty,
        requestId: requestId,
      );
    } catch (e) {
      // Erro ao exibir notificação
    }
  }

  /// Verificar manualmente (para testes)
  Future<void> checkManually() async {
    await _checkPendingRequests();
  }

  /// Limpar histórico de solicitações exibidas
  void clearShownRequests() {
    _shownRequests.clear();
  }

  /// Dispose
  void dispose() {
    stopPeriodicCheck();
    _shownRequests.clear();
  }
}

