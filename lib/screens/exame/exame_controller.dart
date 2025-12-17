import 'package:get/get.dart';
import '../../models/exame.dart';
import '../../services/exame_service.dart';

class ExameController extends GetxController {
  final ExameService _service = Get.put(ExameService());

  var exames = <Exame>[].obs;
  var mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month).obs;
  RxList<Exame> examesFiltrados = <Exame>[].obs;
  var isLoading = false.obs;

  // Filtros
  var filtroNome = ''.obs;
  var filtroCategoria = ''.obs;
  var filtroInicio = Rxn<DateTime>();
  var filtroFim = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    ever(exames, (_) => _filtrar());
    everAll([mesSelecionado, filtroNome, filtroCategoria, filtroInicio, filtroFim], (_) => _filtrar());
  }

  void _filtrar() {
    final start = filtroInicio.value;
    final end = filtroFim.value;
    final nome = filtroNome.value.trim().toLowerCase();
    final cat = filtroCategoria.value.trim().toLowerCase();

    examesFiltrados.value = exames.where((e) {
      final byName = nome.isEmpty || e.nome.toLowerCase().contains(nome);
      final byCat = cat.isEmpty || e.categoria.toLowerCase().contains(cat);
      
      final eDateOnly = DateTime(e.data.year, e.data.month, e.data.day);
      
      final byStart = start == null || !eDateOnly.isBefore(DateTime(start.year, start.month, start.day));
      final byEnd = end == null || !eDateOnly.isAfter(DateTime(end.year, end.month, end.day));
      
      return byName && byCat && byStart && byEnd;
    }).toList();
    
    examesFiltrados.sort((a, b) => b.data.compareTo(a.data));
  }

  Future<void> carregarExames(String pacienteId) async {
    isLoading.value = true;
    try {
      exames.value = await _service.getByPaciente(pacienteId);
      _filtrar();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> adicionarExame(Exame exame) async {
    final created = await _service.create(exame);
    exames.add(created);
  }

  Future<void> removerExame(String exameId) async {
    await _service.delete(exameId);
    exames.removeWhere((e) => e.id == exameId);
    _filtrar();
  }

  Future<void> removerExameByObject(Exame exame) async {
    await _service.deleteByObject(exame);
    exames.removeWhere((e) =>
        (e.id != null && e.id == exame.id) ||
        (e.id == null && e.filePath == exame.filePath && e.nome == exame.nome));
    _filtrar();
  }
}


