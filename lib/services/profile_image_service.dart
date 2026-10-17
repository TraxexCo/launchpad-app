import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileImageService {
  ProfileImageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const bucket = 'profile-images';
  static const maxBytes = 5 * 1024 * 1024;
  final SupabaseClient _client;

  String publicUrl(String? storagePath) {
    if (storagePath == null || storagePath.trim().isEmpty) return '';
    return _client.storage.from(bucket).getPublicUrl(storagePath);
  }

  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before uploading a photo.');
    if (bytes.isEmpty) throw ArgumentError('The selected image is empty.');
    if (bytes.length > maxBytes) {
      throw ArgumentError('Choose an image smaller than 5 MB.');
    }

    final extension = _extension(fileName);
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError('Use a JPG, PNG, or WebP image.'),
    };
    final previous = await _currentPath(user.id);
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '31536000',
          ),
        );
    try {
      await _client
          .from('profiles')
          .update({'avatar_path': path})
          .eq('id', user.id);
    } catch (_) {
      await _client.storage.from(bucket).remove([path]);
      rethrow;
    }
    if (previous != null && previous != path) {
      try {
        await _client.storage.from(bucket).remove([previous]);
      } catch (_) {
        // The new photo is already active; stale-file cleanup can be retried later.
      }
    }
    return path;
  }

  Future<void> remove() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before removing a photo.');
    final previous = await _currentPath(user.id);
    await _client
        .from('profiles')
        .update({'avatar_path': null})
        .eq('id', user.id);
    if (previous != null) {
      await _client.storage.from(bucket).remove([previous]);
    }
  }

  Future<String?> _currentPath(String userId) async {
    final row = await _client
        .from('profiles')
        .select('avatar_path')
        .eq('id', userId)
        .single();
    return row['avatar_path'] as String?;
  }

  String _extension(String fileName) {
    final clean = fileName.toLowerCase().trim();
    final dot = clean.lastIndexOf('.');
    return dot < 0 ? '' : clean.substring(dot + 1);
  }
}
