import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/core/form_validation.dart';

/// Auth form validator tests – login and register screen fields.
void main() {
  group('Login screen validators', () {
    test('email accepts properly formatted address', () {
      expect(FormValidation.email('user@test.com'), isNull);
    });

    test('email rejects missing @', () {
      expect(FormValidation.email('usertest.com'), isNotNull);
    });

    test('email rejects embedded whitespace', () {
      expect(FormValidation.email('user name@test.com'), isNotNull);
      expect(FormValidation.email('user@test .com'), isNotNull);
    });

    test('email accepts a normal address', () {
      expect(FormValidation.email('student@launchpad.ph'), isNull);
    });

    test('password rejects value shorter than 6 chars', () {
      expect(FormValidation.password('12345'), isNotNull);
    });

    test('password accepts 6+ char value', () {
      expect(FormValidation.password('correct'), isNull);
    });
  });

  group('Register screen – Account step validators', () {
    test('required name field rejects blank', () {
      expect(FormValidation.requiredField('', 'Name'), isNotNull);
    });

    test('required name field accepts non-empty', () {
      expect(FormValidation.requiredField('Maria', 'Name'), isNull);
    });

    test('strongPassword rejects < 8 chars', () {
      expect(FormValidation.strongPassword('short'), isNotNull);
    });

    test('strongPassword accepts 8+ chars', () {
      expect(FormValidation.strongPassword('launchpad8'), isNull);
    });

    test('strongPassword requires both letters and numbers', () {
      expect(FormValidation.strongPassword('onlyletters'), isNotNull);
      expect(FormValidation.strongPassword('12345678'), isNotNull);
    });
  });

  group('Register screen – Profile step validators', () {
    test('School required field rejects blank', () {
      expect(FormValidation.requiredField('', 'School'), isNotNull);
    });

    test('Course required field rejects whitespace', () {
      expect(FormValidation.requiredField('   ', 'Course'), isNotNull);
    });

    test('Bio required field accepts valid text', () {
      expect(FormValidation.requiredField('Flutter dev', 'Bio'), isNull);
    });

    test('optional GitHub URL passes when empty', () {
      expect(FormValidation.optionalUrl(''), isNull);
    });

    test('optional GitHub URL rejects invalid URL', () {
      expect(FormValidation.optionalUrl('not-a-url'), isNotNull);
    });

    test('optional GitHub URL accepts https URL', () {
      expect(FormValidation.optionalUrl('https://github.com/user'), isNull);
    });
  });
}
