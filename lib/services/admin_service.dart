import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('admin_users')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<List<Map<String, dynamic>>> verificationQueue() => _client
      .from('verification_documents')
      .select(
        'id,owner_id,document_type,status,submitted_at,review_note,profiles(full_name,role)',
      )
      .order('submitted_at', ascending: false);

  Future<List<Map<String, dynamic>>> reports() => _client
      .from('reports')
      .select(
        'id,reporter_id,target_type,target_label,reason,details,status,created_at,resolution_note',
      )
      .order('created_at', ascending: false);

  Future<List<Map<String, dynamic>>> disputes() => _client
      .from('contracts')
      .select(
        'id,status,dispute_reason,disputed_at,student_id,business_id,jobs(title),payments(status,amount,reference_number)',
      )
      .eq('status', 'disputed')
      .order('disputed_at', ascending: false);

  Future<List<Map<String, dynamic>>> payments() => _client
      .from('payments')
      .select(
        'id,contract_id,amount,status,reference_number,payment_method,created_at,updated_at',
      )
      .order('created_at', ascending: false)
      .limit(100);

  Future<void> reviewVerification(int id, bool approve, String? note) =>
      _client.rpc(
        'admin_review_verification',
        params: {
          'document_key': id,
          'approve_document': approve,
          'note_text': note,
        },
      );

  Future<void> resolveReport(int id, String status, String note) => _client.rpc(
    'admin_resolve_report',
    params: {'report_key': id, 'resolution_status': status, 'note_text': note},
  );

  Future<void> resolveDispute(int id, String decision, String note) =>
      _client.rpc(
        'admin_resolve_dispute',
        params: {'contract_key': id, 'decision': decision, 'note_text': note},
      );

  Future<String> verificationFileUrl(String ownerId, int documentId) async {
    final row = await _client
        .from('verification_documents')
        .select('storage_path')
        .eq('id', documentId)
        .eq('owner_id', ownerId)
        .single();
    return _client.storage
        .from('verification-documents')
        .createSignedUrl(row['storage_path'] as String, 600);
  }
}
