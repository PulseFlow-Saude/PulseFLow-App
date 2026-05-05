import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../widgets/pulse_bottom_navigation.dart' show PulseNavItem;
import '../../widgets/pulse_drawer_button.dart';
import '../../widgets/pulse_side_menu.dart';
import '../home/home_controller.dart';

/// Hub de históricos — mesmo padrão visual do [MenuScreen] (área de Registros).
class HistorySelectionScreen extends StatelessWidget {
  const HistorySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPad = math.max(16.0, MediaQuery.sizeOf(context).width * 0.055);
    final bottomPad = math.max(MediaQuery.paddingOf(context).bottom, 16.0) + 16;

    return PulseBlueScaffold(
      drawer: const PulseSideMenu(activeItem: PulseNavItem.history),
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
                _buildHistoryCardsList(),
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
                  Icons.history_rounded,
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
                      'hist_section_title'.tr,
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
                      'hist_section_sub'.tr,
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

  Widget _buildHistoryCardsList() {
    final cards = [
      _HistoryCardData(
        accent: AppTheme.primaryBlue,
        icon: Icons.history_rounded,
        title: 'hist_clinical'.tr,
        subtitle: 'hist_clinical_sub'.tr,
        onTap: () => Get.toNamed(Routes.MEDICAL_RECORDS),
      ),
      _HistoryCardData(
        accent: const Color(0xFF1565C0),
        icon: Icons.event_available_rounded,
        title: 'hist_events'.tr,
        subtitle: 'hist_events_sub'.tr,
        onTap: () => Get.toNamed(Routes.EVENTO_CLINICO_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.orange.shade800,
        icon: Icons.restaurant_menu_rounded,
        title: 'hist_gastrite'.tr,
        subtitle: 'hist_gastrite_sub'.tr,
        onTap: () => Get.toNamed(Routes.CRISE_GASTRITE_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.pink.shade400,
        icon: Icons.timeline_rounded,
        title: 'hist_menstrual'.tr,
        subtitle: 'hist_menstrual_sub'.tr,
        onTap: () => Get.toNamed(Routes.MENSTRUACAO_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.red.shade700,
        icon: Icons.favorite_rounded,
        title: 'hist_heart_rate'.tr,
        subtitle: 'hist_heart_rate_sub'.tr,
        onTap: () => Get.toNamed(Routes.HEART_RATE_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.blueGrey.shade600,
        icon: Icons.directions_walk_rounded,
        title: 'hist_steps'.tr,
        subtitle: 'hist_steps_sub'.tr,
        onTap: () => Get.toNamed(Routes.STEPS_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.indigo.shade600,
        icon: Icons.bedtime_rounded,
        title: 'hist_sleep'.tr,
        subtitle: 'hist_sleep_sub'.tr,
        onTap: () => Get.toNamed(Routes.SLEEP_HISTORY),
      ),
      _HistoryCardData(
        accent: Colors.green.shade700,
        icon: Icons.security_rounded,
        title: 'hist_access'.tr,
        subtitle: 'hist_access_sub'.tr,
        onTap: () => Get.toNamed(Routes.ACCESS_HISTORY),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          _HistoryCard(data: cards[i]),
          if (i < cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HistoryCardData {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HistoryCardData({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _HistoryCard extends StatelessWidget {
  final _HistoryCardData data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.title,
      hint: '${'hist_tap_to_access'.tr} ${data.title}',
      child: Container(
        decoration: AppTheme.surfaceListCardDecoration(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              data.onTap();
            },
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
                      child: Icon(
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
