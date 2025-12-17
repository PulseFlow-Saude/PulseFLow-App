import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../screens/home/home_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../../widgets/pulse_side_menu.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationsController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final horizontalPadding = isCompact ? 12.0 : 20.0;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.blueSystemOverlayStyle,
          child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const PulseSideMenu(),
        bottomNavigationBar: const PulseBottomNavigation(showOutline: false),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF011627), Color(0xFF023A63)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
            child: Column(
                  children: [
                _buildHeader(controller),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFilterBar(controller, horizontalPadding),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                            child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
                                      ),
                                    );
                                  }

                                  final filtered = controller.filteredNotifications;

                                  if (filtered.isEmpty) {
                                    return _buildEmptyState(controller);
                                  }

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (controller.filter.value == 'all' && controller.unreadCount > 0)
                                        _buildMarkAllReadButton(controller),
                                      Expanded(
                                        child: RefreshIndicator(
                                          onRefresh: () async {
                                            await controller.loadNotifications();
                                            try {
                                              final homeController = Get.find<HomeController>();
                                              await homeController.loadNotificationsCount();
                                            } catch (e) {}
                                          },
                                          color: const Color(0xFF00324A),
                                          child: ListView.separated(
                                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: horizontalPadding,
                                              vertical: isCompact ? 14 : 20,
                                            ),
                                            itemCount: filtered.length,
                                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                                            itemBuilder: (context, index) {
                                              final notification = filtered[index];
                                              return _buildNotificationCard(controller, notification);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(NotificationsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notificações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.unreadCount > 0
                          ? '${controller.unreadCount} notificações pendentes'
                          : 'Tudo em dia',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(NotificationsController controller, double horizontalPadding) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding - 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            _getSelectedFilterIcon(controller.filter.value),
            size: 18,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getSelectedFilterLabel(controller.filter.value),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _openFilterSheet(controller),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Alterar'),
          )
        ],
      ),
    );
  }

  IconData _getSelectedFilterIcon(String value) {
    switch (value) {
      case 'unread':
        return Icons.mark_email_unread_outlined;
      case 'appointments':
        return Icons.event_available_outlined;
      case 'archived':
        return Icons.archive_outlined;
      default:
        return Icons.ballot_outlined;
    }
  }

  String _getSelectedFilterLabel(String value) {
    switch (value) {
      case 'unread':
        return 'Exibindo apenas não lidas';
      case 'appointments':
        return 'Filtrando agendamentos';
      case 'archived':
        return 'Arquivadas';
      default:
        return 'Todas as notificações';
    }
  }

  void _openFilterSheet(NotificationsController controller) {
    final filters = [
      _FilterOption(
        value: 'all',
        label: 'Todas',
        description: 'Exibe todas as notificações disponíveis',
        icon: Icons.ballot_outlined,
      ),
      _FilterOption(
        value: 'unread',
        label: 'Não lidas',
        description: 'Somente as notificações pendentes de leitura',
        icon: Icons.mark_email_unread_outlined,
      ),
      _FilterOption(
        value: 'appointments',
        label: 'Agendamentos',
        description: 'Alertas de consultas, exames e pulse key',
        icon: Icons.event_available_outlined,
      ),
      _FilterOption(
        value: 'archived',
        label: 'Arquivadas',
        description: 'Itens que você arquivou anteriormente',
        icon: Icons.archive_outlined,
      ),
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: filters.map((filter) {
                final isSelected = controller.filter.value == filter.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 6 : 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () {
                      controller.setFilter(filter.value);
                      Get.back();
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? const Color(0xFF00324A) : const Color(0xFFF1F5F9),
                      child: Icon(
                        filter.icon,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    title: Text(
                      filter.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF00324A) : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(filter.description),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF00324A))
                        : const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5F5)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(NotificationsController controller, _FilterChipData data) {
    return Obx(() {
      final isSelected = controller.filter.value == data.value;
      return GestureDetector(
        onTap: () => controller.setFilter(data.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFFE2E8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.16),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
            border: Border.all(
              color: isSelected ? const Color(0xFF00324A) : Colors.white.withOpacity(0.0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00324A).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                size: 18,
                color: isSelected ? const Color(0xFF00324A) : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00324A) : const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMarkAllReadButton(NotificationsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => controller.markAllAsRead(),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Marcar todas como lidas'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00324A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationsController controller,
    NotificationItem notification,
  ) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.archive_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          controller.archiveNotification(notification.id);
          Get.snackbar(
            'Arquivado',
            'Notificação arquivada',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        } else {
          _showDeleteDialog(controller, notification);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmDialog(controller, notification);
        }
        return true;
      },
      child: InkWell(
        onTap: () => controller.handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isUnread
                ? const LinearGradient(
                    colors: [Color(0xFFF0F5FF), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.titleSmall.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
                            style: TextStyle(
                              color: _getNotificationColor(notification.type),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((notification.type ?? '').toLowerCase() == 'appointment')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF97316)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Aviso de consulta',
                                    style: TextStyle(
                                      color: Color(0xFFF97316),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.formatDate(notification.date),
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: notification.isArchived ? 'unarchive' : 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    notification.isArchived ? Icons.unarchive : Icons.archive,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(notification.isArchived ? 'Desarquivar' : 'Arquivar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'archive') {
                              controller.archiveNotification(notification.id);
                            } else if (value == 'unarchive') {
                              controller.unarchiveNotification(notification.id);
                            } else if (value == 'delete') {
                              _showDeleteDialog(controller, notification);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationsController controller) {
    String message;
    IconData icon;
    
    switch (controller.filter.value) {
      case 'unread':
        message = 'Você não possui notificações não lidas';
        icon = Icons.mark_email_read_outlined;
        break;
      case 'archived':
        message = 'Você não possui notificações arquivadas';
        icon = Icons.archive_outlined;
        break;
      default:
        message = 'Você não possui notificações no momento';
        icon = Icons.notifications_none_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 72,
                color: const Color(0xFF00324A).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTheme.titleMedium.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Novas notificações aparecerão aqui',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => controller.loadNotifications(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00324A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Atualizar agora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'exam':
        return Icons.assignment_rounded;
      case 'prescription':
        return Icons.medication_rounded;
      case 'pulse_key':
        return Icons.vpn_key_rounded;
      case 'profile_update':
        return Icons.person_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'appointment':
        return const Color(0xFF00324A);
      case 'reminder':
        return Colors.orange;
      case 'exam':
        return Colors.blue;
      case 'prescription':
        return Colors.green;
      case 'pulse_key':
        return Colors.purple;
      case 'profile_update':
        return Colors.teal;
      default:
        return const Color(0xFF00324A);
    }
  }

  Future<bool> _showDeleteConfirmDialog(NotificationsController controller, NotificationItem notification) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Excluir notificação',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Deseja realmente excluir esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showDeleteDialog(NotificationsController controller, NotificationItem notification) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Excluir notificação',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Deseja realmente excluir esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNotification(notification.id);
              Get.back();
              Get.snackbar(
                'Excluído',
                'Notificação excluída',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'appointment':
        return 'Consulta';
      case 'reminder':
        return 'Lembrete';
      case 'exam':
        return 'Exame';
      case 'prescription':
        return 'Prescrição';
      case 'pulse_key':
        return 'Pulse Key';
      case 'profile_update':
        return 'Perfil';
      case 'updates':
      default:
        return 'Atualização';
    }
  }

}

class _FilterChipData {
  final String value;
  final String label;
  final IconData icon;

  const _FilterChipData(this.value, this.label, this.icon);
}

class _FilterOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const _FilterOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

