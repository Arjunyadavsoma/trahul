import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_webapp/features/dashboard/groups_tab.dart'; // GroupChatScreen
import 'package:my_webapp/features/groups/create_group_screen.dart'; // Ensure correct import

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your groups.")),
      );
    }

    final groupsStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You haven't joined or created any groups yet."));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final data = group.data() as Map<String, dynamic>;
              final groupName = data['name'] ?? 'Unnamed Group';
              final groupDesc = data['description'] ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: groupDesc.isNotEmpty ? Text(groupDesc) : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupChatScreen(groupId: group.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create New Group',
        child: const Icon(Icons.group_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
      ),
    );
  }
}
