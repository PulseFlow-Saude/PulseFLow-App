import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/access_history.dart';

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

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dataHora);
    } else if (difference.inDays == 1) {
      return 'Ontem às ${DateFormat('HH:mm').format(dataHora)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás às ${DateFormat('HH:mm').format(dataHora)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dataHora);
    }
  }

  String formatarDataCompleta(DateTime dataHora) {
    return DateFormat('dd/MM/yyyy às HH:mm').format(dataHora);
  }
}

