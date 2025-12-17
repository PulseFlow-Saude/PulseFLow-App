import 'package:get/get.dart';

class PacienteController extends GetxController {
  var pacienteId = ''.obs;

  void setPacienteId(String id) {
    pacienteId.value = id;
  }

  // Compatibilidade com chamadas antigas
  void setPatientId(String id) {
    pacienteId.value = id;
  }
}
