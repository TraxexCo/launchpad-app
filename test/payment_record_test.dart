import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/models/payment_record.dart';

void main() {
  test('paid and released payments unlock project work', () {
    final paid = PaymentRecord.fromJson({
      'id': 4,
      'contract_id': 8,
      'amount': '12500.00',
      'currency': 'PHP',
      'status': 'paid',
      'reference_number': 'LP-8-TEST',
      'paid_at': '2026-10-11T10:00:00Z',
    });
    expect(paid.isFunded, isTrue);
    expect(paid.displayStatus, 'Project Funded');
    expect(paid.amount, 12500);

    final released = PaymentRecord.fromJson({
      'id': 4,
      'contract_id': 8,
      'amount': 12500,
      'status': 'released',
      'reference_number': 'LP-8-TEST',
    });
    expect(released.isFunded, isTrue);
    expect(released.displayStatus, 'Payment Released');
  });

  test('checkout status remains unpaid but keeps its provider URL', () {
    final payment = PaymentRecord.fromJson({
      'id': 5,
      'contract_id': 9,
      'amount': 5000,
      'status': 'checkout_created',
      'reference_number': 'LP-9-TEST',
      'checkout_url': 'https://checkout.paymongo.com/test',
    });
    expect(payment.isFunded, isFalse);
    expect(payment.canOpenCheckout, isTrue);
    expect(payment.displayStatus, 'Awaiting Payment');
  });
}
