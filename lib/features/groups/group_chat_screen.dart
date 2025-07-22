import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_webapp/features/groups/group_info_screen.dart'; // ✅ Import Group Info Screen

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final supabase = Supabase.instance.client;

  String groupName = 'Group Chat';
  List<String> memberIds = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      final data = groupDoc.data()!;
      setState(() {
        groupName = data['name'] ?? 'Group Chat';
        memberIds = List<String>.from(data['members']);
      });
    }
  }

  void sendMessage({String? text, String? fileUrl, String type = 'text'}) async {
    if (user == null) return;
    if (text == null && fileUrl == null) return;

    final msg = {
      'senderId': user?.uid,
      'senderName': user?.displayName ?? user?.email ?? 'Anonymous',
      'timestamp': Timestamp.now(),
      'type': type,
      'text': text ?? '',
      'fileUrl': fileUrl ?? '',
    };

    await FirebaseFirestore.instance
        .collection('groupMessages')
        .doc(widget.groupId)
        .collection('messages')
        .add(msg);
  }

  Future<void> sendFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;

    final file = result.files.first;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

    try {
      await supabase.storage.from('chat-files').uploadBinary('group/$fileName', file.bytes!);
      final publicUrl = supabase.storage.from('chat-files').getPublicUrl('group/$fileName');
      sendMessage(fileUrl: publicUrl, type: 'file');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File upload failed: $e')));
    }
  }

  void _navigateToGroupInfo() {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true, // 👈 opens the new screen full-screen style
      builder: (_) => GroupInfoScreen(groupId: widget.groupId),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('groupMessages')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();

    return Scaffold(
     appBar: AppBar(
  title: Row(
    children: [
      Expanded(
        child: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      GestureDetector(
        onTap: _navigateToGroupInfo, // <-- Tapping the icon opens group info
        child: const Icon(Icons.info_outline, size: 18),
      ),
    ],
  ),
),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: isMe ? Colors.blue[100] : Colors.grey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['senderName'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (data['type'] == 'file')
                                InkWell(
                                  onTap: () => launchUrl(Uri.parse(data['fileUrl'])),
                                  child: Text(
                                    "📁 ${Uri.parse(data['fileUrl']).pathSegments.last}",
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                )
                              else
                                Text(data['text'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                (data['timestamp'] as Timestamp)
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.attach_file), onPressed: sendFile),
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(hintText: 'Type message...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = messageController.text.trim();
                  if (text.isNotEmpty) {
                    sendMessage(text: text);
                    messageController.clear();
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
