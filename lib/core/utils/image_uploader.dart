import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

Future<String?> uploadImageToSupabase({
  Uint8List? bytes,
  File? file,
  required String folder,
  required String userId,
}) async {
  final storage = Supabase.instance.client.storage.from('user-files');
  final fileName = '$folder/$userId-${_uuid.v4()}.jpg';

  try {
    if (bytes != null) {
      await storage.uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
    } else if (file != null) {
      await storage.upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    } else {
      return null;
    }

    final url = storage.getPublicUrl(fileName);
    return url;
  } catch (e) {
    throw 'Failed to upload image: $e';
  }
}
