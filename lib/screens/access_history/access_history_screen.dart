import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'access_history_controller.dart';
import '../../models/access_history.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class AccessHistoryScreen extends StatelessWidget {
  const AccessHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccessHistoryController());
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isPhone = screenSize.width < 420;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const PulseSideMenu(activeItem: PulseNavItem.profile),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.blueScreenGradientDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: Container(
                  decoration: AppTheme.blueContentSheetDecoration,
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth =
                          constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;

                      return Obx(() {
                        if (controller.isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue),
                            ),
                          );
                        }

                        if (controller.acessos.isEmpty) {
                          return _buildEmptyState(isSmallScreen);
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: RefreshIndicator(
                              onRefresh: () =>
                                  controller.carregarHistoricoAcessos(),
                              color: AppTheme.primaryBlue,
                              child: ListView.separated(
                                padding: EdgeInsets.all(isPhone ? 12 : 16),
                                itemCount: controller.acessos.length,
                                separatorBuilder: (context, index) => SizedBox(
                                    height: isSmallScreen ? 8 : 12),
                                itemBuilder: (context, index) {
                                  final acesso = controller.acessos[index];
                                  return _buildAccessCard(controller, acesso,
                                      isSmallScreen, isPhone);
                                },
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccessHistoryController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.paddingOf(context).top + 12,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PulseDrawerButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'access_history_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Obx(() => Text(
                  controller.acessos.isEmpty
                      ? 'access_none'.tr
                      : controller.acessos.length > 1
                          ? 'access_count_plural'.trParams({'n': controller.acessos.length.toString()})
                          : 'access_count'.trParams({'n': controller.acessos.length.toString()}),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: isSmallScreen ? 60 : 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'access_none'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'access_empty_sub'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCard(
    AccessHistoryController controller,
    AccessHistory acesso,
    bool isSmallScreen,
    bool isPhone,
  ) {
    final isActive = acesso.isActive;

    return Container(
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.success,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : AppTheme.surfaceListCardDecoration(),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color:
                        isActive ? AppTheme.success : AppTheme.primaryBlue,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acesso.medicoNome,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 1 : 2),
                      Text(
                        acesso.medicoEspecialidade,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'access_active'.tr,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Divider(color: Colors.grey[200], height: 1),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: isSmallScreen ? 5 : 6),
                Flexible(
                  child: Text(
                    '${'access_at'.tr} ${controller.formatarDataCompleta(acesso.dataHora)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (acesso.desconectadoEm != null) ...[
              SizedBox(height: isSmallScreen ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.logout,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: isSmallScreen ? 5 : 6),
                  Flexible(
                    child: Text(
                      '${'access_disconnected'.tr} ${controller.formatarDataCompleta(acesso.desconectadoEm!)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (acesso.duracao != null) ...[
              SizedBox(height: isSmallScreen ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: isSmallScreen ? 5 : 6),
                  Flexible(
                    child: Text(
                      '${'access_duration'.tr} ${acesso.duracaoFormatada}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

