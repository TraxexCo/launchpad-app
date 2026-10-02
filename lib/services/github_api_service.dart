import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubApiService {
  GithubApiService({this.client});

  final http.Client? client;
  static final _cache = <String, _CachedRepos>{};
  static const _lifetime = Duration(minutes: 15);

  Future<List<Map<String, dynamic>>> fetchUserRepositories(
    String username,
  ) async {
    final cleaned = username.trim();
    if (cleaned.isEmpty) return [];
    final cacheKey = cleaned.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _lifetime) {
      return cached.repos;
    }

    final uri = Uri.https('api.github.com', '/users/$cleaned/repos', {
      'sort': 'updated',
      'per_page': '10',
    });
    final response =
        await (client?.get(
              uri,
              headers: {'Accept': 'application/vnd.github+json'},
            ) ??
            http.get(uri, headers: {'Accept': 'application/vnd.github+json'}));
    if (response.statusCode == 404) {
      throw const GithubApiException('No repositories found or user not found');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      if (cached != null) return cached.repos;
      throw const GithubApiException(
        'GitHub API rate limit reached. Please check back shortly.',
      );
    }
    if (response.statusCode != 200) {
      if (cached != null) return cached.repos;
      throw const GithubApiException('Could not load GitHub repositories.');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final repos = data.cast<Map<String, dynamic>>();
    _cache[cacheKey] = _CachedRepos(repos, DateTime.now());
    return repos;
  }
}

class GithubApiException implements Exception {
  final String message;
  const GithubApiException(this.message);

  @override
  String toString() => message;
}

class _CachedRepos {
  final List<Map<String, dynamic>> repos;
  final DateTime fetchedAt;
  const _CachedRepos(this.repos, this.fetchedAt);
}
