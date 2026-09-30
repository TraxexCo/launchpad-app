import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  ReportService._();

  static Future<void> submit({
    required String targetType,
    required String targetLabel,
    required String reason,
    String? details,
  }) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to submit a report.');
    final cleanDetails = details?.trim() ?? '';
    await client.from('reports').insert({
      'reporter_id': userId,
      'target_type': targetType,
      'target_label': targetLabel.trim(),
      'reason': reason,
      'details': cleanDetails.isEmpty ? null : cleanDetails,
    });
  }
}
