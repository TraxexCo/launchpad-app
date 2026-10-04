import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  /// Fetch all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    return _client
        .from('notifications')
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
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  /// Delete a notification
  Future<void> deleteNotification(int id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Stream<int> unreadCountStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.where((row) => row['is_read'] != true).length);
  }

  Future<Map<String, bool>> getPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const {'jobs': true, 'proposals': true, 'messages': true};
    }
    final row = await _client
        .from('notification_preferences')
        .select('jobs,proposals,messages')
        .eq('user_id', userId)
        .maybeSingle();
    return {
      'jobs': row?['jobs'] as bool? ?? true,
      'proposals': row?['proposals'] as bool? ?? true,
      'messages': row?['messages'] as bool? ?? true,
    };
  }

  Future<void> setPreference(String kind, bool enabled) async {
    if (!const {'jobs', 'proposals', 'messages'}.contains(kind)) {
      throw ArgumentError.value(kind, 'kind');
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notification_preferences').upsert({
      'user_id': userId,
      kind: enabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
