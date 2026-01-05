import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsManager {
  static final NotificationsManager _instance = NotificationsManager._internal();
  factory NotificationsManager() => _instance;
  NotificationsManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<List<Map<String, dynamic>>> notifications = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Fetch Notifications
  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      notifications.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Mark as Read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // Update local state immediately for responsiveness
      final currentList = List<Map<String, dynamic>>.from(notifications.value);
      final index = currentList.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        currentList[index]['is_read'] = true;
        notifications.value = currentList;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Delete Notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      
      final currentList = List<Map<String, dynamic>>.from(notifications.value);
      currentList.removeWhere((n) => n['id'] == notificationId);
      notifications.value = currentList;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
  // Send Notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      // Basic insert
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
