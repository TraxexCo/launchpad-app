import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_record.dart';

class PaymentContractSummary {
  final String title;
  final double amount;
  final bool studentView;

  const PaymentContractSummary({
    required this.title,
    required this.amount,
    required this.studentView,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<PaymentRecord?> getForContract(int contractId) async {
    final row = await _client
        .from('payments')
        .select()
        .eq('contract_id', contractId)
        .maybeSingle();
    return row == null ? null : PaymentRecord.fromJson(row);
  }

  Future<PaymentContractSummary> getContractSummary(int contractId) async {
    final row = await _client
        .from('contracts')
        .select('agreed_budget,student_id,jobs(title)')
        .eq('id', contractId)
        .single();
    final job = row['jobs'];
    final title = job is Map ? job['title']?.toString() : null;
    return PaymentContractSummary(
      title: title ?? 'Project Contract',
      amount: double.tryParse(row['agreed_budget'].toString()) ?? 0,
      studentView: row['student_id'] == _client.auth.currentUser?.id,
    );
  }

  Stream<PaymentRecord?> watchContract(int contractId) => _client
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('contract_id', contractId)
      .map((rows) => rows.isEmpty ? null : PaymentRecord.fromJson(rows.first));

  Future<PaymentRecord> createCheckout(int contractId) async {
    final response = await _client.functions.invoke(
      'create-paymongo-checkout',
      body: {'contract_id': contractId},
    );
    final data = _asMap(response.data);
    if (data['error'] != null) throw StateError(data['error'].toString());
    final payment = _asMap(data['payment']);
    if (data['checkout_url'] != null) {
      payment['checkout_url'] = data['checkout_url'];
    }
    return PaymentRecord.fromJson(payment);
  }

  Future<PaymentRecord> sync(int contractId) async {
    final response = await _client.functions.invoke(
      'sync-paymongo-payment',
      body: {'contract_id': contractId},
    );
    final data = _asMap(response.data);
    if (data['error'] != null) throw StateError(data['error'].toString());
    return PaymentRecord.fromJson(_asMap(data['payment']));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException(
      'The payment service returned an invalid response.',
    );
  }
}
