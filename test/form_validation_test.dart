import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/core/form_validation.dart';

void main() {
  test('registration password boundary follows the specification', () {
    expect(FormValidation.password('12345'),
        'Password must be at least 6 characters');
    expect(FormValidation.password('123456'), isNull);
  });

  test('job title/description and budget reject missing and nonpositive data', () {
    expect(FormValidation.jobDescription('  '), 'Description is required');
    expect(FormValidation.jobDescription('a' * 50), isNull);
    expect(FormValidation.jobBudget('0'), 'Budget must be greater than zero');
    expect(FormValidation.jobBudget('-500'), 'Budget must be greater than zero');
    expect(FormValidation.jobBudget('25,000'), isNull);
  });

  test('proposal pitch and rate give the required errors', () {
    expect(FormValidation.proposalPitch('  '),
        'Please provide a pitch or cover letter explaining your approach');
    expect(FormValidation.proposalRate('twenty thousand'),
        'Enter a valid numeric amount');
  });

  test('portfolio title gives the required error', () {
    expect(FormValidation.projectTitle('  '), 'Please enter a title');
  });
}
