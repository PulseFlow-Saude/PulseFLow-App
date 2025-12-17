import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';
import '../../services/notifications/notification_storage.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final bool isArchived;
  final String? type;
  final String? link;
  final bool isLocal;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.isArchived = false,
    this.type,
    this.link,
    this.isLocal = false,
  });

  NotificationItem copyWith({
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    bool? isArchived,
    String? type,
    String? link,
    bool? isLocal,
  }) {
    return NotificationItem(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      type: type ?? this.type,
      link: link ?? this.link,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}

class NotificationsController extends GetxController {
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  List<NotificationItem> get filteredNotifications {
    switch (filter.value) {
      case 'unread':
        return notifications.where((n) => !n.isRead && !n.isArchived).toList();
      case 'appointments':
        return notifications
            .where((n) =>
                !n.isArchived &&
                (n.type?.toLowerCase() == 'appointment' ||
                    n.type?.toLowerCase() == 'appointments'))
            .toList();
      case 'archived':
        return notifications.where((n) => n.isArchived).toList();
      default:
        return notifications.where((n) => !n.isArchived).toList();
    }
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final notificationsList = <NotificationItem>[];
      final existingIds = <String>{};

      try {
        final apiService = ApiService();
        final notificacoesData = await apiService.buscarNotificacoes();

        for (final notif in notificacoesData) {
          final item = _mapRemoteNotification(notif);
          if (item != null) {
            notificationsList.add(item);
            existingIds.add(item.id);
          }
        }
      } catch (_) {}

      try {
        final localData = await NotificationStorage.loadNotifications();
        for (final local in localData) {
          final localId = local['id']?.toString() ?? '';
          if (localId.isEmpty || existingIds.contains(localId)) continue;

          final localDate =
              DateTime.tryParse(local['createdAt']?.toString() ?? '');

          notificationsList.add(NotificationItem(
            id: localId,
            title: local['title']?.toString() ?? 'Notificação',
            message: local['message']?.toString() ?? '',
            date: localDate ?? DateTime.now(),
            isRead: local['isRead'] == true,
            isArchived: local['isArchived'] == true,
            type: local['type']?.toString(),
            link: local['link']?.toString(),
            isLocal: true,
          ));
        }
      } catch (_) {}

      notificationsList.sort((a, b) => b.date.compareTo(a.date));
      notifications.value = notificationsList;
      notifications.refresh();
      update();
    } finally {
      isLoading.value = false;
    }
  }

  NotificationItem? _mapRemoteNotification(Map<String, dynamic> notif) {
    try {
      String id = '';
      if (notif['_id'] != null) {
        if (notif['_id'] is String) {
          id = notif['_id'];
        } else if (notif['_id'] is Map) {
          id = notif['_id']['\$oid']?.toString() ??
              notif['_id']['oid']?.toString() ??
              notif['_id'].toString();
        } else {
          id = notif['_id'].toString();
        }
      }

      if (id.isEmpty) {
        return null;
      }

      final title = notif['title']?.toString() ?? 'Notificação';
      final description = notif['description']?.toString() ?? '';
      final unread = notif['unread'] == true ||
          notif['unread'] == 'true' ||
          notif['unread'] == 1 ||
          notif['unread'] == '1';
      final archived = notif['archived'] == true ||
          notif['archived'] == 'true' ||
          notif['archived'] == 1 ||
          notif['archived'] == '1';
      final type = notif['type']?.toString() ?? 'updates';
      final link = notif['link']?.toString();

      DateTime date;
      if (notif['createdAt'] != null) {
        if (notif['createdAt'] is String) {
          date = DateTime.tryParse(notif['createdAt']) ?? DateTime.now();
        } else if (notif['createdAt'] is Map &&
            notif['createdAt']['\$date'] != null) {
          date = DateTime.tryParse(notif['createdAt']['\$date'].toString()) ??
              DateTime.now();
        } else if (notif['createdAt'] is Map &&
            notif['createdAt']['date'] != null) {
          date = DateTime.tryParse(notif['createdAt']['date'].toString()) ??
              DateTime.now();
        } else {
          date = DateTime.now();
        }
      } else {
        date = DateTime.now();
      }

      return NotificationItem(
        id: id,
        title: title,
        message: description,
        date: date,
        isRead: !unread,
        isArchived: archived,
        type: type,
        link: link,
      );
    } catch (_) {
      return null;
    }
  }

  int get unreadCount {
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return;
    }

    final current = notifications[index];

    try {
      if (!current.isLocal) {
        final apiService = ApiService();
        await apiService.marcarNotificacaoComoLida(notificationId);
      }

      notifications[index] = current.copyWith(isRead: true);
      notifications.refresh();

      if (current.isLocal) {
        await NotificationStorage.markAsRead(notificationId, true);
      }

      _updateHomeNotificationsCount();
    } catch (_) {}
  }
  
  void _updateHomeNotificationsCount() {
    try {
      final homeController = Get.find<HomeController>();
      homeController.loadNotificationsCount();
    } catch (e) {
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiService = ApiService();
      await apiService.marcarTodasNotificacoesComoLidas();
    } catch (_) {}

    final localIds = <String>[];

    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      if (notifications[i].isLocal) {
        localIds.add(notifications[i].id);
      }
    }

    for (final localId in localIds) {
      await NotificationStorage.markAsRead(localId, true);
    }

    notifications.refresh();
    _updateHomeNotificationsCount();
  }

  Future<void> deleteNotification(String notificationId) async {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return;
    }

    final current = notifications[index];

    try {
      final apiService = ApiService();
      if (!current.isLocal) {
        await apiService.excluirNotificacao(notificationId);
      }

      notifications.removeAt(index);
      notifications.refresh();

      if (current.isLocal) {
        await NotificationStorage.delete(notificationId);
      }

      _updateHomeNotificationsCount();
    } catch (_) {}
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final item = notifications[index];
        if (!item.isLocal) {
          await ApiService().arquivarNotificacao(notificationId);
        } else {
          await NotificationStorage.markAsArchived(notificationId, true);
        }

        notifications[index] = item.copyWith(isArchived: true);
        notifications.refresh();
      }
    } catch (_) {}
  }

  Future<void> unarchiveNotification(String notificationId) async {
    try {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final item = notifications[index];
        if (!item.isLocal) {
          await ApiService().desarquivarNotificacao(notificationId);
        } else {
          await NotificationStorage.markAsArchived(notificationId, false);
        }

        notifications[index] = item.copyWith(isArchived: false);
        notifications.refresh();
      }
    } catch (_) {}
  }

  void setFilter(String newFilter) {
    filter.value = newFilter;
    loadNotifications();
  }

  Future<void> clearAll() async {
    try {
      for (final notif in notifications) {
        await deleteNotification(notif.id);
      }
      notifications.clear();
      notifications.refresh();
      await NotificationStorage.clear();
    } catch (e) {
    }
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Agora';
        }
        return '${difference.inMinutes} min atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void handleNotificationTap(NotificationItem notification) {
    markAsRead(notification.id);
    
    if (notification.type == 'appointment') {
      Get.toNamed(Routes.APPOINTMENT_SCHEDULER);
    } else if (notification.type == 'exam') {
      Get.toNamed(Routes.EXAME_LIST);
    } else if (notification.type == 'prescription') {
    } else if (notification.type == 'pulse_key') {
      Get.toNamed(Routes.PULSE_KEY);
    } else if (notification.type == 'profile_update') {
      Get.toNamed(Routes.PROFILE);
    }
  }
}

