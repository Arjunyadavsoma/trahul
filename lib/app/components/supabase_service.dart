import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final storage = Supabase.instance.client.storage;

  static Future<String?> uploadProfileImage(String userId, String fileName, Uint8List bytes) async {
    final path = 'users/$userId/$fileName';
    await storage.from('profile-pictures').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.from('profile-pictures').getPublicUrl(path);
    return publicUrl;
  }
}
