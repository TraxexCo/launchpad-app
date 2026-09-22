import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubApiService {
  static final _cache = <String, _CachedRepos>{};
  static const _lifetime = Duration(minutes: 15);

  Future<List<Map<String, dynamic>>> fetchUserRepositories(String username) async {
    final cleaned = username.trim();
    if (cleaned.isEmpty) return [];
    final cacheKey = cleaned.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _lifetime) {
      return cached.repos;
    }

    final uri = Uri.https('api.github.com', '/users/$cleaned/repos', {
      'sort': 'updated', 'per_page': '10',
    });
    final response = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'});
    if (response.statusCode == 404) throw StateError('GitHub account not found.');
    if (response.statusCode == 403 || response.statusCode == 429) {
      if (cached != null) return cached.repos;
      throw StateError('GitHub is temporarily limiting requests. Try again later.');
    }
    if (response.statusCode != 200) {
      if (cached != null) return cached.repos;
      throw StateError('Could not load GitHub repositories.');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final repos = data.cast<Map<String, dynamic>>();
    _cache[cacheKey] = _CachedRepos(repos, DateTime.now());
    return repos;
  }
}

class _CachedRepos {
  final List<Map<String, dynamic>> repos;
  final DateTime fetchedAt;
  const _CachedRepos(this.repos, this.fetchedAt);
}
