// 📄 retry_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RetryService {
  final String conversationId;
  final storage = Supabase.instance.client.storage;

  RetryService(this.conversationId);

  Future<void> retrySend({
    required String docId,
    required String fileName,
    required Uint8List bytes,
    required String type,
  }) async {
    final timestamp = Timestamp.now();

    try {
      await storage.from('chat-files').uploadBinary(
        'attachments/$fileName',
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final fileUrl = storage
          .from('chat-files')
          .getPublicUrl('attachments/$fileName');

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(docId)
          .update({
        'fileUrl': fileUrl,
        'status': 'sent',
        'timestamp': timestamp,
      });
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(docId)
          .update({
        'status': 'failed',
      });
      rethrow;
    }
  }
}
