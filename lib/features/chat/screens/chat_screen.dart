import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_webapp/features/chat/screens/retry_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen_base.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  late final ChatService chatService;
  late final RetryService retryService;

  String userName = "Chat";
  String? receiverId;

  @override
  void initState() {
    super.initState();
    chatService = ChatService(widget.conversationId);
    retryService = RetryService(widget.conversationId);
    _fetchReceiverUserName();
  }

  Future<void> _fetchReceiverUserName() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final convoDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (convoDoc.exists) {
      final data = convoDoc.data();
      final List participants = data?['participants'] ?? [];

      receiverId = participants.firstWhere((id) => id != currentUserId, orElse: () => null);

      if (receiverId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['username'] ?? 'Chat';
          });
        }
      }
    }
  }

  Future<void> sendAttachment(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'image' ? FileType.image : FileType.any,
      withData: true,
    );

    if (result == null || result.files.first.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    final file = result.files.first;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final messageId = await chatService.createUploadMessage(type, file.name);

    try {
      await chatService.uploadFileToSupabase(
        bytes: Uint8List.fromList(file.bytes!),
        fileName: fileName,
        type: type,
        messageId: messageId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == userId;
                    final msgType = data['messageType'] ?? 'text';
                    final fileUrl = data['fileUrl'] ?? '';
                    final fileName = data['fileName'] ?? '';
                    final status = data['status'] ?? 'sent';
                    final senderName = data['senderName'] ?? 'Unknown';
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    final formattedTime = DateFormat('hh:mm a').format(timestamp);

                    Widget content;
                    if (msgType == 'image' && fileUrl.isNotEmpty) {
                      content = Image.network(fileUrl, width: 200);
                    } else if (msgType == 'file') {
                      content = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (fileUrl.isNotEmpty)
                            TextButton(
                              onPressed: () => launchUrl(Uri.parse(fileUrl)),
                              child: const Text("Open File"),
                            ),
                        ],
                      );
                    } else {
                      content = Text(data['text'] ?? '');
                    }

                    Widget statusIcon = const SizedBox.shrink();
                    if (isMe) {
                      if (status == 'sent') {
                        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.grey);
                      } else if (status == 'uploading') {
                        statusIcon = const SizedBox(
                            height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (status == 'failed') {
                        statusIcon = IconButton(
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                          onPressed: () async {
                            try {
                              final result = await FilePicker.platform.pickFiles(withData: true);
                              if (result != null && result.files.single.bytes != null) {
                                final fileBytes = Uint8List.fromList(result.files.single.bytes!);
                                final fileName = result.files.single.name;

                                await retryService.retrySend(
                                  docId: messages[index].id,
                                  fileName: fileName,
                                  bytes: fileBytes,
                                  type: msgType,
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Retry failed: $e')),
                              );
                            }
                          },
                        );
                      }
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              CircleAvatar(radius: 16, child: Text(senderName[0].toUpperCase())),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(senderName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                content,
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(formattedTime,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.black54)),
                                    const SizedBox(width: 4),
                                    if (isMe) statusIcon,
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => sendAttachment('file'),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => sendAttachment('image'),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => chatService.sendText(controller.text, controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
