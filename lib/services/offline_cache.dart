import 'dart:convert';

import 'offline_cache_memory.dart'
    if (dart.library.io) 'offline_cache_sqlite.dart'
    as platform;

/// Small versioned cache for non-sensitive read models used offline.
class OfflineCache {
  OfflineCache._();

  static Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> values,
  ) => platform.writeCache(key, jsonEncode(values));

  static Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final value = await platform.readCache(key);
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      await platform.deleteCache(key);
      return [];
    }
  }
}
