import 'dart:io';

import 'package:sqflite/sqflite.dart';

Future<Database>? _database;

Future<Database> _open() => _database ??= () async {
  final root = await getDatabasesPath();
  return openDatabase(
    '$root${Platform.pathSeparator}launchpad_cache.db',
    version: 1,
    onCreate: (db, _) => db.execute('''
      create table cache_entries (
        cache_key text primary key,
        payload text not null,
        updated_at integer not null
      )
    '''),
  );
}();

Future<void> writeCache(String key, String value) async {
  final db = await _open();
  await db.insert('cache_entries', {
    'cache_key': key,
    'payload': value,
    'updated_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<String?> readCache(String key) async {
  final db = await _open();
  final rows = await db.query(
    'cache_entries',
    columns: ['payload'],
    where: 'cache_key = ?',
    whereArgs: [key],
    limit: 1,
  );
  return rows.isEmpty ? null : rows.first['payload'] as String?;
}

Future<void> deleteCache(String key) async {
  final db = await _open();
  await db.delete('cache_entries', where: 'cache_key = ?', whereArgs: [key]);
}
