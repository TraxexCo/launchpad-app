import 'package:shared_preferences/shared_preferences.dart';

Future<void> clearLegacyPlaintextStorageImpl(String supabaseUrl) async {
  final preferences = await SharedPreferences.getInstance();
  final projectRef = Uri.parse(supabaseUrl).host.split('.').first;
  final keys = preferences.getKeys().where(
    (key) =>
        key == 'sb-$projectRef-auth-token' || key.startsWith('chat_pending_'),
  );
  for (final key in keys.toList()) {
    await preferences.remove(key);
  }
}
