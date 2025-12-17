import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class MenuController extends GetxController {
  void goToEnxaqueca() {
    Get.toNamed(Routes.ENXAQUECA);
  }

  void goToHistorico() {
    Get.toNamed(Routes.MEDICAL_RECORDS); // Tela de histórico
  }
}
