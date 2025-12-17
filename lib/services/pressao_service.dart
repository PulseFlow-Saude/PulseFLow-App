import 'package:get/get.dart';
import 'database_service.dart';
import '../models/pressao_arterial.dart';

class PressaoService {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<PressaoArterial> create(PressaoArterial registro) async {
    return _db.createPressao(registro);
  }

  Future<List<PressaoArterial>> getByPacienteId(String pacienteId) async {
    return _db.getPressoesByPacienteId(pacienteId);
  }
}


