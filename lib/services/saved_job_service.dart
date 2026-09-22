import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_post.dart';
import 'job_service.dart';

class SavedJobService {
  static final SavedJobService _instance = SavedJobService._internal();
  factory SavedJobService() => _instance;
  SavedJobService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> isJobSaved(int jobId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final res = await _client
          .from('saved_jobs')
          .select('job_id')
          .eq('student_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleSave(int jobId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to save jobs.');

    final currentlySaved = await isJobSaved(jobId);
    if (currentlySaved) {
      await _client
          .from('saved_jobs')
          .delete()
          .eq('student_id', userId)
          .eq('job_id', jobId);
      return false;
    } else {
      await _client.from('saved_jobs').insert({
        'student_id': userId,
        'job_id': jobId,
      });
      return true;
    }
  }

  Future<List<JobPost>> getSavedJobs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('saved_jobs')
        .select('job_id')
        .eq('student_id', userId)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];
    final jobIds = rows.map((r) => r['job_id'] as int).toList();
    final allJobs = await JobService().getAllJobs();
    return allJobs.where((j) => jobIds.contains(int.tryParse(j.id))).toList();
  }
}
