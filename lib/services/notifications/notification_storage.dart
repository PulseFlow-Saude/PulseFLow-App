import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const _storageKey = 'pf_local_notifications';
  static const _maxItems = 100;

  static Future<List<Map<String, dynamic>>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> _persist(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(notifications));
  }

  static Future<void> addNotification({
    required String id,
    required String title,
    required String message,
    String type = 'updates',
    String? link,
    DateTime? createdAt,
    bool isRead = false,
    bool isArchived = false,
  }) async {
    final list = await loadNotifications();
    final normalized = {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'link': link,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'isRead': isRead,
      'isArchived': isArchived,
    };

    list.removeWhere((item) => item['id']?.toString() == id);
    list.insert(0, normalized);

    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }

    await _persist(list);
  }

  static Future<void> markAsRead(String id, bool isRead) async {
    final list = await loadNotifications();
    final index = list.indexWhere((item) => item['id']?.toString() == id);
    if (index != -1) {
      list[index]['isRead'] = isRead;
      await _persist(list);
    }
  }

  static Future<void> markAsArchived(String id, bool isArchived) async {
    final list = await loadNotifications();
    final index = list.indexWhere((item) => item['id']?.toString() == id);
    if (index != -1) {
      list[index]['isArchived'] = isArchived;
      await _persist(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await loadNotifications();
    list.removeWhere((item) => item['id']?.toString() == id);
    await _persist(list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

