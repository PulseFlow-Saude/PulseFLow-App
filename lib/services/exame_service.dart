import 'package:get/get.dart';
import '../models/exame.dart';
import 'database_service.dart';
import 'api_service.dart';

class ExameService {
  final DatabaseService _db = Get.find<DatabaseService>();
  final ApiService _apiService = ApiService();

  Future<Exame> create(Exame exame) async {
    return _db.createExame(exame);
  }

  Future<List<Exame>> getByPaciente(String pacienteId) async {
    try {
      final examesApi = await _apiService.buscarExamesPaciente();
      
      final exames = examesApi.map((map) {
        return Exame.fromMap(map);
      }).toList();

      final examesLocais = await _db.getExamesByPaciente(pacienteId);
      
      for (final exame in exames) {
        final jaExiste = examesLocais.any((e) => 
          (e.id != null && exame.id != null && e.id == exame.id) ||
          (e.filePath == exame.filePath && e.nome == exame.nome && 
           e.data.year == exame.data.year && 
           e.data.month == exame.data.month && 
           e.data.day == exame.data.day)
        );
        
        if (!jaExiste) {
          try {
            await _db.createExame(exame);
          } catch (_) {}
        }
      }

      return exames;
    } catch (e) {
      return await _db.getExamesByPaciente(pacienteId);
    }
  }

  Future<void> delete(String exameId) async {
    await _db.deleteExame(exameId);
  }

  Future<void> deleteByObject(Exame exame) async {
    await _db.deleteExameByObject(exame);
  }
}


