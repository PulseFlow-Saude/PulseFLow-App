import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

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

class UpcomingAppointmentsController extends GetxController {
  final RxList<AppointmentBooking> appointments = <AppointmentBooking>[].obs;
  final RxBool isLoading = false.obs;
  final RxString loadError = ''.obs;
  
  // Filtros
  final RxString selectedStatus = 'Agendada'.obs;
  final Rxn<DateTime> dataInicioFiltro = Rxn<DateTime>();
  final Rxn<DateTime> dataFimFiltro = Rxn<DateTime>();
  
  final List<String> statusOptions = ['Todos', 'Agendada', 'Cancelada', 'Concluída'];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    isLoading.value = true;
    loadError.value = '';
    
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
          // Ignora erros de parsing individual
        }
      }
      
      appointments.value = appointmentsList;
      appointments.refresh();
    } catch (e) {
      loadError.value = 'Não foi possível carregar as consultas. Tente novamente mais tarde.';
      appointments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  String _normalizeSpecialtyId(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  List<AppointmentBooking> get upcomingAppointments {
    var filtered = appointments.toList();
    
    // Filtro por status
    if (selectedStatus.value != 'Todos') {
      final statusMap = {
        'Agendada': 'agendada',
        'Cancelada': 'cancelada',
        'Concluída': 'concluida',
      };
      final statusFiltro = statusMap[selectedStatus.value] ?? '';
      if (statusFiltro.isNotEmpty) {
        filtered = filtered.where((booking) => 
          booking.status.toLowerCase() == statusFiltro.toLowerCase()
        ).toList();
      }
    }
    
    // Filtro por período
    if (dataInicioFiltro.value != null || dataFimFiltro.value != null) {
      final inicio = dataInicioFiltro.value != null
          ? DateTime(
              dataInicioFiltro.value!.year,
              dataInicioFiltro.value!.month,
              dataInicioFiltro.value!.day,
            )
          : null;
      
      final fim = dataFimFiltro.value != null
          ? DateTime(
              dataFimFiltro.value!.year,
              dataFimFiltro.value!.month,
              dataFimFiltro.value!.day,
              23,
              59,
              59,
            )
          : null;
      
      filtered = filtered.where((booking) {
        final bookingDate = DateTime(
          booking.startTime.year,
          booking.startTime.month,
          booking.startTime.day,
        );
        
        bool matchesInicio = true;
        bool matchesFim = true;
        
        if (inicio != null) {
          matchesInicio = bookingDate.isAfter(inicio.subtract(const Duration(days: 1))) ||
                          bookingDate.isAtSameMomentAs(inicio);
        }
        
        if (fim != null) {
          matchesFim = bookingDate.isBefore(fim.add(const Duration(days: 1))) ||
                       bookingDate.isAtSameMomentAs(DateTime(fim.year, fim.month, fim.day));
        }
        
        return matchesInicio && matchesFim;
      }).toList();
    }
    
    // Ordenar por data
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return filtered;
  }
  
  void setStatusFilter(String status) {
    selectedStatus.value = status;
  }
  
  void setDataInicio(DateTime? data) {
    dataInicioFiltro.value = data;
  }
  
  void setDataFim(DateTime? data) {
    dataFimFiltro.value = data;
  }
  
  void limparFiltros() {
    selectedStatus.value = 'Todos';
    dataInicioFiltro.value = null;
    dataFimFiltro.value = null;
  }
  
  bool get hasActiveFilters {
    return selectedStatus.value != 'Todos' || 
           dataInicioFiltro.value != null || 
           dataFimFiltro.value != null;
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
      
      await loadAppointments();

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
}

