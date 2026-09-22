import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSession {
  final String id;
  final String role;
  final String name;
  final String email;

  const UserSession({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _subscription = _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient _client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _subscription;

  Future<UserSession> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(), password: password,
    );
    if (response.session == null) {
      throw const AuthException('Check your email to confirm your account.');
    }
    final session = await getCurrentUser();
    if (session == null) throw StateError('Profile was not created. Check database logs.');
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
      email: email.trim(), password: password,
      data: {
        'role': role,
        'full_name': name.trim(),
        if (role == 'student') ...{
          'bio': (extraFields['bio'] ?? '').toString().trim(),
          'github_username': githubUsername,
          'skills': extraFields['skills'] ?? <String>[],
        },
        if (role == 'business') ...{
          'business_name': (extraFields['business_name'] ?? '').toString().trim(),
          'address': (extraFields['location'] ?? '').toString().trim(),
        },
      },
    );
    if (response.user == null) throw StateError('Registration did not create an account.');
    notifyListeners();
    return response.session == null;
  }

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  Future<void> logout() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<String?> getToken() async => _client.auth.currentSession?.accessToken;

  Future<UserSession?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null || _client.auth.currentSession == null) return null;
    final row = await _client.from('profiles')
        .select('id, role, full_name').eq('id', user.id).single();
    return UserSession(
      id: row['id'] as String,
      role: row['role'] as String,
      name: row['full_name'] as String,
      email: user.email ?? '',
    );
  }

  Future<bool> get isLoggedIn async => _client.auth.currentSession != null;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
