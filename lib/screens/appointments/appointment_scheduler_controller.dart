import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SpecialtyInfo {
  final String id;
  final String name;
  final Color color;
  final String description;

  SpecialtyInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
  });
}

class DoctorInfo {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String crm;
  final String experience;
  final Map<int, List<String>> weeklySlots;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    required this.crm,
    required this.experience,
    required this.weeklySlots,
  });
}

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

const List<Color> _specialtyColors = [
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFFF97316),
  Color(0xFFEC4899),
  Color(0xFF7C3AED),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
];

const List<Map<int, List<String>>> _slotTemplates = [
  {
    DateTime.monday: ['09:00', '09:30', '10:00', '10:30', '14:00', '14:30'],
    DateTime.wednesday: ['09:00', '09:30', '10:00', '10:30', '16:00'],
    DateTime.friday: ['08:30', '09:00', '09:30', '10:00'],
  },
  {
    DateTime.tuesday: ['08:00', '08:30', '09:00', '09:30', '13:00', '13:30'],
    DateTime.thursday: ['10:00', '10:30', '11:00', '11:30', '15:00', '15:30'],
  },
  {
    DateTime.monday: ['11:00', '11:30', '14:00', '14:30'],
    DateTime.thursday: ['09:00', '09:30', '10:00', '10:30', '16:00'],
    DateTime.saturday: ['09:00', '09:30', '10:00'],
  },
  {
    DateTime.tuesday: ['14:00', '14:30', '15:00', '15:30'],
    DateTime.wednesday: ['08:30', '09:00', '09:30', '10:00'],
  },
  {
    DateTime.monday: ['08:00', '08:30', '09:00', '09:30', '10:00'],
    DateTime.friday: ['13:00', '13:30', '14:00', '14:30'],
  },
];

class AppointmentSchedulerController extends GetxController {
  final RxList<SpecialtyInfo> specialties = <SpecialtyInfo>[].obs;
  final RxList<DoctorInfo> doctors = <DoctorInfo>[].obs;
  final RxList<AppointmentBooking> appointments = <AppointmentBooking>[].obs;

  final RxnString selectedSpecialtyId = RxnString();
  final RxnString selectedDoctorId = RxnString();
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxnString selectedSlot = RxnString();
  final RxString specialtyQuery = ''.obs;
  final RxString doctorQuery = ''.obs;
  final TextEditingController specialtySearchController = TextEditingController();
  final TextEditingController doctorSearchController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString loadError = ''.obs;
  final RxList<Map<String, dynamic>> agendamentosServidor = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> horariosDisponiveis = <Map<String, dynamic>>[].obs;
  final RxMap<String, List<Map<String, dynamic>>> horariosPorData = <String, List<Map<String, dynamic>>>{}.obs;
  final RxList<String> carregandoHorarios = <String>[].obs;

  bool _hasLoaded = false;

