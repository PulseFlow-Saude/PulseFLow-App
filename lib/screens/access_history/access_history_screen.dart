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
        backgroundColor: const Color(0xFF00324A),
        drawer: const PulseSideMenu(activeItem: PulseNavItem.profile),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(controller, isSmallScreen),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
                      
                      return Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
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
                              onRefresh: () => controller.carregarHistoricoAcessos(),
                              color: const Color(0xFF00324A),
                              child: ListView.separated(
                                padding: EdgeInsets.all(isPhone ? 12 : 16),
                                itemCount: controller.acessos.length,
                                separatorBuilder: (context, index) => SizedBox(height: isSmallScreen ? 8 : 12),
                                itemBuilder: (context, index) {
                                  final acesso = controller.acessos[index];
                                  return _buildAccessCard(controller, acesso, isSmallScreen, isPhone);
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AccessHistoryController controller, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
      ),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de Acessos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.acessos.isEmpty
                      ? 'Nenhum acesso registrado'
                      : '${controller.acessos.length} acesso${controller.acessos.length > 1 ? 's' : ''} registrado${controller.acessos.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
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
              'Nenhum acesso registrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Os acessos dos médicos ao seu prontuário\nserão exibidos aqui',
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50) : Colors.grey[200]!,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFF00324A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF00324A),
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
                          color: const Color(0xFF212121),
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
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ATIVO',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
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
                    'Acesso em: ${controller.formatarDataCompleta(acesso.dataHora)}',
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
                      'Desconectado em: ${controller.formatarDataCompleta(acesso.desconectadoEm!)}',
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
                      'Duração: ${acesso.duracaoFormatada}',
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

