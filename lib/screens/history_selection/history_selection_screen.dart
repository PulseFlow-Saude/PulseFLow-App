import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../home/home_controller.dart';

class HistorySelectionScreen extends StatefulWidget {
  const HistorySelectionScreen({Key? key}) : super(key: key);

  @override
  State<HistorySelectionScreen> createState() => _HistorySelectionScreenState();
}

class _HistorySelectionScreenState extends State<HistorySelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A),
        drawer: const PulseSideMenu(activeItem: PulseNavItem.history),
        body: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Conteúdo principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Históricos Disponíveis'),
                        const SizedBox(height: 16),
                        _buildHistoryList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.history),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PulseDrawerButton(),
              _buildPulseFlowLogo(),
              _buildNotificationIcon(),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Históricos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseFlowLogo() {
    return SizedBox(
      width: 140,
      height: 45,
      child: Image.asset(
        'assets/images/PulseNegativo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'PulseFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  // Lista de históricos
  Widget _buildHistoryList() {
    return Column(
      children: [
        _buildHistoryCard(
          icon: Icons.history_rounded,
          title: 'Histórico Clínico',
          subtitle: 'Registros médicos da consulta',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.MEDICAL_RECORDS);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.event_available_rounded,
          title: 'Histórico de Eventos',
          subtitle: 'Eventos de saúde',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.EVENTO_CLINICO_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.restaurant_menu_rounded,
          title: 'Histórico de Gastrite',
          subtitle: 'Crises e sintomas relacionados',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.CRISE_GASTRITE_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.timeline_rounded,
          title: 'Histórico Menstrual',
          subtitle: 'Ciclos e acompanhamento',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.MENSTRUACAO_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.favorite_rounded,
          title: 'Frequência Cardíaca',
          subtitle: 'Histórico de batimentos cardíacos',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.HEART_RATE_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.directions_walk_rounded,
          title: 'Passos',
          subtitle: 'Histórico de passos diários',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.STEPS_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.bedtime_rounded,
          title: 'Insônia / Sono',
          subtitle: 'Histórico de tempo na cama',
          gradientColors: [
            const Color(0xFF00324A),
            const Color(0xFF004A6B),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.SLEEP_HISTORY);
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          icon: Icons.security_rounded,
          title: 'Histórico de Acessos',
          subtitle: 'Veja quem acessou seu prontuário',
          gradientColors: [
            const Color(0xFF4CAF50),
            const Color(0xFF66BB6A),
          ],
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.toNamed(Routes.ACCESS_HISTORY);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: title,
      hint: 'Toque para acessar $title',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Ícone com fundo decorativo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Ícone de seta
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
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

