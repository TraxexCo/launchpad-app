import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrashReportingService {
  static Future<void> record(Object error, StackTrace stack) async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      await Supabase.instance.client.rpc(
        'record_app_error',
        params: {
          'error_message': error.toString(),
          'error_stack': stack.toString(),
          'client_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        },
      );
    } catch (_) {
      // Error reporting must never cause a second application failure.
    }
  }
}
