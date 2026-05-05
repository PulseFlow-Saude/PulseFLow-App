import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../enxaqueca/enxaqueca_screen.dart';
import '../diabetes/diabetes_screen.dart';
import '../login/paciente_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/bp_menu_icon.dart';
import '../../widgets/common/hormonal_icon.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../../widgets/pulse_side_menu.dart';
import '../home/home_controller.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pacienteController = Get.find<PacienteController>();
    final horizontalPad = math.max(16.0, MediaQuery.sizeOf(context).width * 0.055);
    final bottomPad = math.max(MediaQuery.paddingOf(context).bottom, 16.0) + 16;

    return PulseBlueScaffold(
      drawer: PulseSideMenu(activeItem: PulseNavItem.menu),
      header: _buildHeader(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, bottomPad),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionIntro(context),
                _buildHealthRecordsList(pacienteController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 22),
          Expanded(
            child: Center(child: _buildBrandLogo()),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildSectionIntro(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  color: AppTheme.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'menu_section_records'.tr,
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        letterSpacing: 0.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'menu_section_records_sub'.tr,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.95),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.28),
                  AppTheme.primaryBlue.withValues(alpha: 0.08),
                  AppTheme.primaryBlue.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    if (!Get.isRegistered<HomeController>()) {
      return IconButton(
        icon: _notificationBadge(null),
        onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
      );
    }

    final homeController = Get.find<HomeController>();
    return Obx(() {
      final count = homeController.unreadNotificationsCount.value;
      return IconButton(
        icon: _notificationBadge(count),
        onPressed: () async {
          await Get.toNamed(Routes.NOTIFICATIONS);
          await homeController.loadNotificationsCount();
        },
      );
    });
  }

  Widget _notificationBadge(int? count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (count != null && count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandLogo() {
    return SizedBox(
      width: 140,
      height: 45,
      child: Image.asset(
        'assets/images/oryon_health_logo_negative.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                'Oryon Health',
                style: AppTheme.titleSmall.copyWith(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthRecordsList(PacienteController pacienteController) {
    final cards = [
      _RecordCardData(
        accent: AppTheme.primaryBlue,
        icon: Icons.attach_file_rounded,
        title: 'menu_exames'.tr,
        subtitle: 'menu_exames_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.EXAME_UPLOAD);
        },
      ),
      _RecordCardData(
        accent: Colors.deepPurple,
        icon: Icons.psychology_rounded,
        title: 'menu_enxaqueca'.tr,
        subtitle: 'menu_enxaqueca_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => EnxaquecaScreen(
                pacienteId: pacienteController.pacienteId.value,
              ));
        },
      ),
      _RecordCardData(
        accent: Colors.red.shade700,
        icon: Icons.bloodtype_rounded,
        title: 'menu_diabetes'.tr,
        subtitle: 'menu_diabetes_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => DiabetesScreen(
                pacienteId: pacienteController.pacienteId.value,
              ));
        },
      ),
      _RecordCardData(
        accent: const Color(0xFFC62828),
        customIcon: BpMenuIcon(size: 28, color: const Color(0xFFC62828)),
        title: 'menu_pressao'.tr,
        subtitle: 'menu_pressao_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.PRESSAO);
        },
      ),
      _RecordCardData(
        accent: Colors.orange.shade800,
        icon: Icons.sick_rounded,
        title: 'menu_gastrite'.tr,
        subtitle: 'menu_gastrite_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.CRISE_GASTRITE_FORM);
        },
      ),
      _RecordCardData(
        accent: const Color(0xFF1565C0),
        icon: Icons.event_note_rounded,
        title: 'menu_eventos'.tr,
        subtitle: 'menu_eventos_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.EVENTO_CLINICO_FORM);
        },
      ),
      _RecordCardData(
        accent: Colors.teal.shade700,
        customIcon: HormonalIcon(size: 28, color: Colors.teal.shade700),
        title: 'menu_hormonal'.tr,
        subtitle: 'menu_hormonal_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.HORMONAL);
        },
      ),
      _RecordCardData(
        accent: Colors.pink.shade400,
        icon: Icons.favorite_rounded,
        title: 'menu_ciclo'.tr,
        subtitle: 'menu_ciclo_sub'.tr,
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.MENSTRUACAO_FORM);
        },
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          _RecordCard(data: cards[i]),
          if (i < cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RecordCardData {
  final Color accent;
  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecordCardData({
    required this.accent,
    this.icon,
    this.customIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || customIcon != null);
}

class _RecordCard extends StatelessWidget {
  final _RecordCardData data;

  const _RecordCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.title,
      hint: '${'menu_tap_to'.tr} ${data.title}',
      child: Container(
        decoration: AppTheme.surfaceListCardDecoration(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: data.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: data.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: data.customIcon ??
                          Icon(
                            data.icon,
                            size: 26,
                            color: data.accent,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: AppTheme.textSecondary.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
