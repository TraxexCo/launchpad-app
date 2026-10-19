import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ContractDeliverable {
  final int id;
  final int submissionNumber;
  final String title;
  final String summary;
  final String? linkUrl;
  final String? storagePath;
  final String? originalFileName;
  final DateTime createdAt;

  const ContractDeliverable({
    required this.id,
    required this.submissionNumber,
    required this.title,
    required this.summary,
    this.linkUrl,
    this.storagePath,
    this.originalFileName,
    required this.createdAt,
  });

  factory ContractDeliverable.fromJson(Map<String, dynamic> json) =>
      ContractDeliverable(
        id: json['id'] as int,
        submissionNumber: json['submission_number'] as int,
        title: json['title'] as String,
        summary: json['summary'] as String,
        linkUrl: json['link_url'] as String?,
        storagePath: json['storage_path'] as String?,
        originalFileName: json['original_file_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ContractEvent {
  final int id;
  final String type;
  final String? message;
  final DateTime createdAt;

  const ContractEvent({
    required this.id,
    required this.type,
    this.message,
    required this.createdAt,
  });

  factory ContractEvent.fromJson(Map<String, dynamic> json) => ContractEvent(
    id: json['id'] as int,
    type: json['event_type'] as String,
    message: json['message'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class DisputeEvidence {
  final int id;
  final String submittedBy;
  final String statement;
  final String? storagePath;
  final String? originalFileName;
  final DateTime createdAt;

  const DisputeEvidence({
    required this.id,
    required this.submittedBy,
    required this.statement,
    this.storagePath,
    this.originalFileName,
    required this.createdAt,
  });

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) =>
      DisputeEvidence(
        id: json['id'] as int,
        submittedBy: json['submitted_by'] as String,
        statement: json['statement'] as String,
        storagePath: json['storage_path'] as String?,
        originalFileName: json['original_file_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ContractItem {
  final int id;
  final int proposalId;
  final String status;
  final DateTime agreedAt;
  final DateTime? completedAt;
  final String jobTitle;
  final String jobCategory;
  final double budget;
  final int timelineWeeks;
  final String studentId;
  final String studentName;
  final String businessId;
  final String businessName;
  final bool reviewedByMe;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? fundedAt;
  final DateTime? startedAt;
  final String? revisionMessage;
  final String? cancellationReason;
  final String? disputeReason;
  final DateTime? disputeDeadline;

  const ContractItem({
    required this.id,
    required this.proposalId,
    required this.status,
    required this.agreedAt,
    this.completedAt,
    required this.jobTitle,
    required this.jobCategory,
    required this.budget,
    required this.timelineWeeks,
    required this.studentId,
    required this.studentName,
    required this.businessId,
    required this.businessName,
    this.reviewedByMe = false,
    this.paymentStatus = 'unpaid',
    this.paymentReference,
    this.fundedAt,
    this.startedAt,
    this.revisionMessage,
    this.cancellationReason,
    this.disputeReason,
    this.disputeDeadline,
  });
}

class ContractService {
  static final ContractService _instance = ContractService._internal();
  factory ContractService() => _instance;
  ContractService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ContractItem>> getMyContracts({
    int page = 0,
    int pageSize = 30,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('contracts')
        .select('''
      id,
      proposal_id,
      job_id,
      business_id,
      student_id,
      agreed_budget,
      agreed_timeline_weeks,
      status,
      agreed_at,
      completed_at,
      funded_at,
      started_at,
      revision_message,
      cancellation_reason,
      dispute_reason,
      dispute_deadline,
      payments (
        status,
        reference_number
      ),
      jobs (
        id,
        title,
        category,
        business_id
      ),
      proposals (
        id
      )
    ''')
        .order('agreed_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    if (rows.isEmpty) return [];

    final studentIds = <String>{};
    final businessIds = <String>{};

    for (final row in rows) {
      final sId = row['student_id'] as String?;
      final bId = row['business_id'] as String?;
      if (sId != null) studentIds.add(sId);
      if (bId != null) businessIds.add(bId);
    }

    final studentProfiles = studentIds.isNotEmpty
        ? await _client
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', studentIds.toList())
        : <Map<String, dynamic>>[];
    final businessProfiles = businessIds.isNotEmpty
        ? await _client
              .from('business_profiles')
              .select('user_id, business_name')
              .inFilter('user_id', businessIds.toList())
        : <Map<String, dynamic>>[];

    final contractIds = rows.map((row) => row['id'] as int).toList();
    final reviewRows = await _client
        .from('reviews')
        .select('contract_id')
        .eq('reviewer_id', userId)
        .inFilter('contract_id', contractIds);
    final reviewedContractIds = {
      for (final review in reviewRows) review['contract_id'] as int,
    };

    final studentNameMap = {
      for (final s in studentProfiles)
        s['id'] as String: s['full_name'] as String,
    };
    final businessNameMap = {
      for (final b in businessProfiles)
        b['user_id'] as String: b['business_name'] as String,
    };

    final items = <ContractItem>[];
    for (final row in rows) {
      final job = row['jobs'] as Map<String, dynamic>?;
      final sId = row['student_id'] as String? ?? '';
      final bId = row['business_id'] as String? ?? '';

      items.add(
        ContractItem(
          id: row['id'] as int,
          proposalId: row['proposal_id'] as int,
          status: row['status'] as String? ?? 'in_progress',
          agreedAt:
              DateTime.tryParse(row['agreed_at'] as String? ?? '') ??
              DateTime.now(),
          completedAt: row['completed_at'] != null
              ? DateTime.tryParse(row['completed_at'] as String)
              : null,
          jobTitle: job?['title'] as String? ?? 'Project Contract',
          jobCategory: job?['category'] as String? ?? 'Contract',
          budget: double.tryParse(row['agreed_budget']?.toString() ?? '0') ?? 0,
          timelineWeeks:
              int.tryParse(row['agreed_timeline_weeks']?.toString() ?? '1') ??
              1,
          studentId: sId,
          studentName: studentNameMap[sId] ?? 'Student',
          businessId: bId,
          businessName: businessNameMap[bId] ?? 'Business',
          reviewedByMe: reviewedContractIds.contains(row['id'] as int),
          paymentStatus: _paymentValue(row['payments'], 'status') ?? 'unpaid',
          paymentReference: _paymentValue(row['payments'], 'reference_number'),
          fundedAt: row['funded_at'] == null
              ? null
              : DateTime.tryParse(row['funded_at'] as String),
          startedAt: row['started_at'] == null
              ? null
              : DateTime.tryParse(row['started_at'] as String),
          revisionMessage: row['revision_message'] as String?,
          cancellationReason: row['cancellation_reason'] as String?,
          disputeReason: row['dispute_reason'] as String?,
          disputeDeadline: row['dispute_deadline'] == null
              ? null
              : DateTime.tryParse(row['dispute_deadline'] as String),
        ),
      );
    }

    return items;
  }

  String? _paymentValue(dynamic relation, String key) {
    if (relation is Map) return relation[key]?.toString();
    if (relation is List && relation.isNotEmpty && relation.first is Map) {
      return (relation.first as Map)[key]?.toString();
    }
    return null;
  }

  Future<ContractItem> getContract(int contractId) async {
    final items = await getMyContracts();
    return items.firstWhere(
      (item) => item.id == contractId,
      orElse: () =>
          throw const PostgrestException(message: 'Contract not found'),
    );
  }

  Future<List<ContractDeliverable>> getDeliverables(int contractId) async {
    final rows = await _client
        .from('contract_deliverables')
        .select()
        .eq('contract_id', contractId)
        .order('submission_number', ascending: false)
        .range(0, 49);
    return rows.map(ContractDeliverable.fromJson).toList();
  }

  Future<List<ContractEvent>> getEvents(int contractId) async {
    final rows = await _client
        .from('contract_events')
        .select()
        .eq('contract_id', contractId)
        .order('created_at', ascending: false)
        .range(0, 99);
    return rows.map(ContractEvent.fromJson).toList();
  }

  Future<List<DisputeEvidence>> getDisputeEvidence(int contractId) async {
    final rows = await _client
        .from('dispute_evidence')
        .select()
        .eq('contract_id', contractId)
        .order('created_at');
    return rows.map(DisputeEvidence.fromJson).toList();
  }

  Future<String> uploadDisputeEvidence({
    required int contractId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Sign in required');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$contractId/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _client.storage
        .from('dispute-evidence')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    return path;
  }

  Future<void> submitDisputeEvidence({
    required int contractId,
    required String statement,
    String? storagePath,
    String? fileName,
  }) => _client.rpc(
    'submit_dispute_evidence',
    params: {
      'contract_key': contractId,
      'statement_text': statement.trim(),
      'evidence_storage_path': storagePath,
      'evidence_file_name': fileName,
    },
  );

  Future<String> createDisputeFileUrl(String path) =>
      _client.storage.from('dispute-evidence').createSignedUrl(path, 600);

  Future<void> startWork(int contractId) async {
    await _client.rpc(
      'start_contract_work',
      params: {'contract_key': contractId},
    );
  }

  Future<String> uploadDeliverable({
    required int contractId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Sign in required');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$contractId/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _client.storage
        .from('contract-deliverables')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    return path;
  }

  Future<void> submitDeliverable({
    required int contractId,
    required String title,
    required String summary,
    String? linkUrl,
    String? storagePath,
    String? fileName,
  }) async {
    await _client.rpc(
      'submit_contract_deliverable',
      params: {
        'contract_key': contractId,
        'deliverable_title': title.trim(),
        'deliverable_summary': summary.trim(),
        'deliverable_link': linkUrl?.trim(),
        'deliverable_storage_path': storagePath,
        'deliverable_file_name': fileName,
      },
    );
  }

  Future<String> createFileUrl(String path) =>
      _client.storage.from('contract-deliverables').createSignedUrl(path, 600);

  Future<void> cancelContract(int contractId, String reason) async {
    await _client.rpc(
      'cancel_contract',
      params: {'contract_key': contractId, 'reason_text': reason.trim()},
    );
  }

  Future<void> disputeContract(int contractId, String reason) async {
    await _client.rpc(
      'open_contract_dispute',
      params: {'contract_key': contractId, 'reason_text': reason.trim()},
    );
  }

  Future<void> respondToCompletion(
    int contractId, {
    required bool approve,
    String? revisionNote,
  }) async {
    await _client.rpc(
      'respond_contract_completion',
      params: {
        'contract_key': contractId,
        'approve_completion': approve,
        'revision_note': revisionNote?.trim(),
      },
    );
  }

  Future<void> submitReview({
    required int contractId,
    required int rating,
    required String body,
  }) async {
    await _client.rpc(
      'submit_contract_review',
      params: {
        'contract_key': contractId,
        'rating_value': rating,
        'review_body': body.trim(),
      },
    );
  }
}
