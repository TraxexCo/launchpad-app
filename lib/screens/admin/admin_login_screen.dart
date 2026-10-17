import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/form_validation.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AdminLoginScreen extends StatefulWidget {
  final bool unauthorized;

  const AdminLoginScreen({super.key, this.unauthorized = false});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.unauthorized) {
      _error = 'This account is not approved for LaunchPad administration.';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().login(_email.text, _password.text);
      if (!await AdminService().isAdmin()) {
        await AuthService().logout();
        throw const AuthException(
          'This account is not approved for LaunchPad administration.',
        );
      }
      if (mounted) context.go('/admin');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _clean(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _clean(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'Email or password is incorrect.';
      }
      if (message.contains('email not confirmed')) {
        return 'Confirm your email before signing in.';
      }
      return error.message;
    }
    return 'We could not sign you in. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('The admin console is available on web only.'),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AdminLoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 48 : 22,
                        vertical: 28,
                      ),
                      child: wide
                          ? Row(
                              children: [
                                const Expanded(child: _AdminIntro()),
                                const SizedBox(width: 72),
                                SizedBox(width: 420, child: _loginPanel()),
                              ],
                            )
                          : ListView(
                              children: [
                                const _AdminIntro(compact: true),
                                const SizedBox(height: 34),
                                _loginPanel(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPanel() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xF2181A1F),
      border: Border.all(color: AppColors.borderHigh),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 40,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow(label: 'RESTRICTED ACCESS'),
            const SizedBox(height: 16),
            Text(
              'Administrator sign in',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use an account approved in the LaunchPad administrator allowlist.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: .10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: .55),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AppTextField(
              label: 'Admin email',
              hint: 'name@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
              validator: FormValidation.email,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              validator: FormValidation.password,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/recover-password'),
                child: const Text('Recover access'),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Open admin console',
              icon: Icons.arrow_forward_rounded,
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 17,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Access is checked again by Supabase on every action.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminIntro extends StatelessWidget {
  final bool compact;

  const _AdminIntro({this.compact = false});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderHigh),
            ),
            child: Image.asset(
              'assets/branding/launchpad_mark.png',
              semanticLabel: 'LaunchPad logo',
            ),
          ),
          const SizedBox(width: 13),
          Text(
            'LAUNCHPAD',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      SizedBox(height: compact ? 32 : 72),
      const _Eyebrow(label: 'OPERATIONS / MANILA'),
      const SizedBox(height: 18),
      Text(
        'Keep the marketplace\nready for good work.',
        style: GoogleFonts.manrope(
          fontSize: compact ? 38 : 58,
          height: 1.02,
          letterSpacing: -2,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 22),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: const Text(
          'Review identity documents, resolve reports and disputes, protect accounts, and monitor classroom payments from one controlled workspace.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.65,
            fontSize: 16,
          ),
        ),
      ),
      if (!compact) ...[
        const SizedBox(height: 48),
        const Wrap(
          spacing: 24,
          runSpacing: 18,
          children: [
            _Capability(number: '01', label: 'Review'),
            _Capability(number: '02', label: 'Resolve'),
            _Capability(number: '03', label: 'Protect'),
          ],
        ),
      ],
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  final String label;

  const _Eyebrow({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.robotoMono(
      color: AppColors.studentPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      letterSpacing: 1.3,
    ),
  );
}

class _Capability extends StatelessWidget {
  final String number;
  final String label;

  const _Capability({required this.number, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.robotoMono(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.borderHigh),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AdminLoginBackdrop extends StatelessWidget {
  const _AdminLoginBackdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GridPainter(),
    child: const ColoredBox(color: Colors.transparent),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final grid = Paint()
      ..color = AppColors.border.withValues(alpha: .28)
      ..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()
      ..moveTo(0, size.height * .78)
      ..lineTo(size.width * .24, size.height * .78)
      ..lineTo(size.width * .24, size.height * .64)
      ..lineTo(size.width * .53, size.height * .64)
      ..lineTo(size.width * .53, size.height * .48);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.studentPrimary.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
