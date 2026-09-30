import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/models/proposal.dart';

void main() {
  test('proposal keeps the decorated business name', () {
    final proposal = Proposal.fromJson({
      'id': 7,
      'job_id': 9,
      'job_title': 'Ordering app',
      'business_name': 'Sample Café',
      'pitch_text': 'I can deliver this project.',
      'proposed_budget': 12000,
      'estimated_timeline_weeks': 4,
      'status': 'pending',
      'created_at': '2026-10-01T00:00:00Z',
    });

    expect(proposal.businessName, 'Sample Café');
    expect(proposal.copyWith(jobTitle: 'Updated title').businessName, 'Sample Café');
  });
}
