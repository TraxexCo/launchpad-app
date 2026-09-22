import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/proposal.dart';

class ProposalService {
  static final ProposalService _instance = ProposalService._internal();
  factory ProposalService() => _instance;
  ProposalService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Proposal>> getMyProposals() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client.from('proposals').select()
        .eq('student_id', userId).order('created_at', ascending: false);
    return _decorate(rows);
  }

  Future<List<Proposal>> getProposalsByJob(int jobId) async {
    final rows = await _client.from('proposals').select()
        .eq('job_id', jobId).order('created_at', ascending: false);
    return _decorate(rows);
  }

  Future<List<Proposal>> _decorate(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];
    final jobIds = rows.map((row) => row['job_id'] as int).toSet().toList();
    final studentIds = rows.map((row) => row['student_id'] as String).toSet().toList();
    final jobs = await _client.from('jobs').select('id,title,budget').inFilter('id', jobIds);
    final profiles = await _client.from('profiles').select('id,full_name').inFilter('id', studentIds);
    final studentProfiles = await _client.from('student_profiles')
        .select('user_id,github_username').inFilter('user_id', studentIds);
    final jobById = {for (final row in jobs) row['id']: row};
    final profileById = {for (final row in profiles) row['id']: row};
    final studentById = {for (final row in studentProfiles) row['user_id']: row};
    return rows.map((row) {
      final username = studentById[row['student_id']]?['github_username'] as String?;
      return Proposal.fromJson({
        ...row,
        'job_title': jobById[row['job_id']]?['title'],
        'job_budget': jobById[row['job_id']]?['budget'],
        'student_profile_id': row['student_id'],
        'student_name': profileById[row['student_id']]?['full_name'],
        'github_url': username == null || username.isEmpty ? null : 'https://github.com/$username',
      });
    }).toList();
  }

  Future<void> submitProposal({
    required int jobId,
    required String coverLetter,
    required String rate,
    required int estimatedTimelineWeeks,
    int? attachedProjectId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to submit a proposal');
    final budget = double.tryParse(rate.replaceAll(RegExp(r'[^\d.]'), ''));
    if (budget == null || budget <= 0) throw FormatException('Enter a valid rate.');
    await _client.from('proposals').insert({
      'job_id': jobId,
      'student_id': userId,
      'pitch_text': coverLetter.trim(),
      'proposed_budget': budget,
      'estimated_timeline_weeks': estimatedTimelineWeeks,
      'attached_project_id': ?attachedProjectId,
    });
  }

  Future<void> updateProposalStatus(int proposalId, String status) async {
    if (status == 'accepted') {
      await _client.rpc('accept_proposal', params: {'proposal_id': proposalId});
    } else if (status == 'rejected') {
      await _client.rpc('reject_proposal', params: {'proposal_id': proposalId});
    } else {
      throw ArgumentError.value(status, 'status');
    }
  }
}
