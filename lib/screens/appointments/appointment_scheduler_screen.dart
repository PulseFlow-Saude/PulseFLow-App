import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';
import 'appointment_scheduler_controller.dart';

class AppointmentSchedulerScreen extends StatelessWidget {
  const AppointmentSchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppointmentSchedulerController());
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Obx(
                () => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Escolha a especialidade'),
                      const SizedBox(height: 12),
                      _buildSpecialtySection(controller),
                      const SizedBox(height: 28),

                      _buildSectionTitle('2. Escolha o médico'),
                      const SizedBox(height: 12),
                      _buildDoctorSection(controller),
                      const SizedBox(height: 28),

                      _buildSectionTitle('3. Escolha a data'),
                      const SizedBox(height: 12),
                      _buildDateSelector(controller),
                      const SizedBox(height: 28),

                      _buildSectionTitle('4. Escolha o horário'),
                      const SizedBox(height: 12),
                      _buildSlotsGrid(controller),
                      const SizedBox(height: 28),

                      _buildSummaryCard(controller, homeController),
                      const SizedBox(height: 16),
                      _buildConfirmButton(controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 20,
        right: 20,
      ),
    decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Agendamento de Consulta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Escolha a melhor combinação para você',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: const [
                Icon(Icons.calendar_month_rounded, color: Colors.white, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Encontre horários disponíveis conforme a agenda do médico escolhido. Horários já ocupados não serão exibidos.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleMedium.copyWith(
        color: const Color(0xFF1E293B),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSpecialtySection(AppointmentSchedulerController controller) {
    final selected = controller.selectedSpecialty;
    if (selected != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_hospital_rounded, color: selected.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.name,
                    style: AppTheme.titleMedium.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected.description,
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                controller.resetSelections();
                Get.offAllNamed(Routes.APPOINTMENTS_SPECIALTY);
              },
              child: const Text('Trocar'),
            ),
          ],
        ),
      );
    }
    return _buildSpecialtyChips(controller);
  }

  Widget _buildDoctorSection(AppointmentSchedulerController controller) {
    final doctor = controller.selectedDoctor;
    if (controller.selectedSpecialtyId.value == null) {
      return _buildEmptyState(
        icon: Icons.info_outline,
        message: 'Selecione uma especialidade para listar os médicos.',
      );
    }
    if (doctor != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00324A).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00324A).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF00324A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: AppTheme.titleMedium.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doctor.specialtyName} • ${doctor.crm}',
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                controller.selectedSlot.value = null;
                controller.doctorSearchController.text = '';
                controller.updateDoctorSearch('');
                controller.selectedDoctorId.value = null;
                Get.toNamed(Routes.APPOINTMENTS_DOCTORS);
              },
              child: const Text('Trocar'),
            ),
          ],
        ),
      );
    }
    return _buildDoctorList(controller);
  }

  Widget _buildSpecialtyChips(AppointmentSchedulerController controller) {
    final filteredSpecialties = controller.filteredSpecialties;
    final query = controller.specialtyQuery.value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.specialtySearchController,
          onChanged: controller.updateSpecialtySearch,
          decoration: InputDecoration(
            hintText: 'Pesquise por especialidade',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00324A), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredSpecialties.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off_rounded,
            message: query.isEmpty
                ? 'Nenhuma especialidade disponível no momento.'
                : 'Não encontramos especialidades que contenham "$query".',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: filteredSpecialties.map((specialty) {
              final isSelected = controller.selectedSpecialtyId.value == specialty.id;
              return ChoiceChip(
                label: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        specialty.name,
                        style: AppTheme.titleSmall.copyWith(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall.copyWith(
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                selected: isSelected,
                onSelected: (_) {
                  controller.specialtySearchController.text = specialty.name;
                  controller.specialtySearchController.selection = TextSelection.collapsed(offset: specialty.name.length);
                  controller.updateSpecialtySearch(specialty.name);
                  controller.selectSpecialty(specialty.id);
                },
                selectedColor: specialty.color,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDoctorList(AppointmentSchedulerController controller) {
    return Obx(() {
      final doctors = controller.filteredDoctors;
      if (controller.selectedSpecialtyId.value == null) {
        return _buildEmptyState(
          icon: Icons.info_outline,
          message: 'Selecione uma especialidade para listar os médicos.',
        );
      }
      if (doctors.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off_rounded,
          message: controller.doctorQuery.value.isEmpty
              ? 'Nenhum médico encontrado para esta especialidade.'
              : 'Não encontramos médicos que contenham "${controller.doctorQuery.value}".',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.doctorSearchController,
            onChanged: controller.updateDoctorSearch,
            decoration: InputDecoration(
              hintText: 'Pesquise pelo médico',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF00324A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...doctors.map((doctor) {
          final isSelected = controller.selectedDoctorId.value == doctor.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF00324A) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              color: Colors.white,
            ),
            child: ListTile(
              onTap: () => controller.selectDoctor(doctor.id),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF00324A).withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: Color(0xFF00324A)),
              ),
              title: Text(
                doctor.name,
                style: AppTheme.titleMedium.copyWith(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${doctor.specialtyName} • ${doctor.crm}',
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctor.experience,
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? const Color(0xFF00324A) : Colors.grey,
              ),
            ),
          );
        }).toList(),
        ],
      );
    });
  }

  Widget _buildDateSelector(AppointmentSchedulerController controller) {
    return Obx(() {
      if (controller.selectedDoctor == null) {
        return _buildEmptyState(
          icon: Icons.calendar_today_rounded,
          message: 'Selecione um médico para visualizar as datas disponíveis.',
        );
      }

      final availableDates = controller.availableDates;
      
      if (availableDates.isEmpty) {
        return _buildEmptyState(
          icon: Icons.event_busy_rounded,
          message: 'Este médico não possui horários disponíveis cadastrados.',
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableDates.map((date) {
            final isSelected = DateUtils.isSameDay(date, controller.selectedDate.value);
            final isToday = DateUtils.isSameDay(date, DateTime.now());

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => controller.selectDate(date),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00324A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00324A) : Colors.grey.shade300,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E', 'pt_BR').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isToday ? 'Hoje' : DateFormat('MMM', 'pt_BR').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildSlotsGrid(AppointmentSchedulerController controller) {
    if (controller.selectedDoctor == null) {
      return _buildEmptyState(
        icon: Icons.work_history_outlined,
        message: 'Selecione um médico para visualizar os horários disponíveis.',
      );
    }

    return Obx(() {
      final date = controller.selectedDate.value;
      final dataKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final estaCarregando = controller.carregandoHorarios.contains(dataKey);
      final horariosPorDataValue = controller.horariosPorData.value;
      
      if (estaCarregando) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final availableSlots = controller.getAvailableSlotsForSelectedDoctor();
    
      if (availableSlots.isEmpty) {
        return _buildEmptyState(
          icon: Icons.event_busy_rounded,
          message: 'Não há horários disponíveis para esta data. Selecione outra data.',
        );
      }

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: availableSlots.map((slot) {
          final isSelected = controller.selectedSlot.value == slot;
          return GestureDetector(
            onTap: () => controller.selectSlot(slot),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00324A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00324A) : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                slot,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSummaryCard(AppointmentSchedulerController controller, HomeController homeController) {
    final patientName = homeController.getPatientName();
    final specialty = controller.selectedSpecialty;
    final doctor = controller.selectedDoctor;
    final slot = controller.selectedSlot.value;
    final date = controller.selectedDate.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00324A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00324A).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da consulta',
            style: AppTheme.titleMedium.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Paciente', patientName),
          _buildSummaryRow('Especialidade', specialty?.name ?? 'Selecione a especialidade'),
          _buildSummaryRow('Médico', doctor?.name ?? 'Selecione o médico'),
          _buildSummaryRow(
            'Data',
            DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(date),
          ),
          _buildSummaryRow('Horário', slot ?? 'Selecione um horário disponível'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(AppointmentSchedulerController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline_rounded),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00324A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () async {
          final success = await controller.confirmAppointment();
          if (success) {
            // stay on screen, summary already updated
          }
        },
        label: const Text(
          'Confirmar agendamento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
