import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../models/payment_record.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_state_view.dart';

class PaymentScreen extends StatefulWidget {
  final int contractId;
  final String projectTitle;
  final double amount;
  final bool studentView;

  const PaymentScreen({
    super.key,
    required this.contractId,
    required this.projectTitle,
    required this.amount,
    required this.studentView,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  PaymentRecord? _payment;
  StreamSubscription<PaymentRecord?>? _subscription;
  bool _loading = true;
  bool _working = false;
  bool _checkoutOpened = false;
  String? _error;
  late String _projectTitle;
  late double _amount;
  late bool _studentView;

  @override
  void initState() {
    super.initState();
    _projectTitle = widget.projectTitle;
    _amount = widget.amount;
    _studentView = widget.studentView;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _subscription = PaymentService().watchContract(widget.contractId).listen((
      payment,
    ) {
      if (mounted && payment != null) setState(() => _payment = payment);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutOpened) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PaymentService().getForContract(widget.contractId),
        PaymentService().getContractSummary(widget.contractId),
      ]);
      final payment = results[0] as PaymentRecord?;
      final contract = results[1] as PaymentContractSummary;
      if (mounted) {
        setState(() {
          _payment = payment;
          _projectTitle = contract.title;
          _amount = contract.amount;
          _studentView = contract.studentView;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  String _message(Object error) {
    final text = error.toString().replaceFirst('Bad state: ', '');
    return text.contains('FunctionsException')
        ? 'The PayMongo service is not deployed or configured yet.'
        : text;
  }

  Future<void> _startCheckout() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final payment = await PaymentService().createCheckout(widget.contractId);
      final rawUrl = payment.checkoutUrl;
      if (rawUrl == null || rawUrl.isEmpty) {
        if (payment.isFunded) {
          if (mounted) setState(() => _payment = payment);
          return;
        }
        throw StateError('PayMongo did not return a checkout link.');
      }
      final opened = await launchUrl(
        Uri.parse(rawUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Could not open PayMongo Checkout.');
      if (mounted) {
        setState(() {
          _payment = payment;
          _checkoutOpened = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _sync() async {
    if (_working || _payment == null) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final payment = await PaymentService().sync(widget.contractId);
      if (mounted) {
        setState(() => _payment = payment);
        if (payment.isFunded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PayMongo test payment confirmed.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    final funded = payment?.isFunded ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: AppColors.businessPrimary.withValues(alpha: .05),
        child: SafeArea(
          child: _loading
              ? const AppLoadingView(
                  label: 'Loading payment channel…',
                  color: AppColors.businessPrimary,
                )
              : Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _paymentInstrument(payment),
                            const SizedBox(height: AppSpacing.lg),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _row('Project', _projectTitle),
                                  const Divider(height: AppSpacing.xl),
                                  _row(
                                    'Contract',
                                    '#${widget.contractId.toString().padLeft(4, '0')}',
                                  ),
                                  const Divider(height: AppSpacing.xl),
                                  _row(
                                    'Amount',
                                    '₱${_amount.toStringAsFixed(2)}',
                                  ),
                                  if (payment != null) ...[
                                    const Divider(height: AppSpacing.xl),
                                    _row('Reference', payment.referenceNumber),
                                    if (payment.paymentMethod != null) ...[
                                      const Divider(height: AppSpacing.xl),
                                      _row(
                                        'Method',
                                        payment.paymentMethod!.toUpperCase(),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: .1),
                                  border: Border.all(
                                    color: AppColors.error.withValues(
                                      alpha: .35,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            if (!_studentView && !funded)
                              AppButton(
                                label: payment?.canOpenCheckout == true
                                    ? 'Reopen PayMongo Checkout'
                                    : 'Pay with PayMongo Test Mode',
                                icon: Icons.open_in_browser_rounded,
                                isLoading: _working,
                                backgroundColor: AppColors.businessPrimary,
                                onPressed: _startCheckout,
                              ),
                            if (payment != null && !funded) ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppButton(
                                label: 'Verify Payment Status',
                                icon: Icons.sync_rounded,
                                outlined: true,
                                isLoading: _working,
                                onPressed: _sync,
                              ),
                            ],
                            if (funded)
                              AppButton(
                                label: 'Return to Project',
                                icon: Icons.arrow_back_rounded,
                                backgroundColor: AppColors.success,
                                onPressed: () => context.pop(true),
                              ),
                            if (_studentView && payment == null)
                              Text(
                                'The business has not opened a PayMongo checkout yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'TEST MODE • No real money is charged. LaunchPad confirms the result directly with the PayMongo API.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                height: 1.5,
                                color: AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Funding',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'PAYMONGO TEST CHANNEL',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: AppColors.businessAccent,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded, color: AppColors.success),
      ],
    ),
  );

  Widget _paymentInstrument(PaymentRecord? payment) {
    final status = payment?.displayStatus ?? 'Not Funded';
    final funded = payment?.isFunded ?? false;
    final color = funded
        ? AppColors.success
        : payment == null
        ? AppColors.warning
        : AppColors.businessAccent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .22), AppColors.surfaceHigh],
        ),
        border: Border.all(color: color.withValues(alpha: .5)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                funded
                    ? Icons.verified_rounded
                    : Icons.account_balance_wallet_outlined,
                color: color,
                size: 34,
              ),
              const Spacer(),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            funded
                ? 'The accepted project is cleared for work.'
                : _studentView
                ? 'Funding must be confirmed before submission.'
                : 'Fund the accepted student proposal securely in test mode.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: .06);
  }

  Widget _row(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 82,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}
