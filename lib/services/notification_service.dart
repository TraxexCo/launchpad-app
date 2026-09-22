import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  /// Fetch all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    return _client.from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Mark a notification as read
  Future<void> markAsRead(int id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }

  /// Delete a notification
  Future<void> deleteNotification(int id) async {
    await _client.from('notifications').delete().eq('id', id);
  }
}
