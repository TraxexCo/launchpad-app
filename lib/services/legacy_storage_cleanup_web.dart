import 'package:web/web.dart' as web;

Future<void> clearLegacyPlaintextStorageImpl(String supabaseUrl) async {
  final projectRef = Uri.parse(supabaseUrl).host.split('.').first;
  web.window.localStorage.removeItem('sb-$projectRef-auth-token');
}
