import 'package:get/get.dart';
import '../../models/diabetes.dart';
import '../../services/diabetes_service.dart';

class DiabetesController extends GetxController {
  final DiabetesService _service = Get.put(DiabetesService());

  var registros = <Diabetes>[].obs;
  var mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month).obs;
  RxList<Diabetes> registrosFiltrados = <Diabetes>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(registros, (_) => _filtrarRegistros());
    ever(mesSelecionado, (_) => _filtrarRegistros());
  }

  void _filtrarRegistros() {
    registrosFiltrados.value = registros.where((e) {
      return e.data.year == mesSelecionado.value.year &&
          e.data.month == mesSelecionado.value.month;
    }).toList();
  }

  Future<void> carregarRegistros(String pacienteId) async {
    registros.value = await _service.getByPacienteId(pacienteId);
    for (final registro in registros) {
    }
    _filtrarRegistros(); // Initial filtering after loading
  }

  Future<void> adicionarRegistro({
    required String pacienteId,
    required double glicemia,
    required String unidade,
    required DateTime data,
  }) async {
    final registro = Diabetes(
      pacienteId: pacienteId,
      data: data,
      glicemia: glicemia,
      unidade: unidade,
    );

    final criado = await _service.create(registro);
    registros.add(criado);
  }
}

