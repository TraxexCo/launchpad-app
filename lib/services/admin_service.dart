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

  Future<List<Map<String, dynamic>>> verificationQueue({
    int page = 0,
  }) => _client
      .from('verification_documents')
      .select(
        'id,owner_id,document_type,status,submitted_at,review_note,profiles(full_name,role)',
      )
      .order('submitted_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

  Future<List<Map<String, dynamic>>> reports({int page = 0}) => _client
      .from('reports')
      .select(
        'id,reporter_id,target_type,target_label,reason,details,status,created_at,resolution_note',
      )
      .order('created_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

  Future<List<Map<String, dynamic>>> disputes({int page = 0}) => _client
      .from('contracts')
      .select(
        'id,status,dispute_reason,disputed_at,student_id,business_id,jobs(title),payments(status,amount,reference_number)',
      )
      .eq('status', 'disputed')
      .order('disputed_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

  Future<List<Map<String, dynamic>>> payments({int page = 0}) => _client
      .from('payments')
      .select(
        'id,contract_id,amount,status,reference_number,payment_method,provider_payment_id,created_at,updated_at',
      )
      .order('created_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

  Future<List<Map<String, dynamic>>> accounts({int page = 0}) => _client
      .from('profiles')
      .select('id,role,full_name,created_at,suspended_at,suspension_reason')
      .order('created_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

  Future<List<Map<String, dynamic>>> jobs({int page = 0}) => _client
      .from('jobs')
      .select(
        'id,business_id,title,budget,status,location,created_at,moderated_at,moderation_note,business_profiles(business_name)',
      )
      .order('created_at', ascending: false)
      .range(page * 50, (page + 1) * 50 - 1);

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

  Future<Map<String, dynamic>> disputeCase(int contractId) async {
    final result = await _client.rpc(
      'admin_get_dispute_case',
      params: {'contract_key': contractId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> deliverableFileUrl(String path) =>
      _client.storage.from('contract-deliverables').createSignedUrl(path, 600);

  Future<void> setUserSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  }) => _client.rpc(
    'admin_set_user_suspension',
    params: {
      'target_user': userId,
      'suspend_user': suspended,
      'reason_text': reason,
    },
  );

  Future<void> moderateJob(
    int jobId, {
    required bool close,
    required String note,
  }) => _client.rpc(
    'admin_moderate_job',
    params: {'job_key': jobId, 'close_job': close, 'note_text': note},
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
