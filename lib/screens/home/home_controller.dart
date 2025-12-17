import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/patient.dart';
import '../../models/enxaqueca.dart';
import '../../models/diabetes.dart';
import '../../models/crise_gastrite.dart';
import '../../models/evento_clinico.dart';
import '../../models/menstruacao.dart';
import '../../utils/greeting_utils.dart';

class AppointmentBooking {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialtyId;
  final String specialtyName;
  final DateTime startTime;
  final Duration duration;
  final String status;

  AppointmentBooking({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialtyId,
    required this.specialtyName,
    required this.startTime,
    this.duration = const Duration(minutes: 30),
    this.status = 'agendada',
  });
}

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  
  // Observáveis para os dados do paciente
  final _currentPatient = Rxn<Patient>();
  final _isLoading = false.obs;
  
  // Dados para atalhos
  final _hasEnxaqueca = false.obs;
  final _hasDiabetes = false.obs;
  final _hasCriseGastrite = false.obs;
  final _hasEventoClinico = false.obs;
  final _hasMenstruacao = false.obs;
  
  // Favoritos personalizáveis
  final _favoriteItems = <String>[].obs;
  
  // Dados para estatísticas
  final _enxaquecaData = <Enxaqueca>[].obs;
  final _diabetesData = <Diabetes>[].obs;
  final _gastriteData = <CriseGastrite>[].obs;
  final _eventoClinicoData = <EventoClinico>[].obs;
  final _menstruacaoData = <Menstruacao>[].obs;
  
  // Contador de notificações
  final RxInt unreadNotificationsCount = 0.obs;
  
  // Consultas agendadas
  final RxList<AppointmentBooking> upcomingAppointments = <AppointmentBooking>[].obs;
  final RxBool isLoadingAppointments = false.obs;
  
  // Getters
  Patient? get currentPatient => _currentPatient.value;
  bool get isLoading => _isLoading.value;
  
  // Getters para atalhos
  bool get hasEnxaqueca => _hasEnxaqueca.value;
  bool get hasDiabetes => _hasDiabetes.value;
  bool get hasCriseGastrite => _hasCriseGastrite.value;
  bool get hasEventoClinico => _hasEventoClinico.value;
  bool get hasMenstruacao => _hasMenstruacao.value;
  
  // Getters para favoritos
  List<String> get favoriteItems => _favoriteItems;
  
  @override
  void onInit() {
    super.onInit();
    _loadPatientData();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    _isLoading.value = true;
    try {
      await Future.wait([
        _loadAvailableData(),
        loadNotificationsCount(),
        loadUpcomingAppointments(),
      ]);
    } catch (e) {
      print('❌ [HomeController] Erro ao inicializar dados: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadNotificationsCount() async {
    try {
      final apiService = ApiService();
      final count = await apiService.buscarContadorNotificacoesNaoLidas();
      unreadNotificationsCount.value = count;
    } catch (e) {
      unreadNotificationsCount.value = 0;
    }
  }
  
  Future<void> loadUpcomingAppointments() async {
    isLoadingAppointments.value = true;
    try {
      final apiService = ApiService();
      final dataInicio = DateTime.now();
      final dataFim = dataInicio.add(const Duration(days: 30));
      
      final agendamentos = await apiService.buscarAgendamentosPaciente(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      final appointmentsList = <AppointmentBooking>[];
      
      for (final agendamento in agendamentos) {
        try {
          final id = agendamento['_id']?.toString() ?? '';
          final medicoId = agendamento['medicoId']?.toString() ?? 
                          agendamento['medicoId']?['_id']?.toString() ?? '';
          final medicoNome = agendamento['medicoId']?['nome']?.toString() ?? 
                            'Médico não informado';
          final areaAtuacao = agendamento['medicoId']?['areaAtuacao']?.toString() ?? 
                             'Especialidade não informada';
          
          DateTime startTime;
          int duracao;
          
          if (agendamento['data'] != null && agendamento['horaInicio'] != null) {
            final dataStr = agendamento['data']?.toString() ?? '';
            final horaInicio = agendamento['horaInicio']?.toString() ?? '00:00';
            final parts = horaInicio.split(':');
            final ano = int.parse(dataStr.split('-')[0]);
            final mes = int.parse(dataStr.split('-')[1]);
            final dia = int.parse(dataStr.split('-')[2].split('T')[0]);
            final hora = int.parse(parts[0]);
            final minuto = int.parse(parts[1]);
            startTime = DateTime(ano, mes, dia, hora, minuto);
            duracao = agendamento['duracao'] as int? ?? 30;
          } else {
            startTime = DateTime.now();
            duracao = 30;
          }
          
          final status = agendamento['status']?.toString() ?? 'agendada';
          
          // Só adicionar consultas futuras (incluindo hoje) com status agendada
          final now = DateTime.now();
          final appointmentDate = DateTime(startTime.year, startTime.month, startTime.day);
          final today = DateTime(now.year, now.month, now.day);
          final isFutureOrToday = appointmentDate.isAfter(today.subtract(const Duration(days: 1))) || appointmentDate.isAtSameMomentAs(today);
          final isAgendada = status.toLowerCase() == 'agendada';
          
          if (isFutureOrToday && isAgendada) {
            appointmentsList.add(AppointmentBooking(
              id: id,
              doctorId: medicoId,
              doctorName: medicoNome,
              specialtyId: areaAtuacao,
              specialtyName: areaAtuacao,
              startTime: startTime,
              duration: Duration(minutes: duracao),
              status: status,
            ));
          }
        } catch (e) {
          continue;
        }
      }
      
      // Ordenar por data
      appointmentsList.sort((a, b) => a.startTime.compareTo(b.startTime));
      upcomingAppointments.value = appointmentsList;
      upcomingAppointments.refresh();
      
      // Debug: imprimir quantidade de consultas encontradas
      print('📅 [HomeController] Consultas agendadas encontradas: ${appointmentsList.length}');
    } catch (e) {
      print('❌ [HomeController] Erro ao carregar consultas: $e');
      upcomingAppointments.value = [];
    } finally {
      isLoadingAppointments.value = false;
    }
  }
  
  // Carrega os dados do paciente logado
  void _loadPatientData() {
    _currentPatient.value = _authService.currentUser;
  }
  
  // Carrega dados disponíveis do paciente
  Future<void> _loadAvailableData() async {
    if (currentPatient?.id == null) {
      print('⚠️ [HomeController] Paciente não encontrado');
      return;
    }
    
    try {
      final patientId = currentPatient!.id!;
      print('📊 [HomeController] Carregando dados do paciente: $patientId');
      
      // Carrega todos os dados do paciente
      final enxaquecas = await _databaseService.getEnxaquecasByPacienteId(patientId);
      final diabetes = await _databaseService.getDiabetesByPacienteId(patientId);
      final crisesGastrite = await _databaseService.getCrisesGastriteByPacienteId(patientId);
      final eventosClinicos = await _databaseService.getEventosClinicosByPacienteId(patientId);
      final menstruacoes = await _databaseService.getMenstruacoesByPacienteId(patientId);
      
      print('📊 [HomeController] Dados carregados - Enxaqueca: ${enxaquecas.length}, Diabetes: ${diabetes.length}, Gastrite: ${crisesGastrite.length}, Eventos: ${eventosClinicos.length}, Menstruação: ${menstruacoes.length}');
      
      // Armazena os dados para estatísticas
      _enxaquecaData.value = enxaquecas;
      _diabetesData.value = diabetes;
      _gastriteData.value = crisesGastrite;
      _eventoClinicoData.value = eventosClinicos;
      _menstruacaoData.value = menstruacoes;
      
      // Verifica quais tipos de dados o paciente tem
      _hasEnxaqueca.value = enxaquecas.isNotEmpty;
      _hasDiabetes.value = diabetes.isNotEmpty;
      _hasCriseGastrite.value = crisesGastrite.isNotEmpty;
      _hasEventoClinico.value = eventosClinicos.isNotEmpty;
      _hasMenstruacao.value = menstruacoes.isNotEmpty;
      
      // Inicializa favoritos com dados disponíveis
      _updateFavoriteItems();
      
      print('✅ [HomeController] Dados carregados com sucesso');
    } catch (e, stackTrace) {
      print('❌ [HomeController] Erro ao carregar dados disponíveis: $e');
      print('❌ [HomeController] Stack trace: $stackTrace');
    }
  }

  // Atualiza os dados do paciente
  Future<void> refreshPatientData() async {
    _isLoading.value = true;
    try {
      // Recarrega os dados do usuário atual
      await _authService.init();
      _currentPatient.value = _authService.currentUser;
      await _loadAvailableData();
      await loadNotificationsCount();
      await loadUpcomingAppointments();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os dados do paciente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Obtém saudação baseada no horário
  String getGreeting() {
    return buildGreetingMessage();
  }
  
  // Obtém o nome do paciente
  String getPatientName() {
    return currentPatient?.name ?? 'Usuário';
  }
  
  // Obtém a foto de perfil do paciente
  String? getProfilePhoto() {
    return currentPatient?.profilePhoto;
  }

  // Verifica se a foto é base64
  bool isBase64Photo(String? photo) {
    if (photo == null) return false;
    return photo.startsWith('data:image/');
  }

  // Atualiza lista de favoritos baseada nos dados disponíveis
  void _updateFavoriteItems() {
    final availableItems = <String>[];
    
    if (_hasEnxaqueca.value) availableItems.add('enxaqueca');
    if (_hasDiabetes.value) availableItems.add('diabetes');
    if (_hasCriseGastrite.value) availableItems.add('crise_gastrite');
    if (_hasEventoClinico.value) availableItems.add('evento_clinico');
    if (_hasMenstruacao.value) availableItems.add('menstruacao');
    
    // Se não há favoritos definidos, usa os primeiros 3 disponíveis
    if (_favoriteItems.isEmpty && availableItems.isNotEmpty) {
      _favoriteItems.value = availableItems.take(3).toList();
    }
  }

  // Adiciona item aos favoritos
  void addToFavorites(String item) {
    if (!_favoriteItems.contains(item) && _favoriteItems.length < 4) {
      _favoriteItems.add(item);
    }
  }

  // Remove item dos favoritos
  void removeFromFavorites(String item) {
    _favoriteItems.remove(item);
  }

  // Verifica se há dados disponíveis
  bool get hasAnyData {
    return _hasEnxaqueca.value || 
           _hasDiabetes.value || 
           _hasCriseGastrite.value || 
           _hasEventoClinico.value || 
           _hasMenstruacao.value;
  }

  // Calcula estatísticas para enxaqueca
  Map<String, dynamic> getEnxaquecaStats() {
    if (_enxaquecaData.isEmpty) return {};
    
    final sorted = List<Enxaqueca>.from(_enxaquecaData)..sort((a, b) => b.data.compareTo(a.data));
    final ultimaCrise = sorted.first;
    final intensidades = _enxaquecaData.map((e) => int.tryParse(e.intensidade) ?? 0).toList();
    final maior = intensidades.reduce((a, b) => a > b ? a : b);
    final menor = intensidades.reduce((a, b) => a < b ? a : b);
    final media = intensidades.reduce((a, b) => a + b) / intensidades.length;
    
    // Calcular frequência (crises nos últimos 30 dias)
    final now = DateTime.now();
    final ultimos30Dias = now.subtract(const Duration(days: 30));
    final crisesUltimos30Dias = _enxaquecaData.where((e) => e.data.isAfter(ultimos30Dias)).length;
    
    // Dias desde última crise
    final diasDesdeUltima = now.difference(ultimaCrise.data).inDays;
    
    return {
      'maior': maior,
      'menor': menor,
      'media': media.round(),
      'total': intensidades.length,
      'ultimaCrise': ultimaCrise.data,
      'diasDesdeUltima': diasDesdeUltima,
      'frequencia30Dias': crisesUltimos30Dias,
      'ultimaIntensidade': int.tryParse(ultimaCrise.intensidade) ?? 0,
    };
  }

  // Calcula estatísticas para diabetes
  Map<String, dynamic> getDiabetesStats() {
    if (_diabetesData.isEmpty) return {};
    
    final sorted = List<Diabetes>.from(_diabetesData)..sort((a, b) => b.data.compareTo(a.data));
    final ultimaMedicao = sorted.first;
    final glicoses = _diabetesData.map((d) => d.glicemia).toList();
    final maior = glicoses.reduce((a, b) => a > b ? a : b);
    final menor = glicoses.reduce((a, b) => a < b ? a : b);
    final media = glicoses.reduce((a, b) => a + b) / glicoses.length;
    
    // Status baseado na última medição (mg/dL)
    String status = 'Normal';
    if (ultimaMedicao.unidade == 'mg/dL') {
      if (ultimaMedicao.glicemia < 70) {
        status = 'Baixa';
      } else if (ultimaMedicao.glicemia > 180) {
        status = 'Alta';
      }
    } else {
      // mmol/L
      if (ultimaMedicao.glicemia < 3.9) {
        status = 'Baixa';
      } else if (ultimaMedicao.glicemia > 10.0) {
        status = 'Alta';
      }
    }
    
    // Dias desde última medição
    final now = DateTime.now();
    final diasDesdeUltima = now.difference(ultimaMedicao.data).inDays;
    
    // Média dos últimos 7 dias
    final ultimos7Dias = now.subtract(const Duration(days: 7));
    final medicoes7Dias = _diabetesData.where((d) => d.data.isAfter(ultimos7Dias)).toList();
    final media7Dias = medicoes7Dias.isEmpty 
        ? null 
        : medicoes7Dias.map((d) => d.glicemia).reduce((a, b) => a + b) / medicoes7Dias.length;
    
    return {
      'maior': maior,
      'menor': menor,
      'media': media.round(),
      'total': glicoses.length,
      'ultimaMedicao': ultimaMedicao.data,
      'ultimaGlicemia': ultimaMedicao.glicemia.round(),
      'unidade': ultimaMedicao.unidade,
      'status': status,
      'diasDesdeUltima': diasDesdeUltima,
      'media7Dias': media7Dias?.round(),
    };
  }

  // Calcula estatísticas para gastrite
  Map<String, dynamic> getGastriteStats() {
    if (_gastriteData.isEmpty) return {};
    
    final sorted = List<CriseGastrite>.from(_gastriteData)..sort((a, b) => b.data.compareTo(a.data));
    final ultimaCrise = sorted.first;
    final intensidades = _gastriteData.map((g) => g.intensidadeDor).toList();
    final maior = intensidades.reduce((a, b) => a > b ? a : b);
    final menor = intensidades.reduce((a, b) => a < b ? a : b);
    final media = intensidades.reduce((a, b) => a + b) / intensidades.length;
    
    // Calcular frequência (crises nos últimos 30 dias)
    final now = DateTime.now();
    final ultimos30Dias = now.subtract(const Duration(days: 30));
    final crisesUltimos30Dias = _gastriteData.where((e) => e.data.isAfter(ultimos30Dias)).length;
    
    // Dias desde última crise
    final diasDesdeUltima = now.difference(ultimaCrise.data).inDays;
    
    return {
      'maior': maior,
      'menor': menor,
      'media': media.round(),
      'total': intensidades.length,
      'ultimaCrise': ultimaCrise.data,
      'diasDesdeUltima': diasDesdeUltima,
      'frequencia30Dias': crisesUltimos30Dias,
      'ultimaIntensidade': ultimaCrise.intensidadeDor,
    };
  }

  // Calcula estatísticas para eventos clínicos
  Map<String, dynamic> getEventoClinicoStats() {
    if (_eventoClinicoData.isEmpty) return {};
    
    final now = DateTime.now();
    final sorted = List<EventoClinico>.from(_eventoClinicoData)..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final ultimoEvento = sorted.first;
    
    // Eventos futuros
    final eventosFuturos = _eventoClinicoData.where((e) => e.dataHora.isAfter(now)).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    final proximoEvento = eventosFuturos.isNotEmpty ? eventosFuturos.first : null;
    
    // Eventos deste mês
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final thisMonthEvents = _eventoClinicoData.where((e) {
      final eventDate = e.dataHora;
      return eventDate.isAfter(lastMonth) && eventDate.isBefore(thisMonth.add(const Duration(days: 31)));
    }).length;
    
    return {
      'total': _eventoClinicoData.length,
      'este_mes': thisMonthEvents,
      'ultimoEvento': ultimoEvento.dataHora,
      'proximoEvento': proximoEvento?.dataHora,
      'totalFuturos': eventosFuturos.length,
    };
  }

  // Calcula estatísticas para menstruação
  Map<String, dynamic> getMenstruacaoStats() {
    if (_menstruacaoData.isEmpty) return {};
    
    final sorted = List<Menstruacao>.from(_menstruacaoData)..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
    final ultimaMenstruacao = sorted.first;
    
    final duracoes = _menstruacaoData.map((m) => m.duracaoEmDias).toList();
    final maior = duracoes.reduce((a, b) => a > b ? a : b);
    final menor = duracoes.reduce((a, b) => a < b ? a : b);
    final media = duracoes.reduce((a, b) => a + b) / duracoes.length;
    
    // Calcular ciclo médio (dias entre menstruações)
    int? cicloMedio;
    if (sorted.length > 1) {
      final ciclos = <int>[];
      for (int i = 0; i < sorted.length - 1; i++) {
        final dias = sorted[i].dataInicio.difference(sorted[i + 1].dataInicio).inDays;
        ciclos.add(dias);
      }
      if (ciclos.isNotEmpty) {
        cicloMedio = (ciclos.reduce((a, b) => a + b) / ciclos.length).round();
      }
    }
    
    // Próximo ciclo esperado
    DateTime? proximoCiclo;
    if (cicloMedio != null) {
      proximoCiclo = ultimaMenstruacao.dataInicio.add(Duration(days: cicloMedio));
    }
    
    // Dias desde última menstruação
    final now = DateTime.now();
    final diasDesdeUltima = now.difference(ultimaMenstruacao.dataInicio).inDays;
    
    return {
      'maior': maior,
      'menor': menor,
      'media': media.round(),
      'total': duracoes.length,
      'ultimaMenstruacao': ultimaMenstruacao.dataInicio,
      'diasDesdeUltima': diasDesdeUltima,
      'cicloMedio': cicloMedio,
      'proximoCiclo': proximoCiclo,
      'duracaoAtual': ultimaMenstruacao.duracaoEmDias,
    };
  }


  Future<void> logout() async {
    try {
      await _authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível fazer logout. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
} 