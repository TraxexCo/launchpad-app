import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/core/constants.dart';

void main() {
  test('shared skill catalog is complete and contains no duplicates', () {
    expect(kSkillOptions, hasLength(28));
    expect(kSkillOptions.toSet(), hasLength(kSkillOptions.length));
    expect(
      kSkillOptions,
      containsAll(<String>[
        'Dart',
        'FastAPI',
        'PostgreSQL',
        'Supabase',
        'UI/UX',
        'REST API',
        'GraphQL',
        'Android',
        'iOS',
        'React Native',
        'Docker',
        'Git',
        'AWS',
      ]),
    );
  });
}
