import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../utils/specialty_translations.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../home/home_controller.dart';
import '../institutional/settings_controller.dart';
import 'appointment_scheduler_controller.dart';

class AppointmentSchedulerScreen extends StatelessWidget {
  const AppointmentSchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppointmentSchedulerController());
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return PulseBlueScaffold(
      header: _buildHeader(context),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('appt_step_specialty'.tr),
              const SizedBox(height: 12),
              _buildSpecialtySection(controller),
              const SizedBox(height: 28),
              _buildSectionTitle('appt_step_doctor'.tr),
              const SizedBox(height: 12),
              _buildDoctorSection(controller),
              const SizedBox(height: 28),
              _buildSectionTitle('appt_step_date'.tr),
              const SizedBox(height: 12),
              _buildDateSelector(controller),
              const SizedBox(height: 28),
              _buildSectionTitle('appt_step_slot'.tr),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PulseBlueBackButton(onPressed: Get.back),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'appt_scheduling_title'.tr,
                      style: PulseBlueHeaderStyles.titleCompact,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'appt_scheduling_sub'.tr,
                      style: PulseBlueHeaderStyles.subtitleCompact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'appt_schedule_hint'.tr,
                    style: PulseBlueHeaderStyles.subtitleCompact.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
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
                    SpecialtyTranslations.translate(selected.name),
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
              child: Text('appt_change'.tr),
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
        message: 'appt_select_specialty'.tr,
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
                    '${SpecialtyTranslations.translate(doctor.specialtyName)} • ${doctor.crm}',
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
              child: Text('appt_change'.tr),
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
            hintText: 'appt_search_specialty'.tr,
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
                ? 'appt_no_specialty'.tr
                : '${'appt_no_specialty_match'.tr} "$query".',
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
                        SpecialtyTranslations.translate(specialty.name),
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
          message: 'appt_select_specialty'.tr,
        );
      }
      if (doctors.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off_rounded,
          message: controller.doctorQuery.value.isEmpty
              ? 'appt_no_doctor'.tr
              : '${'appt_no_doctor_match'.tr} "${controller.doctorQuery.value}".',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.doctorSearchController,
            onChanged: controller.updateDoctorSearch,
            decoration: InputDecoration(
              hintText: 'appt_search_doctor'.tr,
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
                    '${SpecialtyTranslations.translate(doctor.specialtyName)} • ${doctor.crm}',
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
          message: 'appt_select_doctor_dates'.tr,
        );
      }

      final availableDates = controller.availableDates;
      
      if (availableDates.isEmpty) {
        return _buildEmptyState(
          icon: Icons.event_busy_rounded,
          message: 'appt_no_slots_doctor'.tr,
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
                        DateFormat('E', Get.find<SettingsController>().effectiveLocale.toString()).format(date).toUpperCase(),
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
                        isToday ? 'common_today'.tr : DateFormat('MMM', Get.find<SettingsController>().effectiveLocale.toString()).format(date),
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
          message: 'appt_select_doctor_slots'.tr,
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
          message: 'appt_no_slots_date'.tr,
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
            'appt_summary'.tr,
            style: AppTheme.titleMedium.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('appt_patient'.tr, patientName),
          _buildSummaryRow('appt_specialty'.tr, specialty != null ? SpecialtyTranslations.translate(specialty.name) : 'appt_select_specialty_placeholder'.tr),
          _buildSummaryRow('appt_doctor'.tr, doctor?.name ?? 'appt_select_doctor_placeholder'.tr),
          _buildSummaryRow(
            'appt_date'.tr,
            DateFormat('dd/MM/yyyy (EEEE)', Get.find<SettingsController>().effectiveLocale.toString()).format(date),
          ),
          _buildSummaryRow('appt_time'.tr, slot ?? 'appt_select_slot_placeholder'.tr),
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
        label: Text(
          'appt_confirm'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
