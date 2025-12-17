import 'package:get/get.dart';
import '../../models/pressao_arterial.dart';
import '../../services/pressao_service.dart';

class PressaoController extends GetxController {
  final PressaoService _service = Get.put(PressaoService());

  var registros = <PressaoArterial>[].obs;
  var mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month).obs;
  RxList<PressaoArterial> registrosFiltrados = <PressaoArterial>[].obs;

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
    _filtrarRegistros();
  }

  Future<void> adicionarRegistro({
    required String pacienteId,
    required double sistolica,
    required double diastolica,
    required DateTime data,
  }) async {
    final registro = PressaoArterial(
      pacienteId: pacienteId,
      data: data,
      sistolica: sistolica,
      diastolica: diastolica,
    );
    final criado = await _service.create(registro);
    registros.add(criado);
  }
}


