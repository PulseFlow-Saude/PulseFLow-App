import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../models/access_history.dart';
import '../../utils/intl_locale.dart';

class AccessHistoryController extends GetxController {
  final RxList<AccessHistory> acessos = <AccessHistory>[].obs;
  final RxBool isLoading = false.obs;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    carregarHistoricoAcessos();
  }

  Future<void> carregarHistoricoAcessos() async {
    isLoading.value = true;
    
    try {
      final dados = await _apiService.buscarHistoricoAcessos();
      
      final acessosList = dados.map((acesso) {
        try {
          return AccessHistory.fromJson(acesso);
        } catch (e) {
          return null;
        }
      }).whereType<AccessHistory>().toList();
      
      acessos.value = acessosList;
      acessos.refresh();
    } catch (e) {
      acessos.value = [];
      acessos.refresh();
      Get.snackbar(
        'Erro',
        'Erro ao carregar histórico de acessos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String formatarDataHora(DateTime dataHora) {
    final now = DateTime.now();
    final difference = now.difference(dataHora);
    final timeStr = AppDateFormat.time.format(dataHora);

    if (difference.inDays == 0) {
      return timeStr;
    } else if (difference.inDays == 1) {
      return '${'intl_yesterday'.tr} ${'intl_at'.tr} $timeStr';
    } else if (difference.inDays < 7) {
      return '${'intl_days_ago'.trParams({'count': '${difference.inDays}'})} ${'intl_at'.tr} $timeStr';
    } else {
      return AppDateFormat.shortDateTime.format(dataHora);
    }
  }

  String formatarDataCompleta(DateTime dataHora) {
    return AppDateFormat.shortDateTime.format(dataHora);
  }
}