  List<DateTime> get availableDates {
    final doctor = selectedDoctor;
    final horarios = horariosDisponiveis.value;
    
    if (doctor == null || horarios.isEmpty) {
      return List.generate(
        14,
        (index) => DateTime.now().add(Duration(days: index))._copyWithTime(0, 0),
      );
    }

    final horariosAtivos = horarios.where((h) {
      final ativo = h['ativo'];
      return ativo == true || ativo == 'true';
    }).toList();
    
    final datasDisponiveis = <DateTime>{};
    final hoje = DateTime.now();
    final hojeNormalizado = hoje._copyWithTime(0, 0);
    
    for (final h in horariosAtivos) {
      final tipo = h['tipo']?.toString() ?? 'recorrente';
      
      if (tipo == 'especifico') {
        final dataEspecifica = h['dataEspecifica'];
        if (dataEspecifica != null) {
          try {
            String dateStr;
            
            if (dataEspecifica is Map && dataEspecifica.containsKey('\$date')) {
              dateStr = dataEspecifica['\$date'].toString();
            } else if (dataEspecifica is Map && dataEspecifica.containsKey('date')) {
              dateStr = dataEspecifica['date'].toString();
            } else {
              dateStr = dataEspecifica.toString();
              
              if (dateStr.contains('\$date')) {
                final match = RegExp(r'"\$date"\s*:\s*"([^"]+)"').firstMatch(dateStr);
                if (match == null) {
                  final match2 = RegExp(r"'\$date'\s*:\s*'([^']+)'").firstMatch(dateStr);
                  if (match2 != null) {
                    dateStr = match2.group(1)!;
                  }
                } else {
                  dateStr = match.group(1)!;
                }
              }
            }
            
            if (dateStr.isNotEmpty) {
              final data = AppointmentSchedulerController._parseDateIgnoringTimezone(dateStr);
              final dataNormalizada = data._copyWithTime(0, 0);
              if (dataNormalizada.isAfter(hojeNormalizado.subtract(const Duration(days: 1))) || 
                  dataNormalizada.isAtSameMomentAs(hojeNormalizado)) {
                datasDisponiveis.add(dataNormalizada);
              }
            }
          } catch (e) {
          }
        }
      } else {
        final diaSemana = h['diaSemana'];
        if (diaSemana != null) {
          final dia = diaSemana is int ? diaSemana : (diaSemana as num).toInt();
          
          for (int i = 0; i < 60; i++) {
            final data = hojeNormalizado.add(Duration(days: i));
            final weekdayDart = data.weekday;
            final diaSemanaData = weekdayDart == 7 ? 0 : weekdayDart;
            
            if (diaSemanaData == dia) {
              datasDisponiveis.add(data);
            }
            
            if (datasDisponiveis.length >= 14) {
              break;
            }
          }
        }
      }
    }

    final listaDatas = datasDisponiveis.toList()..sort();
    final datasLimitadas = listaDatas.take(14).toList();

    return datasLimitadas;
  }

  SpecialtyInfo? get selectedSpecialty => specialties.firstWhereOrNull((s) => s.id == selectedSpecialtyId.value);

  DoctorInfo? get selectedDoctor => doctors.firstWhereOrNull((d) => d.id == selectedDoctorId.value);

  @override
  void onInit() {
    super.onInit();
    ensureDataLoaded();
    _carregarAgendamentosPaciente();
  }

