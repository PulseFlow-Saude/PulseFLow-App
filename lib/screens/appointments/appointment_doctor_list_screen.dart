import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'appointment_scheduler_controller.dart';

class AppointmentDoctorListScreen extends StatelessWidget {
  const AppointmentDoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentSchedulerController>();
    controller.ensureDataLoaded();

    if (controller.selectedSpecialtyId.value == null) {
      Future.microtask(() => Get.offAllNamed(Routes.APPOINTMENTS_SPECIALTY));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00324A),
      body: Column(
        children: [
          _DoctorHeader(),
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
                () {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00324A)),
                    );
                  }

                  if (controller.loadError.value.isNotEmpty) {
                    return Center(
                      child: _ErrorState(
                        message: controller.loadError.value,
                        onRetry: () => controller.ensureDataLoaded(force: true),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.selectedSpecialty?.name ?? 'Especialistas',
                          style: AppTheme.titleLarge.copyWith(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Escolha um médico para ver a agenda e horários disponíveis.',
                          style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller.doctorSearchController,
                          onChanged: controller.updateDoctorSearch,
                          decoration: InputDecoration(
                            hintText: 'Pesquisar médico, CRM ou experiência',
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
                        const SizedBox(height: 20),
                        Obx(() {
                          final filteredDoctors = controller.filteredDoctors;
                          final doctorQuery = controller.doctorQuery.value;
                          
                          if (filteredDoctors.isEmpty) {
                            return _EmptyState(
                              icon: Icons.search_off_rounded,
                              message: doctorQuery.isEmpty
                                  ? 'Nenhum médico cadastrado para esta especialidade.'
                                  : 'Não encontramos médicos que contenham "$doctorQuery".',
                            );
                          }
                          
                          return Column(
                            children: filteredDoctors.map((doctor) {
                            final suggestions = _nextAvailableThreeSlots(controller, doctor.id);
                            return _DoctorCard(
                              doctorName: doctor.name,
                              crm: doctor.crm,
                              experience: doctor.experience,
                              specialty: doctor.specialtyName,
                              suggestions: suggestions,
                              onTap: () {
                                controller.selectDoctor(doctor.id);
                                Get.toNamed(Routes.APPOINTMENT_SCHEDULER);
                              },
                            );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _nextAvailableThreeSlots(AppointmentSchedulerController controller, String doctorId) {
    final doctor = controller.doctors.firstWhereOrNull((d) => d.id == doctorId);
    if (doctor == null) return const [];

    return const [];
  }
}

class _DoctorHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolha o médico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Veja horários sugeridos para o próximo atendimento.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String doctorName;
  final String crm;
  final String experience;
  final String specialty;
  final List<DateTime> suggestions;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctorName,
    required this.crm,
    required this.experience,
    required this.specialty,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00324A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF00324A), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: AppTheme.titleMedium.copyWith(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$specialty • $crm',
                      style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00324A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onTap,
                  child: const Text(
                    'Ver agenda',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            experience,
            style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          if (suggestions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximos horários sugeridos',
                  style: AppTheme.bodySmall.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: suggestions.map((dateTime) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00324A).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dateFormatter.format(dateTime),
                        style: AppTheme.bodySmall.copyWith(color: const Color(0xFF00324A), fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00324A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
