import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A), // Cor de fundo azul para ocupar toda a tela
        drawer: const PulseSideMenu(activeItem: PulseNavItem.home),
        body: Column(
          children: [
            // Header com perfil - sem SafeArea para ocupar toda a área superior
            _buildHeader(controller),
            
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
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)), // Nova cor azul
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: controller.refreshPatientData,
                    color: const Color(0xFF00324A), // Nova cor azul
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card de Agendamento (sempre visível)
                          _buildScheduleConsultationCard(),
                          const SizedBox(height: 24),
                          
                          // Seção de Consultas Agendadas
                          _buildUpcomingAppointmentsSection(controller),
                          const SizedBox(height: 24),
                          
                          // Seção Favorito
                          _buildFavoriteSection(controller),
                          const SizedBox(height: 24),
                          
                          // Seção Atalhos
                          _buildShortcutsSection(controller),
                          
                          // Padding extra no final para evitar corte
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.home),
      ),
    );
  }

  Widget _buildHeader(HomeController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 12, // Adiciona padding da status bar
        left: 16,
        right: 16,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A), // Nova cor azul
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Top row com logo centralizado e notificação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              _buildPulseFlowLogo(),
              Obx(() => IconButton(
                icon: Stack(
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
                    if (controller.unreadNotificationsCount.value > 0)
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
          const SizedBox(height: 12),
          
          // Perfil do usuário simplificado
          Obx(() => Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: controller.getProfilePhoto() != null
                    ? ClipOval(
                        child: _buildProfileImage(controller),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Informações do usuário
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.getPatientName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          )),
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
                    color: Color(0xFF00324A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favoritos',
                    style: AppTheme.titleLarge.copyWith(
                      color: const Color(0xFF1E293B),
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
                    color: const Color(0xFF00324A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: const Color(0xFF00324A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF00324A),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ainda não há dados',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece registrando seus dados de saúde para ver suas informações favoritas aqui.',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFavoritesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure seus favoritos tocando em "Editar"',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Center(
                child: Text(
                  'Nenhum dado disponível',
                  style: TextStyle(
                    color: Colors.grey,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 
                          ? 'Hoje' 
                          : diasDesdeUltima == 1 
                              ? 'Há 1 dia' 
                              : 'Há $diasDesdeUltima dias',
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
                  'Última Intensidade',
                  '$ultimaIntensidade/10',
                  itemData['color'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'Últimos 30 dias',
                  '$frequencia30Dias crises',
                  Colors.orange,
                ),
              ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _buildStatItem('Média', '${stats['media'] ?? 0}/10', Colors.blue),
              _buildStatItem('Total', '${stats['total'] ?? 0}', Colors.grey[600]!),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Container(
                padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: itemData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 
                          ? 'Hoje' 
                          : diasDesdeUltima == 1 
                              ? 'Há 1 dia' 
                              : 'Há $diasDesdeUltima dias',
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
                    color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
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
                          status,
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
                    'Média 7 dias',
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
              _buildStatItem('Média Geral', '${stats['media'] ?? 0} $unidade', Colors.blue),
              _buildStatItem('Total', '${stats['total'] ?? 0}', Colors.grey[600]!),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      diasDesdeUltima == 0 
                          ? 'Hoje' 
                          : diasDesdeUltima == 1 
                              ? 'Há 1 dia' 
                              : 'Há $diasDesdeUltima dias',
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
                  'Última Intensidade',
                  '$ultimaIntensidade/10',
                  itemData['color'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'Últimos 30 dias',
                  '$frequencia30Dias crises',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Média', '${stats['media'] ?? 0}/10', Colors.blue),
              _buildStatItem('Total', '${stats['total'] ?? 0}', Colors.grey[600]!),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                    color: const Color(0xFF1E293B),
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
                  'Próximos',
                  '$totalFuturos eventos',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'Este mês',
                  '${stats['este_mes'] ?? 0} eventos',
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo evento',
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
          _buildStatItem('Total', '${stats['total'] ?? 0}', Colors.grey[600]!),
        ],
      ),
    );
  }
  
  Widget _buildMenstruacaoCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    final diasDesdeUltima = stats['diasDesdeUltima'] as int? ?? 0;
    final cicloMedio = stats['cicloMedio'] as int?;
    final proximoCiclo = stats['proximoCiclo'] as DateTime?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dia $diasDesdeUltima do ciclo',
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
                    'Ciclo médio',
                    '$cicloMedio dias',
                    Colors.purple,
                  ),
                ),
              if (cicloMedio != null) const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  'Duração média',
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
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.pink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo ciclo esperado',
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
          _buildStatItem('Total registros', '${stats['total'] ?? 0}', Colors.grey[600]!),
        ],
      ),
    );
  }
  
  Widget _buildDefaultCard(Map<String, dynamic> itemData, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Maior', stats['maior']?.toString() ?? 'N/A', Colors.red),
              _buildStatItem('Menor', stats['menor']?.toString() ?? 'N/A', Colors.green),
              _buildStatItem('Média', stats['media']?.toString() ?? 'N/A', Colors.blue),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
    
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference == -1) return 'Ontem';
    if (difference > 0 && difference <= 7) return 'Em $difference dias';
    
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
            'Intensidade da Dor',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráfico de evolução da intensidade das crises de enxaqueca',
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
            'Níveis de Glicose',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráfico de evolução dos níveis de glicose no sangue',
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
            'Crises de Gastrite',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráfico de frequência e intensidade das crises',
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
            'Eventos Clínicos',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráfico de consultas e exames realizados',
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
            'Ciclo Menstrual',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráfico de acompanhamento do ciclo menstrual',
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
            'Gráfico',
            style: AppTheme.titleSmall.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualização dos dados',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                color: const Color(0xFF1E293B),
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
          'title': 'Enxaqueca',
          'subtitle': 'Registros de dor',
          'color': Colors.purple,
        };
      case 'diabetes':
        return {
          'icon': Icons.bloodtype,
          'title': 'Diabetes',
          'subtitle': 'Níveis de glicose',
          'color': Colors.red,
        };
      case 'crise_gastrite':
        return {
          'icon': Icons.sick,
          'title': 'Gastrite',
          'subtitle': 'Crises registradas',
          'color': Colors.orange,
        };
      case 'evento_clinico':
        return {
          'icon': Icons.medical_services,
          'title': 'Eventos Clínicos',
          'subtitle': 'Consultas e exames',
          'color': Colors.blue,
        };
      case 'menstruacao':
        return {
          'icon': Icons.woman,
          'title': 'Menstruação',
          'subtitle': 'Ciclo menstrual',
          'color': Colors.pink,
        };
      default:
        return {
          'icon': Icons.help,
          'title': 'Desconhecido',
          'subtitle': 'Item não reconhecido',
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
            top: Radius.circular(20),
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
              'Configurar Favoritos',
              style: AppTheme.titleLarge.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha até 4 itens para exibir nos favoritos:',
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
                  _buildFavoriteOption('enxaqueca', 'Enxaqueca', controller),
                  _buildFavoriteOption('diabetes', 'Diabetes', controller),
                  _buildFavoriteOption('crise_gastrite', 'Gastrite', controller),
                  _buildFavoriteOption('evento_clinico', 'Eventos Clínicos', controller),
                  _buildFavoriteOption('menstruacao', 'Menstruação', controller),
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
                      'Cancelar',
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
                      backgroundColor: const Color(0xFF00324A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Salvar',
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
          color: isSelected ? const Color(0xFF00324A) : Colors.grey,
          size: 20,
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            color: isAvailable ? const Color(0xFF1E293B) : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: isAvailable 
            ? null 
            : Text(
                'Nenhum dado disponível',
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
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
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
            dotData: FlDotData(show: false),
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
            dotData: FlDotData(show: false),
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
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleConsultationCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 180, // Altura mínima para garantir que não seja cortado
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00324A), Color(0xFF00557A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Agende sua consulta',
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verifique disponibilidade dos especialistas e escolha o melhor horário para você.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00324A).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(Routes.APPOINTMENTS_SPECIALTY),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00324A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      shadowColor: Colors.transparent,
                    ),
                    icon: const Icon(Icons.medical_services_rounded),
                    label: const Text(
                      'Agendar consulta',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Get.toNamed(Routes.APPOINTMENTS_SPECIALTY),
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection(HomeController controller) {
    return Obx(() {
      if (controller.isLoadingAppointments.value) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
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
              Row(
                children: [
                  const Icon(
                    Icons.event_note,
                    color: Color(0xFF00324A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próximas Consultas',
                    style: AppTheme.titleLarge.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (allAppointments.length > 3)
                TextButton(
                  onPressed: () => Get.toNamed(Routes.UPCOMING_APPOINTMENTS),
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      color: const Color(0xFF00324A),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você não possui consultas agendadas',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday 
                ? const Color(0xFF00324A).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF00324A).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today,
                color: isToday 
                    ? const Color(0xFF00324A)
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
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.specialtyName,
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
                            ? 'Hoje às ${timeFormat.format(appointment.startTime)}'
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
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
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
                color: Color(0xFF00324A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Atalhos',
                style: AppTheme.titleLarge.copyWith(
                  color: const Color(0xFF1E293B),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum exame disponível',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre seus dados de saúde para ver os atalhos aqui.',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
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
        title: 'Enxaqueca',
        subtitle: 'Registros de dor',
        color: Colors.purple,
        onTap: () => Get.toNamed(Routes.ENXAQUECA),
      ));
    }
    
    if (controller.hasDiabetes) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.bloodtype,
        title: 'Diabetes',
        subtitle: 'Níveis de glicose',
        color: Colors.red,
        onTap: () => Get.toNamed(Routes.DIABETES),
      ));
    }
    
    if (controller.hasCriseGastrite) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.sick,
        title: 'Gastrite',
        subtitle: 'Crises registradas',
        color: Colors.orange,
        onTap: () => Get.toNamed(Routes.CRISE_GASTRITE_HISTORY),
      ));
    }
    
    if (controller.hasEventoClinico) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.medical_services,
        title: 'Eventos Clínicos',
        subtitle: 'Consultas e exames',
        color: Colors.blue,
        onTap: () => Get.toNamed(Routes.EVENTO_CLINICO_HISTORY),
      ));
    }
    
    if (controller.hasMenstruacao) {
      shortcuts.add(_buildShortcutCard(
        icon: Icons.woman,
        title: 'Menstruação',
        subtitle: 'Ciclo menstrual',
        color: Colors.pink,
        onTap: () => Get.toNamed(Routes.MENSTRUACAO_HISTORY),
      ));
    }
    
    // Sempre incluir notas médicas
    shortcuts.add(_buildShortcutCard(
      icon: Icons.note_add,
      title: 'Notas Médicas',
      subtitle: 'Anotações pessoais',
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium.copyWith(
                      color: const Color(0xFF1E293B),
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
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoShortcutsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_open,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Sem atalhos',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Nenhum exame recente encontrado',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
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
          backgroundColor: const Color(0xFF00324A), // Nova cor azul
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
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
                  color: const Color(0xFF00324A), // Nova cor azul
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

  // Widget personalizado para a logo do PulseFlow
  Widget _buildPulseFlowLogo() {
    return Container(
      width: 140,
      height: 45,
      child: Image.asset(
        'assets/images/PulseNegativo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback caso a imagem não seja encontrada
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

  // Constrói a imagem do perfil baseada no tipo (base64, URL ou arquivo local)
  Widget _buildProfileImage(HomeController controller) {
    final photo = controller.getProfilePhoto();
    if (photo == null) {
      return const Icon(
        Icons.person,
        color: Colors.white,
        size: 40,
      );
    }

    // Se é base64
    if (controller.isBase64Photo(photo)) {
      try {
        return Image.memory(
          base64Decode(photo.split(',')[1]), // Remove o prefixo data:image/jpeg;base64,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            );
          },
        );
      } catch (e) {
        return const Icon(
          Icons.person,
          color: Colors.white,
          size: 40,
        );
      }
    }
    
    // Se é URL (http/https)
    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            color: Colors.white,
            size: 40,
          );
        },
      );
    }
    
    // Se é arquivo local
    return Image.file(
      File(photo),
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.person,
          color: Colors.white,
          size: 40,
        );
      },
    );
  }
} 