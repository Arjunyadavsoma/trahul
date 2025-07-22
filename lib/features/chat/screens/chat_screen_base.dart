// 📁 chat_screen_base.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final String conversationId;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  ChatService(this.conversationId);

  Future<void> sendText(String text, TextEditingController controller) async {
    if (text.trim().isEmpty) return;
    final timestamp = Timestamp.now();

    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'text': text,
      'senderId': userId,
      'timestamp': timestamp,
      'readBy': [userId],
      'messageType': 'text',
      'status': 'sent',
    });

    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
      'lastMessage': {'text': text, 'senderId': userId, 'timestamp': timestamp},
      'updatedAt': timestamp,
    });

    controller.clear();
  }

  Future<void> uploadFileToSupabase({
    required Uint8List bytes,
    required String fileName,
    required String type,
    required String messageId,
  }) async {
    final timestamp = Timestamp.now();
    final storage = Supabase.instance.client.storage;

    try {
      await storage.from('chat-files').uploadBinary(
        'attachments/$fileName',
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final fileUrl = storage.from('chat-files').getPublicUrl('attachments/$fileName');

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'fileUrl': fileUrl, 'status': 'sent', 'timestamp': timestamp});
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'failed'});
    }
  }

  Future<String> createUploadMessage(String type, String fileName) async {
    final timestamp = Timestamp.now();
    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'text': '',
      'senderId': userId,
      'timestamp': timestamp,
      'readBy': [userId],
      'messageType': type,
      'status': 'uploading',
      'fileName': fileName,
    });

    return messageRef.id;
  }
}
