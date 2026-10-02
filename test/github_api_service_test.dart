import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:launchpad_app/services/github_api_service.dart';

void main() {
  test(
    'unknown GitHub handle produces the required friendly message',
    () async {
      final service = GithubApiService(
        client: MockClient(
          (_) async => http.Response('{"message":"Not Found"}', 404),
        ),
      );
      await expectLater(
        service.fetchUserRepositories('unknown-audit-404'),
        throwsA(
          isA<GithubApiException>().having(
            (error) => error.message,
            'message',
            'No repositories found or user not found',
          ),
        ),
      );
    },
  );

  test('GitHub rate limit produces the required message', () async {
    final service = GithubApiService(
      client: MockClient(
        (_) async =>
            http.Response('{"message":"API rate limit exceeded"}', 403),
      ),
    );
    await expectLater(
      service.fetchUserRepositories('audit-limit-403'),
      throwsA(
        isA<GithubApiException>().having(
          (error) => error.message,
          'message',
          'GitHub API rate limit reached. Please check back shortly.',
        ),
      ),
    );
  });
}
