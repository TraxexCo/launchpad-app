import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationSubmission {
  final int id;
  final String documentType;
  final String status;
  final DateTime submittedAt;

  const VerificationSubmission({
    required this.id,
    required this.documentType,
    required this.status,
    required this.submittedAt,
  });

  factory VerificationSubmission.fromJson(Map<String, dynamic> json) =>
      VerificationSubmission(
        id: json['id'] as int,
        documentType: json['document_type'] as String,
        status: json['status'] as String,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
      );
}

class VerificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<VerificationSubmission?> latest() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('verification_documents')
        .select('id,document_type,status,submitted_at')
        .eq('owner_id', userId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : VerificationSubmission.fromJson(row);
  }

  Future<void> submit({
    required String documentType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Sign in required');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _client.storage
        .from('verification-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    await _client.rpc(
      'submit_verification_document',
      params: {'document_kind': documentType, 'file_path': path},
    );
  }
}
