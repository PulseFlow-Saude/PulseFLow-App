import 'package:get/get.dart';
import '../models/diabetes.dart';
import 'database_service.dart';

class DiabetesService {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<Diabetes> create(Diabetes registro) async {
    return _db.createDiabetes(registro);
  }

  Future<List<Diabetes>> getByPacienteId(String pacienteId) async {
    return _db.getDiabetesByPacienteId(pacienteId);
  }
}

