import 'package:get/get.dart';
import 'database_service.dart';
import '../../models/enxaqueca.dart';

class EnxaquecaService {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<Enxaqueca> create(Enxaqueca enxaqueca) async {
    return _db.createEnxaqueca(enxaqueca);
  }

  Future<List<Enxaqueca>> getByPacienteId(String pacienteId) async {
    return _db.getEnxaquecasByPacienteId(pacienteId);
  }
}
