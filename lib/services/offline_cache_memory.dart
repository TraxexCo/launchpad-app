final _cache = <String, String>{};

Future<void> writeCache(String key, String value) async => _cache[key] = value;
Future<String?> readCache(String key) async => _cache[key];
Future<void> deleteCache(String key) async => _cache.remove(key);
