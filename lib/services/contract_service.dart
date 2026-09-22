import 'package:supabase_flutter/supabase_flutter.dart';

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
  });
}

class ContractService {
  static final ContractService _instance = ContractService._internal();
  factory ContractService() => _instance;
  ContractService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ContractItem>> getMyContracts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client.from('contracts').select('''
      id,
      proposal_id,
      status,
      agreed_at,
      completed_at,
      proposals (
        id,
        proposed_budget,
        estimated_timeline_weeks,
        student_id,
        jobs (
          id,
          title,
          category,
          business_id
        )
      )
    ''').order('agreed_at', ascending: false);

    if (rows.isEmpty) return [];

    final studentIds = <String>{};
    final businessIds = <String>{};

    for (final row in rows) {
      final prop = row['proposals'] as Map<String, dynamic>?;
      if (prop != null) {
        final sId = prop['student_id'] as String?;
        if (sId != null) studentIds.add(sId);

        final job = prop['jobs'] as Map<String, dynamic>?;
        final bId = job?['business_id'] as String?;
        if (bId != null) businessIds.add(bId);
      }
    }

    final studentProfiles = studentIds.isNotEmpty
        ? await _client.from('profiles').select('id, full_name').inFilter('id', studentIds.toList())
        : <Map<String, dynamic>>[];
    final businessProfiles = businessIds.isNotEmpty
        ? await _client.from('business_profiles').select('user_id, business_name').inFilter('user_id', businessIds.toList())
        : <Map<String, dynamic>>[];

    final studentNameMap = {for (final s in studentProfiles) s['id'] as String: s['full_name'] as String};
    final businessNameMap = {for (final b in businessProfiles) b['user_id'] as String: b['business_name'] as String};

    final items = <ContractItem>[];
    for (final row in rows) {
      final prop = row['proposals'] as Map<String, dynamic>?;
      final job = prop?['jobs'] as Map<String, dynamic>?;

      final sId = prop?['student_id'] as String? ?? '';
      final bId = job?['business_id'] as String? ?? '';

      items.add(ContractItem(
        id: row['id'] as int,
        proposalId: row['proposal_id'] as int,
        status: row['status'] as String? ?? 'in_progress',
        agreedAt: DateTime.tryParse(row['agreed_at'] as String? ?? '') ?? DateTime.now(),
        completedAt: row['completed_at'] != null ? DateTime.tryParse(row['completed_at'] as String) : null,
        jobTitle: job?['title'] as String? ?? 'Project Contract',
        jobCategory: job?['category'] as String? ?? 'Contract',
        budget: double.tryParse(prop?['proposed_budget']?.toString() ?? '0') ?? 0.0,
        timelineWeeks: int.tryParse(prop?['estimated_timeline_weeks']?.toString() ?? '1') ?? 1,
        studentId: sId,
        studentName: studentNameMap[sId] ?? 'Student',
        businessId: bId,
        businessName: businessNameMap[bId] ?? 'Business',
      ));
    }

    return items;
  }
}
