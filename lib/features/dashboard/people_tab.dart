import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_webapp/features/chat/screens/chat_screen.dart'; // <-- Ensure correct import

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  // ✅ Create or get existing conversation between two users
  Future<String> getOrCreateConversation(String userA, String userB) async {
    final query = await FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: userA)
        .get();

    for (var doc in query.docs) {
      final members = List<String>.from(doc['members']);
      if (members.contains(userB)) return doc.id;
    }

    final newConvo = FirebaseFirestore.instance.collection('conversations').doc();
    await newConvo.set({
      'members': [userA, userB],
      'type': 'private',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'lastMessage': null,
    });
    return newConvo.id;
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text("Not logged in"));
    }

    final conversationStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .where('type', isEqualTo: 'private')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: conversationStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversationDocs = snapshot.data?.docs ?? [];

        final Set<String> otherUserIds = {};
        for (var doc in conversationDocs) {
          final members = List<String>.from(doc['members']);
          final otherId = members.firstWhere((id) => id != currentUserId, orElse: () => '');
          if (otherId.isNotEmpty) otherUserIds.add(otherId);
        }

        if (otherUserIds.isEmpty) {
          return const Center(child: Text("No recent chats yet."));
        }

        final usersQuery = FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: otherUserIds.toList())
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: usersQuery,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userDocs = userSnapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: userDocs.length,
              itemBuilder: (context, index) {
                final user = userDocs[index];
                final userId = user.id;
                final data = user.data() as Map<String, dynamic>;
                final username = data['username'] ?? 'No Name';
                final email = data['email'] ?? '';
                final photoUrl = data['photoUrl'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(username.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(username),
                  subtitle: Text(email),
                  onTap: () async {
                    final convoId = await getOrCreateConversation(currentUserId, userId);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversationId: convoId),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
