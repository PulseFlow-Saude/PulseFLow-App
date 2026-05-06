import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/specialty_translations.dart';
import 'home_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import 'package:flutter/services.dart';

const double _kHomeCardRadius = 16;

/// Cartões da lista na home: fundo suave, borda no tom do app e sombra discreta.
BoxDecoration _homeListCardDecoration({bool emphasized = false}) {
  return BoxDecoration(
    color: const Color(0xFFF8FAFB),
    borderRadius: BorderRadius.circular(_kHomeCardRadius),
    border: Border.all(
      color: emphasized
          ? AppTheme.primaryBlue.withValues(alpha: 0.32)
          : AppTheme.primaryBlue.withValues(alpha: 0.12),
      width: emphasized ? 1.5 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryBlue.withValues(alpha: 0.07),
        blurRadius: 22,
        offset: const Offset(0, 7),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

BoxDecoration _homeEmptyStateDecoration() {
  return BoxDecoration(
    color: const Color(0xFFF3F6F8),
    borderRadius: BorderRadius.circular(_kHomeCardRadius),
    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    final horizontalPad = math.max(16.0, MediaQuery.sizeOf(context).width * 0.055);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const PulseSideMenu(activeItem: PulseNavItem.home),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                const Color(0xFF001F2E),
                AppTheme.primaryBlue.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _buildHeader(context, controller, isCompact: true),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHomeContentSheet(
                          context,
                          controller,
                          horizontalPad,
                          isLandscape: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildHeader(context, controller),
                      Expanded(
                        child: _buildHomeContentSheet(
                          context,
                          controller,
                          horizontalPad,
                          isLandscape: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContentSheet(
    BuildContext context,
    HomeController controller,
    double horizontalPad, {
    required bool isLandscape,
  }) {
    final mq = MediaQuery.of(context);
    final bottomPad = math.max(mq.padding.bottom, 16.0) + 24;
    final borderRadius = isLandscape
        ? const BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshPatientData,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              16,
              horizontalPad,
              bottomPad,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScheduleConsultationCard(),
                    const SizedBox(height: 24),
                    _buildUpcomingAppointmentsSection(controller),
                    const SizedBox(height: 24),
                    _buildFavoriteSection(controller),
                    const SizedBox(height: 24),
                    _buildShortcutsSection(controller),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller, {bool isCompact = false}) {
    final avatarSize = isCompact ? 56.0 : 70.0;
    final logoHeight = isCompact ? 38.0 : 46.0;
    final logoWidth = isCompact ? 118.0 : 144.0;
    final gapTopBarToProfile = isCompact ? 12.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        isCompact ? 4 : 6,
        12,
        isCompact ? 14 : 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (ctx) {
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                    ),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  );
                },
              ),
              _buildBrandLogo(width: logoWidth, height: logoHeight),
              Obx(() => IconButton(
                    icon: Stack(
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
                        if (controller.unreadNotificationsCount.value > 0)
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
                                controller.unreadNotificationsCount.value > 9
                                    ? '9+'
                                    : controller.unreadNotificationsCount.value.toString(),
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
                    ),
                    onPressed: () async {
                      await Get.toNamed(Routes.NOTIFICATIONS);
                      controller.loadNotificationsCount();
                    },
                  )),
            ],
          ),
          SizedBox(height: gapTopBarToProfile),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 6 : 14,
              0,
              isCompact ? 10 : 16,
              0,
            ),
            child: Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: controller.getProfilePhoto() != null
                          ? ClipOval(child: _buildProfileImage(controller, size: avatarSize))
                          : Icon(Icons.person_rounded, color: Colors.white, size: avatarSize * 0.55),
                    ),
                    SizedBox(width: isCompact ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.getGreeting().tr,
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.getPatientName(),
                            style: AppTheme.titleMedium.copyWith(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSection(HomeController controller) {
    return Obx(() {
      if (!controller.hasAnyData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNoDataMessage(),
          ],
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'home_favorites'.tr,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showFavoriteOptions(controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'home_edit'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.favoriteItems.isEmpty)
            _buildNoFavoritesMessage()
          else
            _buildFavoriteCharts(controller),
        ],
      );
    });
  }

  Widget _buildNoDataMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: _homeEmptyStateDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 44,
            color: AppTheme.primaryBlue.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 18),
          Text(
            'home_no_data'.tr,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_no_data_sub'.tr,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.55),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFavoritesMessage() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _homeEmptyStateDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppTheme.primaryBlue.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'home_configure_favorites'.tr,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.78),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCharts(HomeController controller) {
    return Column(
      children: controller.favoriteItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFavoriteChart(item, controller),
        );
      }).toList(),
    );
  }

  Widget _buildFavoriteChart(String item, HomeController controller) {
    final itemData = _getFavoriteItemData(item);
    final stats = _getStatsForItem(controller, item);
    
    if (stats.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                itemData['icon'],
                color: itemData['color'],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                itemData['title'],
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            Container(
              height: 80,
              width: double.infinity,
              decoration: _homeEmptyStateDecoration(),
              child: Center(
                child: Text(
                  'home_no_data_available'.tr,
                  style: TextStyle(
                    color: AppTheme.textPrimary.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Visualizações específicas por tipo
    switch (item) {
      case 'enxaqueca':
        return _buildEnxaquecaCard(itemData, stats);
      case 'diabetes':
        return _buildDiabetesCard(itemData, stats);
      case 'crise_gastrite':
        return _buildGastriteCard(itemData, stats);
      case 'evento_clinico':
        return _buildEventoClinicoCard(itemData, stats);
      case 'menstruacao':
        return _buildMenstruacaoCard(itemData, stats);
      default:
        return _buildDefaultCard(itemData, stats);
    }
  }
  
  Widget _buildEnxaquecaCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final diasDesdeUltima = stats['diasDesdeUltima'] as int? ?? 0;
    final frequencia30Dias = stats['frequencia30Dias'] as int? ?? 0;
    final ultimaIntensidade = stats['ultimaIntensidade'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (itemData['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemData['icon'],
                  color: itemData['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData['title'],
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 ? 'home_today'.tr : diasDesdeUltima == 1 ? 'home_days_ago'.trParams({'n': '1'}) : 'home_days_ago_plural'.trParams({'n': diasDesdeUltima.toString()}),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'home_last_intensity'.tr,
                  '$ultimaIntensidade/10',
                  itemData['color'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'home_last_30_days'.tr,
                  '$frequencia30Dias ${'home_crises'.tr}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('common_avg'.tr, '${stats['media'] ?? 0}/10', Colors.blue),
              _buildStatItem('common_total'.tr, '${stats['total'] ?? 0}', Colors.grey[600]!),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiabetesCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final ultimaGlicemia = stats['ultimaGlicemia'] as int? ?? 0;
    final unidade = stats['unidade'] as String? ?? 'mg/dL';
    final status = stats['status'] as String? ?? 'Normal';
    final diasDesdeUltima = stats['diasDesdeUltima'] as int? ?? 0;
    final media7Dias = stats['media7Dias'] as int?;
    
    Color statusColor = Colors.green;
    if (status == 'Alta') statusColor = Colors.red;
    if (status == 'Baixa') statusColor = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Container(
                padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: (itemData['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemData['icon'],
                  color: itemData['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData['title'],
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 ? 'home_today'.tr : diasDesdeUltima == 1 ? 'home_days_ago'.trParams({'n': '1'}) : 'home_days_ago_plural'.trParams({'n': diasDesdeUltima.toString()}),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.28)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$ultimaGlicemia',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        unidade,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'Alta' ? 'diab_status_high'.tr : status == 'Baixa' ? 'diab_status_low'.tr : 'diab_status_normal'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (media7Dias != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'home_avg_7_days'.tr,
                    '$media7Dias $unidade',
                    Colors.blue,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('home_avg_general'.tr, '${stats['media'] ?? 0} $unidade', Colors.blue),
              _buildStatItem('common_total'.tr, '${stats['total'] ?? 0}', Colors.grey[600]!),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGastriteCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final diasDesdeUltima = stats['diasDesdeUltima'] as int? ?? 0;
    final frequencia30Dias = stats['frequencia30Dias'] as int? ?? 0;
    final ultimaIntensidade = stats['ultimaIntensidade'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (itemData['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemData['icon'],
                  color: itemData['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData['title'],
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 ? 'home_today'.tr : diasDesdeUltima == 1 ? 'home_days_ago'.trParams({'n': '1'}) : 'home_days_ago_plural'.trParams({'n': diasDesdeUltima.toString()}),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'home_last_intensity'.tr,
                  '$ultimaIntensidade/10',
                  itemData['color'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'home_last_30_days'.tr,
                  '$frequencia30Dias ${'home_crises'.tr}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _buildStatItem('common_avg'.tr, '${stats['media'] ?? 0}/10', Colors.blue),
              _buildStatItem('common_total'.tr, '${stats['total'] ?? 0}', Colors.grey[600]!),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventoClinicoCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final totalFuturos = stats['totalFuturos'] as int? ?? 0;
    final proximoEvento = stats['proximoEvento'] as DateTime?;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (itemData['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemData['icon'],
                  color: itemData['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemData['title'],
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'home_next'.tr,
                  '$totalFuturos ${'home_events'.tr}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'home_this_month'.tr,
                  '${stats['este_mes'] ?? 0} ${'home_events'.tr}',
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (proximoEvento != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_next_event'.tr,
                  style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(proximoEvento),
                          style: TextStyle(
                    fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                  ),
                ),
                      ],
              ),
            ),
          ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildStatItem('common_total'.tr, '${stats['total'] ?? 0}', Colors.grey[600]!),
        ],
      ),
    );
  }
  
  Widget _buildMenstruacaoCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final diasDesdeUltima = stats['diasDesdeUltima'] as int? ?? 0;
    final cicloMedio = stats['cicloMedio'] as int?;
    final proximoCiclo = stats['proximoCiclo'] as DateTime?;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (itemData['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemData['icon'],
                  color: itemData['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData['title'],
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'home_day_cycle'.trParams({'n': diasDesdeUltima.toString()}),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (cicloMedio != null)
                Expanded(
                  child: _buildInfoBox(
                    'home_avg_cycle'.tr,
                    '$cicloMedio dias',
                    Colors.purple,
                  ),
                ),
              if (cicloMedio != null) const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'home_avg_duration'.tr,
                  '${stats['media'] ?? 0} dias',
                  Colors.pink,
                ),
              ),
            ],
          ),
          if (proximoCiclo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.pink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_next_cycle'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(proximoCiclo),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildStatItem('home_total_records'.tr, '${stats['total'] ?? 0}', Colors.grey[600]!),
        ],
      ),
    );
  }
  
  Widget _buildDefaultCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _homeListCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                itemData['icon'],
                color: itemData['color'],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                itemData['title'],
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('common_max'.tr, stats['maior']?.toString() ?? 'N/A', Colors.red),
              _buildStatItem('common_min'.tr, stats['menor']?.toString() ?? 'N/A', Colors.green),
              _buildStatItem('common_avg'.tr, stats['media']?.toString() ?? 'N/A', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'home_today'.tr;
    if (difference == 1) return 'home_format_tomorrow'.tr;
    if (difference == -1) return 'home_format_yesterday'.tr;
    if (difference > 0 && difference <= 7) return 'home_format_in_days'.trParams({'n': difference.toString()});
    
    return '${date.day}/${date.month}/${date.year}';
  }

  // Obtém estatísticas para um item específico
  Map<String, dynamic> _getStatsForItem(HomeController controller, String item) {
    switch (item) {
      case 'enxaqueca':
        return controller.getEnxaquecaStats();
      case 'diabetes':
        return controller.getDiabetesStats();
      case 'crise_gastrite':
        return controller.getGastriteStats();
      case 'evento_clinico':
        return controller.getEventoClinicoStats();
      case 'menstruacao':
        return controller.getMenstruacaoStats();
      default:
        return {};
    }
  }

  // Widget para exibir um item de estatística
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChartForItem(String item, Map<String, dynamic> itemData) {
    switch (item) {
      case 'enxaqueca':
        return _buildEnxaquecaChart();
      case 'diabetes':
        return _buildDiabetesChart();
      case 'crise_gastrite':
        return _buildGastriteChart();
      case 'evento_clinico':
        return _buildEventoClinicoChart();
      case 'menstruacao':
        return _buildMenstruacaoChart();
      default:
        return _buildDefaultChart();
    }
  }

  Widget _buildEnxaquecaChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            color: Colors.purple.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_pain'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_pain_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiabetesChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bloodtype,
            color: Colors.red.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_glucose'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_glucose_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGastriteChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sick,
            color: Colors.orange.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_gastrite'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_gastrite_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventoClinicoChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            color: Colors.blue.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_events'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_events_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenstruacaoChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.woman,
            color: Colors.pink.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_menstruation'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_menstruation_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            color: Colors.grey.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'home_chart_default'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_chart_default_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(String item) {
    final itemData = _getFavoriteItemData(item);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _homeListCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            itemData['icon'],
            color: itemData['color'],
            size: 28,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              itemData['title'],
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              itemData['subtitle'],
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getFavoriteItemData(String item) {
    switch (item) {
      case 'enxaqueca':
        return {
          'icon': Icons.psychology,
          'title': 'home_enxaqueca'.tr,
          'subtitle': 'home_enxaqueca_sub'.tr,
          'color': Colors.purple,
        };
      case 'diabetes':
        return {
          'icon': Icons.bloodtype,
          'title': 'home_diabetes'.tr,
          'subtitle': 'home_diabetes_sub'.tr,
          'color': Colors.red,
        };
      case 'crise_gastrite':
        return {
          'icon': Icons.sick,
          'title': 'home_gastrite'.tr,
          'subtitle': 'home_gastrite_sub'.tr,
          'color': Colors.orange,
        };
      case 'evento_clinico':
        return {
          'icon': Icons.medical_services,
          'title': 'home_eventos'.tr,
          'subtitle': 'home_eventos_sub'.tr,
          'color': Colors.blue,
        };
      case 'menstruacao':
        return {
          'icon': Icons.woman,
          'title': 'home_menstruacao'.tr,
          'subtitle': 'home_menstruacao_sub'.tr,
          'color': Colors.pink,
        };
      default:
        return {
          'icon': Icons.help,
          'title': 'home_unknown'.tr,
          'subtitle': 'home_unknown_sub'.tr,
          'color': Colors.grey,
        };
    }
  }

  void _showFavoriteOptions(HomeController controller) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'home_config_favorites'.tr,
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'home_config_favorites_sub'.tr,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Obx(() => ListView(
                shrinkWrap: true,
                children: [
                  _buildFavoriteOption('enxaqueca', 'home_enxaqueca'.tr, controller),
                  _buildFavoriteOption('diabetes', 'home_diabetes'.tr, controller),
                  _buildFavoriteOption('crise_gastrite', 'home_gastrite'.tr, controller),
                  _buildFavoriteOption('evento_clinico', 'home_eventos'.tr, controller),
                  _buildFavoriteOption('menstruacao', 'home_menstruacao'.tr, controller),
                ],
              )),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'common_cancel'.tr,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'common_save'.tr,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteOption(String item, String title, HomeController controller) {
    final isSelected = controller.favoriteItems.contains(item);
    final isAvailable = _isItemAvailable(item, controller);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 20,
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            color: isAvailable ? AppTheme.textPrimary : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: isAvailable 
            ? null 
            : Text(
                'home_no_data_available'.tr,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        enabled: isAvailable,
        onTap: isAvailable ? () {
          if (isSelected) {
            controller.removeFromFavorites(item);
          } else if (controller.favoriteItems.length < 4) {
            controller.addToFavorites(item);
          }
        } : null,
      ),
    );
  }

  bool _isItemAvailable(String item, HomeController controller) {
    switch (item) {
      case 'enxaqueca':
        return controller.hasEnxaqueca;
      case 'diabetes':
        return controller.hasDiabetes;
      case 'crise_gastrite':
        return controller.hasCriseGastrite;
      case 'evento_clinico':
        return controller.hasEventoClinico;
      case 'menstruacao':
        return controller.hasMenstruacao;
      default:
        return false;
    }
  }

  Widget _buildHeartRateChart() {
    // Simulando dados vazios - você pode implementar lógica real aqui
    bool hasData = true; // Mude para false para testar o estado "sem dados"
    
    if (!hasData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Sem dados',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Nenhum registro de frequência cardíaca encontrado',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1000,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                Widget text;
                switch (value.toInt()) {
                  case 0:
                    text = const Text('A', style: style);
                    break;
                  case 1:
                    text = const Text('B', style: style);
                    break;
                  case 2:
                    text = const Text('C', style: style);
                    break;
                  case 3:
                    text = const Text('D', style: style);
                    break;
                  case 4:
                    text = const Text('E', style: style);
                    break;
                  case 5:
                    text = const Text('F', style: style);
                    break;
                  case 6:
                    text = const Text('G', style: style);
                    break;
                  case 7:
                    text = const Text('H', style: style);
                    break;
                  default:
                    text = const Text('', style: style);
                    break;
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: text,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1000,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: 7,
        minY: 0,
        maxY: 8000,
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 2000),
              const FlSpot(1, 3000),
              const FlSpot(2, 2500),
              const FlSpot(3, 4000),
              const FlSpot(4, 3500),
              const FlSpot(5, 5000),
              const FlSpot(6, 4500),
              const FlSpot(7, 6000),
            ],
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF64B5F6).withOpacity(0.3),
                  const Color(0xFF64B5F6).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: [
              const FlSpot(0, 1500),
              const FlSpot(1, 2500),
              const FlSpot(2, 2000),
              const FlSpot(3, 3000),
              const FlSpot(4, 2800),
              const FlSpot(5, 3500),
              const FlSpot(6, 3200),
              const FlSpot(7, 4000),
            ],
            isCurved: true,
            color: const Color(0xFFFFA726),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [
              const FlSpot(0, 1000),
              const FlSpot(1, 1800),
              const FlSpot(2, 1500),
              const FlSpot(3, 2200),
              const FlSpot(4, 2000),
              const FlSpot(5, 2500),
              const FlSpot(6, 2300),
              const FlSpot(7, 2800),
            ],
            isCurved: true,
            color: const Color(0xFF1976D2),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleConsultationCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.88),
            const Color(0xFF00557A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(_kHomeCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home_schedule_title'.tr,
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'home_schedule_sub'.tr,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Get.toNamed(Routes.APPOINTMENTS_SPECIALTY),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_rounded, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'home_schedule_btn'.tr,
                        style: AppTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 19),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection(HomeController controller) {
    return Obx(() {
      if (controller.isLoadingAppointments.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: _homeListCardDecoration(),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
        );
      }
      
      final allAppointments = controller.upcomingAppointments;
      final appointments = allAppointments.take(3).toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'home_appointments_section'.tr,
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (allAppointments.length > 3)
                TextButton(
                  onPressed: () => Get.toNamed(Routes.UPCOMING_APPOINTMENTS),
                  child: Text(
                    'home_see_all'.tr,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: _homeEmptyStateDecoration(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.65),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'home_no_appointments'.tr,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...appointments.map((appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAppointmentCard(appointment),
            )),
        ],
      );
    });
  }
  
  Widget _buildAppointmentCard(AppointmentBooking appointment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isToday = appointment.startTime.day == DateTime.now().day &&
                    appointment.startTime.month == DateTime.now().month &&
                    appointment.startTime.year == DateTime.now().year;
    
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.UPCOMING_APPOINTMENTS),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: _homeListCardDecoration(emphasized: isToday),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: isToday 
                    ? AppTheme.primaryBlue
                    : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SpecialtyTranslations.translate(appointment.specialtyName),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isToday 
                            ? '${'home_today_at'.tr} ${timeFormat.format(appointment.startTime)}'
                            : '${dateFormat.format(appointment.startTime)} às ${timeFormat.format(appointment.startTime)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.grey.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutsSection(HomeController controller) {
    return Obx(() {
      if (!controller.hasAnyData) {
        return _buildNoShortcutsMessage();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.push_pin,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'home_shortcuts'.tr,
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAvailableShortcuts(controller),
        ],
      );
    });
  }
  
  Widget _buildNoShortcutsMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: _homeEmptyStateDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 44,
            color: AppTheme.primaryBlue.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 18),
          Text(
            'home_no_exams'.tr,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre seus dados de saúde para ver os atalhos aqui.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.55),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableShortcuts(HomeController controller) {
    final shortcuts = <Widget>[];
    
    if (controller.hasEnxaqueca) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.psychology,
        title: 'home_enxaqueca'.tr,
        subtitle: 'home_enxaqueca_sub'.tr,
        color: Colors.purple,
        onTap: () => Get.toNamed(Routes.ENXAQUECA),
      ));
    }
    
    if (controller.hasDiabetes) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.bloodtype,
        title: 'home_diabetes'.tr,
        subtitle: 'home_diabetes_sub'.tr,
        color: Colors.red,
        onTap: () => Get.toNamed(Routes.DIABETES),
      ));
    }
    
    if (controller.hasCriseGastrite) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.sick,
        title: 'home_gastrite'.tr,
        subtitle: 'home_gastrite_sub'.tr,
        color: Colors.orange,
        onTap: () => Get.toNamed(Routes.CRISE_GASTRITE_HISTORY),
      ));
    }
    
    if (controller.hasEventoClinico) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.medical_services,
        title: 'home_eventos'.tr,
        subtitle: 'home_eventos_sub'.tr,
        color: Colors.blue,
        onTap: () => Get.toNamed(Routes.EVENTO_CLINICO_HISTORY),
      ));
    }
    
    if (controller.hasMenstruacao) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.woman,
        title: 'home_menstruacao'.tr,
        subtitle: 'home_menstruacao_sub'.tr,
        color: Colors.pink,
        onTap: () => Get.toNamed(Routes.MENSTRUACAO_HISTORY),
      ));
    }
    
    // Sempre incluir notas médicas
    shortcuts.add(_buildShortcutCard(
      icon: Icons.note_add,
      title: 'home_notas'.tr,
      subtitle: 'home_notas_sub'.tr,
      color: Colors.green,
      onTap: () => Get.toNamed(Routes.MEDICAL_RECORDS),
    ));
    
    return Column(
      children: shortcuts.map((shortcut) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: shortcut,
      )).toList(),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: _homeListCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.withValues(alpha: 0.45),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoShortcutsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: _homeEmptyStateDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_rounded,
            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            'home_no_shortcuts'.tr,
            style: AppTheme.titleSmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'home_no_shortcuts_sub'.tr,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.55),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCardOld(String title, String category, String date) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Exame Selecionado',
          'Visualizando detalhes do exame: $title',
          backgroundColor: AppTheme.primaryBlue, // Nova cor azul
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _homeListCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: AppTheme.bodyMedium.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTheme.bodyMedium.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.snackbar(
                  'Download',
                  'Iniciando download do exame: $title',
                  backgroundColor: const Color(0xFF4CAF50),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue, // Nova cor azul
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Baixar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Obtém o ícone baseado no horário
  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny; // Manhã
    } else if (hour < 18) {
      return Icons.wb_sunny_outlined; // Tarde
    } else {
      return Icons.nightlight_round; // Noite
    }
  }

  Widget _buildBrandLogo({double width = 140, double height = 45}) {
    return SizedBox(
      width: width,
      height: height,
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

  Widget _buildProfileImage(HomeController controller, {required double size}) {
    final photo = controller.getProfilePhoto();
    final iconSize = size * 0.55;
    if (photo == null) {
      return Icon(Icons.person_rounded, color: Colors.white, size: iconSize);
    }

    if (controller.isBase64Photo(photo)) {
      final bytes = controller.decodeProfilePhoto(photo);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person_rounded, color: Colors.white, size: iconSize);
          },
        );
      }
    }

    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person_rounded, color: Colors.white, size: iconSize);
        },
      );
    }

    return Image.file(
      File(photo),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.person_rounded, color: Colors.white, size: iconSize);
      },
    );
  }
} 