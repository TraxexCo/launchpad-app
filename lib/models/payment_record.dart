class PaymentRecord {
  final int id;
  final int contractId;
  final double amount;
  final String currency;
  final String status;
  final String referenceNumber;
  final String? checkoutUrl;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? releasedAt;

  const PaymentRecord({
    required this.id,
    required this.contractId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.referenceNumber,
    this.checkoutUrl,
    this.paymentMethod,
    this.paidAt,
    this.releasedAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: (json['id'] as num).toInt(),
    contractId: (json['contract_id'] as num).toInt(),
    amount: double.tryParse(json['amount'].toString()) ?? 0,
    currency: json['currency']?.toString() ?? 'PHP',
    status: json['status']?.toString() ?? 'unpaid',
    referenceNumber: json['reference_number']?.toString() ?? '',
    checkoutUrl: json['checkout_url']?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
    releasedAt: DateTime.tryParse(json['released_at']?.toString() ?? ''),
  );

  bool get isFunded => status == 'paid' || status == 'released';
  bool get isHeld => status == 'paid';
  bool get isReleased => status == 'released';
  bool get canOpenCheckout =>
      status == 'checkout_created' && (checkoutUrl?.isNotEmpty ?? false);

  String get displayStatus => switch (status) {
    'checkout_created' => 'Awaiting Payment',
    'paid' => 'Funds Held',
    'released' => 'Payment Released',
    'failed' => 'Payment Failed',
    'expired' => 'Checkout Expired',
    'refunded' => 'Payment Refunded',
    _ => 'Not Funded',
  };

  String get protectionMessage => switch (status) {
    'paid' =>
      'Payment is confirmed and held until the business approves the completed work.',
    'released' =>
      'The business approved the completed work and released the payment.',
    'refunded' => 'The held payment was marked for refund after review.',
    'checkout_created' =>
      'The payment has not been confirmed. Project work remains locked.',
    _ => 'Project work stays locked until payment is confirmed.',
  };
}
