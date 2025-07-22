import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:url_launcher/url_launcher.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final SupabaseClient supabase = Supabase.instance.client;

  String groupName = 'Loading...';
  List<String> memberIds = [];

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        groupName = data['name'] ?? 'Group Chat';
        memberIds = List<String>.from(data['members'] ?? []);
      });
    } else {
      setState(() {
        groupName = 'Group Not Found';
      });
    }
  }

  void sendMessage({String? text, String? fileUrl, String type = 'text'}) async {
    if (user == null || (text == null && fileUrl == null)) return;

    final msg = {
      'senderId': user!.uid,
      'senderName': user!.displayName ?? user!.email ?? 'Anonymous',
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

  Future<void> _showGroupMembers() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Group Members"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: usersSnapshot.docs.map((doc) {
              final data = doc.data();
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                  child: data['photoUrl'] == null
                      ? Text(data['username']?.substring(0, 1) ?? '?')
                      : null,
                ),
                title: Text(data['username'] ?? 'No Name'),
                subtitle: Text(data['email'] ?? ''),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
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
        title: GestureDetector(
          onTap: _showGroupMembers,
          child: Row(
            children: [
              Expanded(child: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold))),
              const Icon(Icons.info_outline, size: 18),
            ],
          ),
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
                  decoration: const InputDecoration(hintText: 'Type a message...'),
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
