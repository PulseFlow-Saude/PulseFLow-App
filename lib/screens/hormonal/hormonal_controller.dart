import 'package:get/get.dart';
import '../../models/hormonal.dart';
import '../../services/database_service.dart';

class HormonalController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var registros = <Hormonal>[].obs;
  var mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month).obs;
  RxList<Hormonal> registrosFiltrados = <Hormonal>[].obs;

  // Filtros
  var filtroHormonio = ''.obs; // por nome
  var filtroInicio = Rxn<DateTime>();
  var filtroFim = Rxn<DateTime>();
  var hormoniosSugeridos = <String>{
    'TSH', 'T3', 'T4', 'FT3', 'FT4',
    'Cortisol', 'ACTH', 'Prolactina',
    'LH', 'FSH', 'Estradiol', 'Progesterona',
    'Testosterona Total', 'Testosterona Livre', 'SHBG',
    'DHEA-S', 'Insulina', 'GH', 'IGF-1',
    'PTH', 'Calcitonina', 'Aldosterona', 'Renina',
    '17-OH-Progesterona', 'Androstenediona', 'Estriol', 'Estrona',
    'HCG', 'Anti-TPO', 'Anti-Tg'
  }.obs;

  // Disponíveis a partir dos dados e seleção para o gráfico
  var hormoniosDisponiveis = <String>[].obs;
  var hormoniosSelecionados = <String>[].obs; // vazio = todos

  @override
  void onInit() {
    super.onInit();
    ever(registros, (_) => _filtrarRegistros());
    everAll([mesSelecionado, filtroHormonio, filtroInicio, filtroFim], (_) => _filtrarRegistros());
    ever(hormoniosSelecionados, (_) => _filtrarRegistros());
  }

  void _filtrarRegistros() {
    final start = filtroInicio.value;
    final end = filtroFim.value;
    final term = filtroHormonio.value.trim().toLowerCase();

    registrosFiltrados.value = registros.where((e) {
      final byMonth = e.data.year == mesSelecionado.value.year && e.data.month == mesSelecionado.value.month;
      if (!byMonth) return false;
      final bySelected = hormoniosSelecionados.isEmpty || hormoniosSelecionados.contains(e.hormonio);
      final byName = term.isEmpty || e.hormonio.toLowerCase().contains(term);
      final byStart = start == null || !e.data.isBefore(DateTime(start.year, start.month, start.day));
      final byEnd = end == null || !e.data.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
      return bySelected && byName && byStart && byEnd;
    }).toList();
  }

  // Método público para forçar re-avaliação dos filtros
  void applyFilters() => _filtrarRegistros();

  Future<void> carregarRegistros(String pacienteId) async {
    // Coleção generica via DatabaseService
    final col = await _db.getCollection('hormonais');
    final list = await col.find({'paciente': pacienteId}).toList();
    final mapped = list.map((m) {
      final mm = Map<String, dynamic>.from(m);
      mm['_id'] = mm['_id'].toString();
      if (mm['paciente'] != null) mm['paciente'] = mm['paciente'].toString();
      return Hormonal.fromMap(mm);
    }).toList();
    registros.value = mapped;
    _atualizarDisponiveis();
    _filtrarRegistros();
  }

  Future<void> adicionarRegistro({
    required String pacienteId,
    required String hormonio,
    required double valor,
    required DateTime data,
  }) async {
    final col = await _db.getCollection('hormonais');
    final doc = {
      'paciente': pacienteId,
      'hormonio': hormonio,
      'valor': valor,
      'data': data.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await col.insert(doc);
    registros.add(Hormonal(
      id: doc['_id']?.toString(),
      paciente: pacienteId,
      hormonio: hormonio,
      valor: valor,
      data: data,
    ));
    _atualizarDisponiveis();
  }

  void _atualizarDisponiveis() {
    final set = <String>{};
    for (final r in registros) {
      if (r.hormonio.trim().isNotEmpty) set.add(r.hormonio.trim());
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    hormoniosDisponiveis.assignAll(list);
    if (hormoniosSelecionados.isEmpty) {
      hormoniosSelecionados.assignAll(list);
    } else {
      // remove selecionados que não existem mais
      hormoniosSelecionados.removeWhere((h) => !set.contains(h));
    }
  }
}


