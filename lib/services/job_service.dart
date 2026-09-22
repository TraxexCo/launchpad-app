import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job_post.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<JobPost>> getAllJobs() async {
    final rows = await _client.from('jobs').select().order('created_at', ascending: false);
    return _decorate(rows);
  }

  Future<JobPost> getJobById(int id) async {
    final rows = await _client.from('jobs').select().eq('id', id);
    final jobs = await _decorate(rows);
    if (jobs.isEmpty) throw StateError('Job not found');
    return jobs.first;
  }

  Future<List<JobPost>> getJobsByBusiness(String businessId) async {
    final rows = await _client.from('jobs').select()
        .eq('business_id', businessId).order('created_at', ascending: false);
    return _decorate(rows);
  }

  Future<List<JobPost>> _decorate(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((row) => row['id'] as int).toList();
    final owners = rows.map((row) => row['business_id'] as String).toSet().toList();
    final businesses = await _client.from('business_profiles')
        .select('user_id,business_name,verification_status').inFilter('user_id', owners);
    final businessById = {for (final row in businesses) row['user_id']: row};
    final links = await _client.from('job_skills').select('job_id,skills(name)')
        .inFilter('job_id', ids);
    final skillNames = <int, List<String>>{};
    for (final link in links) {
      final name = (link['skills'] as Map<String, dynamic>?)?['name'] as String?;
      if (name != null) (skillNames[link['job_id'] as int] ??= []).add(name);
    }
    return rows.map((row) {
      final business = businessById[row['business_id']];
      return JobPost.fromJson({
        ...row,
        'business_profile_id': row['business_id'],
        'business_name': business?['business_name'],
        'verification_status': business?['verification_status'],
        'skills': skillNames[row['id']] ?? <String>[],
      });
    }).toList();
  }

  Future<int> createJob({
    required String title,
    required String description,
    required String budget,
    required String category,
    required String urgency,
    required String timeline,
    required String location,
    required List<String> skills,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to post a job');
    final amount = _parseBudget(budget);
    final row = await _client.from('jobs').insert({
      'business_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'budget': amount,
      'category': category,
      'urgency': urgency,
      'timeline': timeline.trim(),
      'location': location.trim(),
    }).select('id').single();
    final id = row['id'] as int;
    try {
      await _replaceSkills(id, skills);
    } catch (_) {
      await _client.from('jobs').delete().eq('id', id);
      rethrow;
    }
    return id;
  }

  Future<void> updateJob(int id, {
    String? title,
    String? description,
    String? budget,
    String? category,
    String? urgency,
    String? timeline,
    String? location,
    List<String>? skills,
  }) async {
    final changes = <String, dynamic>{
      'title': ?title?.trim(),
      'description': ?description?.trim(),
      if (budget != null) 'budget': _parseBudget(budget),
      'category': ?category,
      'urgency': ?urgency,
      if (timeline != null) 'timeline': timeline.trim(),
      if (location != null) 'location': location.trim(),
    };
    if (changes.isNotEmpty) await _client.from('jobs').update(changes).eq('id', id);
    if (skills != null) await _replaceSkills(id, skills);
  }

  Future<void> _replaceSkills(int jobId, List<String> names) async {
    if (names.isEmpty) {
      await _client.from('job_skills').delete().eq('job_id', jobId);
      return;
    }
    final skills = await _client.from('skills').select('id,name').inFilter('name', names);
    if (skills.length != names.toSet().length) {
      throw StateError('One or more selected skills are unavailable.');
    }
    await _client.from('job_skills').delete().eq('job_id', jobId);
    if (skills.isNotEmpty) {
      await _client.from('job_skills').insert([
        for (final skill in skills) {'job_id': jobId, 'skill_id': skill['id']},
      ]);
    }
  }

  Future<void> deleteJob(int id) async {
    await _client.from('jobs').delete().eq('id', id);
  }

  double _parseBudget(String value) {
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null || amount <= 0) throw FormatException('Enter a valid budget.');
    return amount;
  }
}