  Future<void> ensureDataLoaded({bool force = false}) async {
    if (isLoading.value) return;
    if (_hasLoaded && !force) return;
    await _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final database = DatabaseService();
      final rawDoctors = await database.getDoctors();

      final List<DoctorInfo> doctorList = [];
      final Map<String, SpecialtyInfo> specialtyMap = {};
      var specialtyIndex = 0;

      for (final raw in rawDoctors) {
        final id = (raw['id'] ?? raw['_id'] ?? '').toString();
        if (id.isEmpty) continue;

        final name = (raw['nome'] ?? 'Profissional de saúde').toString();
        final specialtyName = (raw['areaAtuacao'] ?? 'Especialidade não informada').toString();
        final specialtyId = _normalizeSpecialtyId(specialtyName);

        var specialty = specialtyMap[specialtyId];
        if (specialty == null) {
          final color = _specialtyColors[specialtyIndex % _specialtyColors.length];
          specialty = SpecialtyInfo(
            id: specialtyId,
            name: specialtyName,
            color: color,
            description: _buildSpecialtyDescription(specialtyName),
          );
          specialtyMap[specialtyId] = specialty;
          specialtyIndex++;
        }

        final crm = (raw['crm'] ?? 'CRM não informado').toString();
        final experience = _buildDoctorExperience(raw);
        final weeklySlots = _generateWeeklySlots(doctorList.length);

        doctorList.add(
          DoctorInfo(
            id: id,
            name: name,
            specialtyId: specialtyId,
            specialtyName: specialtyName,
            crm: crm,
            experience: experience,
            weeklySlots: weeklySlots,
          ),
        );
      }

      specialties.assignAll(specialtyMap.values.toList());
      doctors.assignAll(doctorList);
      _hasLoaded = true;
    } catch (e, stack) {
      loadError.value = 'Não foi possível carregar os médicos. Tente novamente mais tarde.';
      debugPrint('Erro ao carregar médicos: $e\n$stack');
    } finally {
      isLoading.value = false;
    }
  }

  void resetSelections() {
    specialtySearchController.clear();
    doctorSearchController.clear();
    specialtyQuery.value = '';
    doctorQuery.value = '';
    selectedSpecialtyId.value = null;
    selectedDoctorId.value = null;
    selectedSlot.value = null;
    selectedDate.value = DateTime.now();
  }

  String _normalizeSpecialtyId(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _buildSpecialtyDescription(String name) {
    return 'Atendimento especializado em $name.';
  }

  String _buildDoctorExperience(Map<String, dynamic> data) {
    final consultorio = (data['enderecoConsultorio'] ?? '').toString().trim();
    final cidade = (data['cidade'] ?? '').toString().trim();
    final estado = (data['estado'] ?? '').toString().trim();
    final telefoneConsultorio = (data['telefoneConsultorio'] ?? '').toString().trim();
    final telefonePessoal = (data['telefonePessoal'] ?? '').toString().trim();

    final detalhes = <String>[];
    final local = [consultorio, cidade, estado].where((part) => part.isNotEmpty).join(', ');
    if (local.isNotEmpty) {
      detalhes.add('Consultório em $local');
    }

    final contato = telefoneConsultorio.isNotEmpty ? telefoneConsultorio : telefonePessoal;
    if (contato.isNotEmpty) {
      detalhes.add('Contato: $contato');
    }

    if (detalhes.isEmpty) {
      return 'Toque para visualizar a agenda disponível.';
    }

    return detalhes.join(' • ');
  }

  Map<int, List<String>> _generateWeeklySlots(int index) {
    final template = _slotTemplates[index % _slotTemplates.length];
    return template.map((weekday, slots) => MapEntry(weekday, List<String>.from(slots)));
  }

  List<SpecialtyInfo> get filteredSpecialties {
    final query = specialtyQuery.value.trim().toLowerCase();
    if (query.isEmpty) return specialties;
    return specialties
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query))
        .toList();
  }

  List<DoctorInfo> get filteredDoctors {
    final specialtyId = selectedSpecialtyId.value;
    if (specialtyId == null) {
      return const [];
    }
    final base = doctors.where((d) => d.specialtyId == specialtyId);
    final query = doctorQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return base.toList();
    }
    return base
        .where((d) =>
            d.name.toLowerCase().contains(query) ||
            d.crm.toLowerCase().contains(query) ||
            d.experience.toLowerCase().contains(query))
        .toList();
  }

  void updateSpecialtySearch(String value) {
    specialtyQuery.value = value;
  }

  void updateDoctorSearch(String value) {
    doctorQuery.value = value;
  }

  void selectSpecialty(String specialtyId) {
    if (selectedSpecialtyId.value == specialtyId) return;
    selectedSpecialtyId.value = specialtyId;
    selectedDoctorId.value = null;
    selectedSlot.value = null;
    selectedDate.value = DateTime.now();
    final specialty = selectedSpecialty;
    if (specialty != null) {
      specialtySearchController.text = specialty.name;
      specialtySearchController.selection = TextSelection.collapsed(offset: specialty.name.length);
      specialtyQuery.value = specialty.name;
    }
    doctorQuery.value = '';
    doctorSearchController.clear();
  }

  void selectDoctor(String doctorId) {
    if (selectedDoctorId.value == doctorId) {
      return;
    }
    selectedDoctorId.value = doctorId;
    selectedSlot.value = null;
    selectedDate.value = DateTime.now();
    final doctor = selectedDoctor;
    if (doctor != null) {
      doctorSearchController.text = doctor.name;
      doctorSearchController.selection = TextSelection.collapsed(offset: doctor.name.length);
      doctorQuery.value = doctor.name;
      _carregarAgendamentosMedico(doctorId);
      _carregarHorariosDisponiveis(doctorId);
    }
  }

  Future<void> _carregarAgendamentosPaciente() async {
    try {
      final apiService = ApiService();
      final dataInicio = DateTime.now().subtract(const Duration(days: 1));
      final dataFim = dataInicio.add(const Duration(days: 60));
      
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
            final dataHora = agendamento['dataHora']?.toString() ?? 
                            agendamento['dataHora']?['\$date']?.toString() ?? '';
            if (dataHora.isEmpty) {
              continue;
            }
            startTime = DateTime.parse(dataHora);
            duracao = agendamento['duracao'] as int? ?? 30;
          }
          
          if (id.isEmpty || medicoId.isEmpty) {
            continue;
          }
          
          final specialtyId = _normalizeSpecialtyId(areaAtuacao);
          final status = agendamento['status']?.toString() ?? 'agendada';
          
          appointmentsList.add(AppointmentBooking(
            id: id,
            doctorId: medicoId,
            doctorName: medicoNome,
            specialtyId: specialtyId,
            specialtyName: areaAtuacao,
            startTime: startTime,
            duration: Duration(minutes: duracao),
            status: status,
          ));
        } catch (e) {
        }
      }
      
      appointments.value = appointmentsList;
      appointments.refresh();
    } catch (e) {
      appointments.value = [];
    }
  }

  Future<void> _carregarAgendamentosMedico(String medicoId) async {
    try {
      final apiService = ApiService();
      final dataInicio = DateTime.now();
      final dataFim = dataInicio.add(const Duration(days: 14));
      
      final agendamentos = await apiService.buscarAgendamentosMedico(
        medicoId: medicoId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      agendamentosServidor.value = agendamentos;
    } catch (e) {
      agendamentosServidor.value = [];
    }
  }

  Future<void> _carregarHorariosDisponiveis(String medicoId) async {
    try {
      final apiService = ApiService();
      final horarios = await apiService.listarHorariosMedico(medicoId: medicoId);
      
      horariosDisponiveis.value = horarios;
      horariosDisponiveis.refresh();
      
      horariosPorData.clear();
      horariosPorData.refresh();
      
      update();
      
      if (horarios.isEmpty) {
        selectedDate.value = DateTime.now();
      } else {
        final hoje = DateTime.now();
        final primeiroDiaDisponivel = _encontrarProximoDiaDisponivel(hoje);
        if (primeiroDiaDisponivel != null) {
          selectedDate.value = primeiroDiaDisponivel;
          await _carregarHorariosDisponiveisParaData(medicoId, primeiroDiaDisponivel);
        }
      }
      
      update();
    } catch (e) {
      horariosDisponiveis.value = [];
    }
  }

  DateTime? _encontrarProximoDiaDisponivel(DateTime dataInicial) {
    final horariosAtivos = horariosDisponiveis.where((h) {
      final ativo = h['ativo'];
      return ativo == true || ativo == 'true';
    }).toList();
    
    final datasEspecificas = <DateTime>[];
    final diasSemanaComHorarios = <int>{};
    
    final dataInicialNormalizada = dataInicial._copyWithTime(0, 0);
    
    for (final h in horariosAtivos) {
      final tipo = h['tipo']?.toString() ?? 'recorrente';
      
      if (tipo == 'especifico') {
        final dataEspecifica = h['dataEspecifica'];
        if (dataEspecifica != null) {
          try {
            String dateStr;
            
            if (dataEspecifica is Map && dataEspecifica.containsKey('\$date')) {
              dateStr = dataEspecifica['\$date'].toString();
            } else if (dataEspecifica is Map && dataEspecifica.containsKey('date')) {
              dateStr = dataEspecifica['date'].toString();
            } else {
              dateStr = dataEspecifica.toString();
              
              if (dateStr.contains('\$date')) {
                final match = RegExp(r'"\$date"\s*:\s*"([^"]+)"').firstMatch(dateStr);
                if (match == null) {
                  final match2 = RegExp(r"'\$date'\s*:\s*'([^']+)'").firstMatch(dateStr);
                  if (match2 != null) {
                    dateStr = match2.group(1)!;
                  }
                } else {
                  dateStr = match.group(1)!;
                }
              }
            }
            
            if (dateStr.isNotEmpty) {
              final data = AppointmentSchedulerController._parseDateIgnoringTimezone(dateStr);
              final dataNormalizada = data._copyWithTime(0, 0);
              if (dataNormalizada.isAfter(dataInicialNormalizada.subtract(const Duration(days: 1))) || 
                  dataNormalizada.isAtSameMomentAs(dataInicialNormalizada)) {
                datasEspecificas.add(dataNormalizada);
              }
            }
          } catch (e) {
          }
        }
      } else {
        final diaSemana = h['diaSemana'];
        if (diaSemana != null) {
          final dia = diaSemana is int ? diaSemana : (diaSemana as num).toInt();
          diasSemanaComHorarios.add(dia);
        }
      }
    }

    if (datasEspecificas.isEmpty && diasSemanaComHorarios.isEmpty) {
      return null;
    }

    final todasDatas = <DateTime>{};
    
    if (datasEspecificas.isNotEmpty) {
      todasDatas.addAll(datasEspecificas);
    }
    
    if (diasSemanaComHorarios.isNotEmpty) {
      for (int i = 0; i < 60; i++) {
        final data = dataInicialNormalizada.add(Duration(days: i));
        final weekdayDart = data.weekday;
        final diaSemana = weekdayDart == 7 ? 0 : weekdayDart;
        
        if (diasSemanaComHorarios.contains(diaSemana)) {
          todasDatas.add(data);
        }
      }
    }

    if (todasDatas.isEmpty) {
      return null;
    }

    final proximaData = todasDatas.where((d) => 
      d.isAfter(dataInicialNormalizada.subtract(const Duration(days: 1))) || 
      d.isAtSameMomentAs(dataInicialNormalizada)
    ).toList()..sort();
    
    if (proximaData.isNotEmpty) {
      return proximaData.first;
    }

    return null;
  }

  Future<void> _carregarHorariosDisponiveisParaData(String medicoId, DateTime data) async {
    final dataKey = '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    
    final horariosDataMap = horariosPorData.value;
    if (horariosDataMap.containsKey(dataKey) || carregandoHorarios.contains(dataKey)) {
      return;
    }

    try {
      carregandoHorarios.add(dataKey);
      carregandoHorarios.refresh();
      horariosPorData[dataKey] = [];

      final apiService = ApiService();
      final resultado = await apiService.obterHorariosDisponiveis(
        medicoId: medicoId,
        data: data,
      );
      
      final horarios = List<Map<String, dynamic>>.from(resultado['horariosDisponiveis'] ?? []);
      
      horariosPorData[dataKey] = horarios;
      horariosPorData.refresh();
      
      update();
    } catch (e) {
      horariosPorData[dataKey] = [];
      horariosPorData.refresh();
    } finally {
      carregandoHorarios.remove(dataKey);
      carregandoHorarios.refresh();
    }
  }

  void selectDate(DateTime date) async {
    final normalized = date._copyWithTime(0, 0);
    selectedDate.value = normalized;
    selectedSlot.value = null;
    
    if (selectedDoctorId.value != null) {
      _carregarAgendamentosMedico(selectedDoctorId.value!);
      await _carregarHorariosDisponiveisParaData(selectedDoctorId.value!, normalized);
      update();
    }
  }

  void selectSlot(String slot) {
    selectedSlot.value = slot;
  }

  List<String> getAvailableSlotsForSelectedDoctor() {
    final doctor = selectedDoctor;
    final date = selectedDate.value;
    
    if (doctor == null) {
      return [];
    }

    final dataKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final horariosDataMap = horariosPorData.value;
    
    final horariosData = horariosDataMap[dataKey] ?? [];
    
    final slots = horariosData
        .where((h) {
          final disponivel = h['disponivel'];
          final isDisponivel = disponivel == true || disponivel == 'true';
          return isDisponivel;
        })
        .map((h) {
          final hora = h['hora'];
          return hora?.toString() ?? '';
        })
        .where((hora) => hora.isNotEmpty)
        .toList();

    return slots;
  }

  bool _isSlotAvailable(String doctorId, DateTime date, String slot) {
    final slotDateTime = combineDateAndSlot(date, slot);
    
    final conflitoLocal = appointments.any((booking) {
      if (booking.doctorId != doctorId) return false;
      return booking.startTime.year == date.year &&
          booking.startTime.month == date.month &&
          booking.startTime.day == date.day &&
          DateFormat('HH:mm').format(booking.startTime) == slot;
    });
    
    if (conflitoLocal) return false;
    
    final conflitoServidor = agendamentosServidor.any((agendamento) {
      try {
        DateTime inicioAgendamento, fimAgendamento;
        
        if (agendamento['data'] != null && agendamento['horaInicio'] != null && agendamento['horaFim'] != null) {
          final dataStr = agendamento['data']?.toString() ?? '';
          final horaInicio = agendamento['horaInicio']?.toString() ?? '00:00';
          final horaFim = agendamento['horaFim']?.toString() ?? '00:00';
          
          final partsInicio = horaInicio.split(':');
          final partsFim = horaFim.split(':');
          
          final ano = int.parse(dataStr.split('-')[0]);
          final mes = int.parse(dataStr.split('-')[1]);
          final dia = int.parse(dataStr.split('-')[2].split('T')[0]);
          
          inicioAgendamento = DateTime(ano, mes, dia, int.parse(partsInicio[0]), int.parse(partsInicio[1]));
          fimAgendamento = DateTime(ano, mes, dia, int.parse(partsFim[0]), int.parse(partsFim[1]));
        } else if (agendamento['dataHora'] != null) {
          final dataHora = DateTime.parse(agendamento['dataHora'].toString());
          final duracao = agendamento['duracao'] as int? ?? 30;
          inicioAgendamento = dataHora;
          fimAgendamento = dataHora.add(Duration(minutes: duracao));
        } else {
          return false;
        }
        
        final inicioSlot = slotDateTime;
        final fimSlot = slotDateTime.add(const Duration(minutes: 30));
        
        return (inicioSlot.isBefore(fimAgendamento) && fimSlot.isAfter(inicioAgendamento));
      } catch (e) {
        return false;
      }
    });
    
    return !conflitoServidor;
  }

  Future<bool> confirmAppointment() async {
    final doctor = selectedDoctor;
    final slot = selectedSlot.value;
    final specialty = selectedSpecialty;

    if (doctor == null || slot == null || specialty == null) {
      Get.snackbar(
        'Informações incompletas',
        'Selecione especialidade, médico, data e horário disponíveis.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: const Color(0xFF1E293B),
      );
      return false;
    }

    try {
      final authService = Get.find<AuthService>();
      final patient = authService.currentUser;
      
      if (patient == null || patient.id == null) {
        Get.snackbar(
          'Erro',
          'Não foi possível identificar o paciente. Faça login novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: const Color(0xFF1E293B),
        );
        return false;
      }

      final dataKey = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';
      final horariosData = horariosPorData[dataKey] ?? [];
      final horarioSelecionado = horariosData.firstWhereOrNull((h) => h['hora'] == slot);
      final duracaoConsulta = horarioSelecionado?['duracao'] as int? ?? 30;
      
      final horaInicio = slot;
      final parts = horaInicio.split(':');
      final horaInicioH = int.parse(parts[0]);
      final minutoInicioM = int.parse(parts[1]);
      final horaFimTime = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day, horaInicioH, minutoInicioM).add(Duration(minutes: duracaoConsulta));
      final horaFim = '${horaFimTime.hour.toString().padLeft(2, '0')}:${horaFimTime.minute.toString().padLeft(2, '0')}';
      
      final startTime = combineDateAndSlot(selectedDate.value, slot);
      
      if (startTime.isBefore(DateTime.now())) {
        Get.snackbar(
          'Data inválida',
          'A data e horário da consulta deve ser futura.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: const Color(0xFF1E293B),
        );
        return false;
      }

      if (!_isSlotAvailable(doctor.id, selectedDate.value, slot)) {
        Get.snackbar(
          'Horário indisponível',
          'Este horário já foi reservado. Por favor, escolha outro horário.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: const Color(0xFF1E293B),
        );
        return false;
      }

      final apiService = ApiService();
      
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final resultado = await apiService.criarAgendamento(
        medicoId: doctor.id,
        data: selectedDate.value,
        horaInicio: horaInicio,
        horaFim: horaFim,
        tipoConsulta: 'presencial',
        motivoConsulta: 'Consulta agendada pelo paciente',
        duracao: duracaoConsulta,
      );

      Get.back();

      final novoAgendamento = AppointmentBooking(
        id: resultado['agendamento']?['_id'] ?? resultado['agendamento']?['id'] ?? '',
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialtyId: specialty.id,
        specialtyName: specialty.name,
        startTime: startTime,
        status: resultado['agendamento']?['status']?.toString() ?? 'agendada',
      );

      appointments.add(novoAgendamento);
      
      final agendamentoData = {
        'dataHora': '${startTime.year.toString().padLeft(4, '0')}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}T${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00.000',
        'duracao': duracaoConsulta,
        'status': 'agendada',
      };
      agendamentosServidor.add(agendamentoData);
      
      selectedSlot.value = null;

      await _carregarAgendamentosPaciente();

      Get.snackbar(
        'Consulta agendada',
        'Seu horário com ${doctor.name} foi reservado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      Get.back();
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      if (errorMessage.toLowerCase().contains('já existe') || 
          errorMessage.toLowerCase().contains('horário') ||
          errorMessage.toLowerCase().contains('conflito')) {
        errorMessage = 'Este horário já foi reservado. Por favor, escolha outro horário.';
      } else if (errorMessage.toLowerCase().contains('token') || 
                 errorMessage.toLowerCase().contains('sessão')) {
        errorMessage = 'Sua sessão expirou. Por favor, faça login novamente.';
      } else if (errorMessage.toLowerCase().contains('data') && 
                 errorMessage.toLowerCase().contains('futura')) {
        errorMessage = 'A data e horário da consulta deve ser futura.';
      }
      
      Get.snackbar(
        'Erro ao agendar',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: const Color(0xFF1E293B),
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  List<AppointmentBooking> get upcomingAppointments {
    final now = DateTime.now().subtract(const Duration(minutes: 30));
    return appointments.where((booking) => booking.startTime.isAfter(now)).toList();
  }

  Future<bool> cancelarAgendamento(String agendamentoId, {String? motivo}) async {
    try {
      final apiService = ApiService();
      
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await apiService.cancelarAgendamento(
        agendamentoId: agendamentoId,
        motivoCancelamento: motivo,
      );

      Get.back();

      appointments.removeWhere((booking) => booking.id == agendamentoId);
      
      await _carregarAgendamentosPaciente();

      Get.snackbar(
        'Consulta cancelada',
        'Seu agendamento foi cancelado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      Get.back();
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      if (errorMessage.toLowerCase().contains('token') || 
          errorMessage.toLowerCase().contains('sessão')) {
        errorMessage = 'Sua sessão expirou. Por favor, faça login novamente.';
      } else if (errorMessage.toLowerCase().contains('não encontrado')) {
        errorMessage = 'Agendamento não encontrado. Pode já ter sido cancelado.';
      }
      
      Get.snackbar(
        'Erro ao cancelar',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: const Color(0xFF1E293B),
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  @override
  void onClose() {
    specialtySearchController.dispose();
    doctorSearchController.dispose();
    super.onClose();
  }

  static DateTime combineDateAndSlot(DateTime date, String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _parseDateIgnoringTimezone(String dateString) {
    try {
      String cleanedDate = dateString.trim();
      
      if (cleanedDate.contains('\$date')) {
        final match = RegExp(r'"\$date"\s*:\s*"([^"]+)"').firstMatch(cleanedDate);
        if (match == null) {
          final match2 = RegExp(r"'\$date'\s*:\s*'([^']+)'").firstMatch(cleanedDate);
          if (match2 != null) {
            cleanedDate = match2.group(1)!;
          }
        } else {
          cleanedDate = match.group(1)!;
        }
      }
      
      final dateMatch = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(cleanedDate);
      if (dateMatch != null) {
        final year = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final day = int.parse(dateMatch.group(3)!);
        return DateTime(year, month, day, 0, 0);
      }
      
      cleanedDate = cleanedDate.replaceAll('T', ' ').split('.')[0].split('Z')[0].split('+')[0].trim();
      
      final parts = cleanedDate.split(RegExp(r'[\s\-:]'));
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day, 0, 0);
      }
    } catch (e) {
    }
    
    try {
      final parsed = DateTime.parse(dateString);
      return DateTime(parsed.year, parsed.month, parsed.day, 0, 0);
    } catch (e) {
      return DateTime.now();
    }
  }
}

extension on DateTime {
  DateTime _copyWithTime(int hour, int minute) {
    return DateTime(year, month, day, hour, minute);
  }
}
