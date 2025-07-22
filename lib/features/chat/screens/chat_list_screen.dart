import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/conversation.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final stream = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No conversations yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final conversation = Conversation.fromMap(docs[index].id, data);
              final lastMessage = conversation.lastMessage?['text'] ?? "No messages yet";

              final isGroup = conversation.type == 'group';
              final otherMemberId = conversation.members
                  .firstWhere((id) => id != currentUserId, orElse: () => 'unknown');

              return FutureBuilder<DocumentSnapshot>(
                future: isGroup
                    ? Future.value(null) // Skip fetching user if it's a group
                    : FirebaseFirestore.instance.collection('users').doc(otherMemberId).get(),
                builder: (context, userSnapshot) {
                  String displayName = 'Private Chat';
                  String? avatarUrl;

                  if (isGroup) {
                    displayName = 'Group Chat';
                  } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    displayName = userData['username'] ?? 'User';
                    avatarUrl = userData['photoUrl'];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? Text(displayName[0]) : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(lastMessage),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversationId: conversation.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
