import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hardware-backed storage for authentication and private offline data.
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}

/// Persists Supabase sessions in Android Keystore/iOS Keychain storage.
class SecureSupabaseLocalStorage extends LocalStorage {
  const SecureSupabaseLocalStorage();

  static const _key = 'launchpad.supabase.session.v1';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() =>
      SecureStorageService.instance.containsKey(key: _key);

  @override
  Future<String?> accessToken() =>
      SecureStorageService.instance.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      SecureStorageService.instance.write(
        key: _key,
        value: persistSessionString,
      );

  @override
  Future<void> removePersistedSession() =>
      SecureStorageService.instance.delete(key: _key);
}

/// Keeps the mobile PKCE verifier out of SharedPreferences.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage();

  String _key(String key) => 'launchpad.pkce.$key';

  @override
  Future<String?> getItem({required String key}) =>
      SecureStorageService.instance.read(key: _key(key));

  @override
  Future<void> removeItem({required String key}) =>
      SecureStorageService.instance.delete(key: _key(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      SecureStorageService.instance.write(key: _key(key), value: value);
}
