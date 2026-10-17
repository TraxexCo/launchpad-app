import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/core/form_validation.dart';

void main() {
  // ── requiredField ─────────────────────────────────────────────────────────
  group('FormValidation.requiredField', () {
    test('returns error for null', () {
      expect(FormValidation.requiredField(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(FormValidation.requiredField(''), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(FormValidation.requiredField('   '), isNotNull);
    });

    test('includes the field name in the error message', () {
      expect(FormValidation.requiredField('', 'Email'), contains('Email'));
    });

    test('returns null for a valid non-empty value', () {
      expect(FormValidation.requiredField('Juan dela Cruz'), isNull);
    });
  });

  // ── email ─────────────────────────────────────────────────────────────────
  group('FormValidation.email', () {
    test('rejects null', () {
      expect(FormValidation.email(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(FormValidation.email(''), isNotNull);
    });

    test('rejects value without @', () {
      expect(FormValidation.email('notanemail'), isNotNull);
    });

    test('rejects value without domain dot', () {
      expect(FormValidation.email('user@nodot'), isNotNull);
    });

    test('accepts a well-formed address', () {
      expect(FormValidation.email('user@example.com'), isNull);
    });

    test('accepts address with subdomain', () {
      expect(FormValidation.email('user@mail.example.co.uk'), isNull);
    });
  });

  // ── password ──────────────────────────────────────────────────────────────
  group('FormValidation.password', () {
    test('rejects null', () {
      expect(FormValidation.password(null), isNotNull);
    });

    test('rejects fewer than 6 characters', () {
      expect(FormValidation.password('12345'), isNotNull);
    });

    test('accepts exactly 6 characters', () {
      expect(FormValidation.password('123456'), isNull);
    });
  });

  // ── strongPassword ────────────────────────────────────────────────────────
  group('FormValidation.strongPassword', () {
    test('rejects fewer than 8 characters', () {
      expect(FormValidation.strongPassword('1234567'), isNotNull);
    });

    test('accepts exactly 8 characters', () {
      expect(FormValidation.strongPassword('secure123'), isNull);
    });
  });

  // ── url ───────────────────────────────────────────────────────────────────
  group('FormValidation.url', () {
    test('rejects null', () {
      expect(FormValidation.url(null), isNotNull);
    });

    test('rejects http-less URL', () {
      expect(FormValidation.url('github.com/user'), isNotNull);
    });

    test('accepts https:// URL', () {
      expect(FormValidation.url('https://github.com/user'), isNull);
    });

    test('accepts http:// URL', () {
      expect(FormValidation.url('http://example.com'), isNull);
    });
  });

  // ── optionalUrl ───────────────────────────────────────────────────────────
  group('FormValidation.optionalUrl', () {
    test('returns null for empty string', () {
      expect(FormValidation.optionalUrl(''), isNull);
    });

    test('returns null for null', () {
      expect(FormValidation.optionalUrl(null), isNull);
    });

    test('rejects invalid URL when non-empty', () {
      expect(FormValidation.optionalUrl('not-a-url'), isNotNull);
    });

    test('accepts valid URL when non-empty', () {
      expect(FormValidation.optionalUrl('https://portfolio.dev'), isNull);
    });
  });

  // ── jobDescription ────────────────────────────────────────────────────────
  group('FormValidation.jobDescription', () {
    test('rejects blank description', () {
      expect(FormValidation.jobDescription('  '), isNotNull);
    });

    test('rejects description shorter than 50 chars', () {
      expect(FormValidation.jobDescription('Short'), isNotNull);
    });

    test('accepts description with exactly 50 chars', () {
      expect(FormValidation.jobDescription('a' * 50), isNull);
    });
  });

  // ── jobBudget ─────────────────────────────────────────────────────────────
  group('FormValidation.jobBudget', () {
    test('rejects null', () {
      expect(FormValidation.jobBudget(null), isNotNull);
    });

    test('rejects zero', () {
      expect(FormValidation.jobBudget('0'), isNotNull);
    });

    test('rejects negative value', () {
      expect(FormValidation.jobBudget('-500'), isNotNull);
    });

    test('rejects non-numeric string', () {
      expect(FormValidation.jobBudget('free'), isNotNull);
    });

    test('accepts positive integer', () {
      expect(FormValidation.jobBudget('8000'), isNull);
    });

    test('accepts comma-formatted number', () {
      expect(FormValidation.jobBudget('25,000'), isNull);
    });
  });

  // ── proposalPitch ─────────────────────────────────────────────────────────
  group('FormValidation.proposalPitch', () {
    test('rejects blank pitch', () {
      expect(FormValidation.proposalPitch('  '), isNotNull);
    });

    test('rejects pitch shorter than 80 chars', () {
      expect(FormValidation.proposalPitch('Too short.'), isNotNull);
    });

    test('accepts pitch with exactly 80 chars', () {
      expect(FormValidation.proposalPitch('a' * 80), isNull);
    });
  });

  // ── proposalRate ──────────────────────────────────────────────────────────
  group('FormValidation.proposalRate', () {
    test('rejects null', () {
      expect(FormValidation.proposalRate(null), isNotNull);
    });

    test('rejects non-numeric value', () {
      expect(FormValidation.proposalRate('twenty thousand'), isNotNull);
    });

    test('accepts numeric rate', () {
      expect(FormValidation.proposalRate('15000'), isNull);
    });
  });

  // ── projectTitle ──────────────────────────────────────────────────────────
  group('FormValidation.projectTitle', () {
    test('rejects blank title', () {
      expect(FormValidation.projectTitle('  '), isNotNull);
    });

    test('accepts non-empty title', () {
      expect(FormValidation.projectTitle('My Flutter App'), isNull);
    });
  });
}
