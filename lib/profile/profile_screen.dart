import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_webapp/app/components/app_drawer.dart';
import 'package:my_webapp/features/chat/screens/chat_screen.dart';
import 'package:my_webapp/profile/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  // 🔁 Create or fetch private conversation
  Future<String> createOrGetConversation(
      String currentUserId, String otherUserId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .get();

    for (var doc in snapshot.docs) {
      final members = List<String>.from(doc['members'] ?? []);
      if (members.contains(otherUserId)) return doc.id;
    }

    final ref = FirebaseFirestore.instance.collection('conversations').doc();
    await ref.set({
      'members': [currentUserId, otherUserId],
      'type': 'private',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'lastMessage': null,
    });
    return ref.id;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      drawer: AppDrawer(),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final photoUrl = data['photoUrl'] ?? 'https://via.placeholder.com/150';
          final fullName = data['fullName'] ?? 'N/A';
          final username = data['username'] ?? '';
          final email = data['email'] ?? '';
          final bio = data['bio'] ?? '';
          final jobTitle = data['jobTitle'] ?? '';
          final company = data['company'] ?? '';
          final location = data['location'] ?? '';
          final phone = data['phone'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(photoUrl),
                ),
                const SizedBox(height: 16),
                Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(username, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                if (jobTitle.isNotEmpty || company.isNotEmpty)
                  Text('$jobTitle at $company', style: const TextStyle(fontSize: 14)),
                if (location.isNotEmpty) Text(location),
                const Divider(height: 32),
                if (bio.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      bio,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const Spacer(),
                if (currentUserId == userId) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final convoId = await createOrGetConversation(currentUserId, userId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversationId: convoId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text("Message"),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
