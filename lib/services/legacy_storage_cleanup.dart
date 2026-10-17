import 'legacy_storage_cleanup_native.dart'
    if (dart.library.js_interop) 'legacy_storage_cleanup_web.dart';

Future<void> clearLegacyPlaintextStorage(String supabaseUrl) =>
    clearLegacyPlaintextStorageImpl(supabaseUrl);
