import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final List<String> readBy;
  final String messageType;
  final String? fileUrl;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.readBy,
    required this.messageType,
    this.fileUrl,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      text: data['text'] ?? '',
      senderId: data['senderId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      messageType: data['messageType'],
      fileUrl: data['fileUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'senderId': senderId,
        'timestamp': timestamp,
        'readBy': readBy,
        'messageType': messageType,
        'fileUrl': fileUrl ?? '',
      };
}
