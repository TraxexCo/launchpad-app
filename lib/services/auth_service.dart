import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSession {
  final String id;
  final String role;
  final String name;
  final String email;
  final String? avatarPath;

  const UserSession({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarPath,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _subscription = _client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        isRecoveringPassword = true;
      }
      notifyListeners();
    });
    if (!kIsWeb) {
      _linkSubscription = _appLinks.uriLinkStream.listen(_handleIncomingLink);
    }
  }

  final SupabaseClient _client = Supabase.instance.client;
  final AppLinks _appLinks = AppLinks();
  late final StreamSubscription<AuthState> _subscription;
  StreamSubscription<Uri>? _linkSubscription;
  bool isRecoveringPassword = false;
  int? _pendingPaymentContractId;
  static const mobileAuthRedirect = 'launchpad://auth-callback/';
  String get authRedirect => kIsWeb ? Uri.base.origin : mobileAuthRedirect;

  Future<void> restoreInitialRecoveryState() async {
    if (kIsWeb) return;
    final uri = await _appLinks.getInitialLink().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    if (uri == null) return;
    _handleIncomingLink(uri);
  }

  void _handleIncomingLink(Uri uri) {
    final fragment = Uri.splitQueryString(uri.fragment);
    if (uri.queryParameters['type'] == 'recovery' ||
        fragment['type'] == 'recovery') {
      isRecoveringPassword = true;
    }
    if (uri.scheme == 'launchpad' && uri.host == 'payment-return') {
      final contractId = int.tryParse(uri.queryParameters['contract_id'] ?? '');
      if (contractId != null && contractId > 0) {
        _pendingPaymentContractId = contractId;
      }
    }
    notifyListeners();
  }

  String? takePendingPaymentPath() {
    final contractId = _pendingPaymentContractId;
    if (contractId == null) return null;
    _pendingPaymentContractId = null;
    return '/payment/$contractId';
  }

  Future<UserSession> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const AuthException('Check your email to confirm your account.');
    }
    final session = await getCurrentUser();
    if (session == null) {
      throw StateError('Profile was not created. Check database logs.');
    }
    notifyListeners();
    return session;
  }

  /// Returns true when email confirmation is required before sign-in.
  Future<bool> register({
    required String role,
    required String name,
    required String email,
    required String password,
    Map<String, dynamic> extraFields = const {},
  }) async {
    if (role != 'student' && role != 'business') {
      throw ArgumentError.value(role, 'role');
    }
    final githubInput = (extraFields['github_url'] ?? '').toString().trim();
    final githubUsername = githubInput.startsWith('https://github.com/')
        ? Uri.parse(githubInput).pathSegments.firstOrNull ?? ''
        : githubInput;
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirect,
      data: {
        'role': role,
        'full_name': name.trim(),
        if (role == 'student') ...{
          'school': (extraFields['school'] ?? '').toString().trim(),
          'course': (extraFields['course'] ?? '').toString().trim(),
          'bio': (extraFields['bio'] ?? '').toString().trim(),
          'github_username': githubUsername,
          'skills': extraFields['skills'] ?? <String>[],
        },
        if (role == 'business') ...{
          'business_name': (extraFields['business_name'] ?? '')
              .toString()
              .trim(),
          'address': (extraFields['location'] ?? '').toString().trim(),
        },
      },
    );
    if (response.user == null) {
      throw StateError('Registration did not create an account.');
    }
    notifyListeners();
    return response.session == null;
  }

  Future<void> resetPassword(String email) => _client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: authRedirect);

  Future<void> updateRecoveredPassword(String password) async {
    if (!isRecoveringPassword) {
      throw StateError('Open a valid password reset link first.');
    }
    await _client.auth.updateUser(UserAttributes(password: password));
    isRecoveringPassword = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    isRecoveringPassword = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      throw StateError(
        data is Map
            ? data['error']?.toString() ?? 'Account deletion failed.'
            : 'Account deletion failed.',
      );
    }
    await _client.auth.signOut(scope: SignOutScope.local);
    notifyListeners();
  }

  Future<String?> getToken() async => _client.auth.currentSession?.accessToken;

  Future<UserSession?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null || _client.auth.currentSession == null) return null;
    final row = await _client
        .from('profiles')
        .select(
          'id, role, full_name, avatar_path, suspended_at, suspension_reason',
        )
        .eq('id', user.id)
        .single();
    if (row['suspended_at'] != null) {
      await _client.auth.signOut();
      throw AuthException(
        row['suspension_reason']?.toString() ?? 'This account is suspended.',
      );
    }
    return UserSession(
      id: row['id'] as String,
      role: row['role'] as String,
      name: row['full_name'] as String,
      email: user.email ?? '',
      avatarPath: row['avatar_path'] as String?,
    );
  }

  Future<bool> get isLoggedIn async => _client.auth.currentSession != null;

  @override
  void dispose() {
    _subscription.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
