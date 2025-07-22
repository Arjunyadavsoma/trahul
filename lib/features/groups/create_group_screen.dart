import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final Set<String> selectedUserIds = {};
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 16),
            const Text("Select Members", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final users = snapshot.data!.docs.where((doc) => doc.id != currentUser?.uid).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final data = user.data() as Map<String, dynamic>;

                      return CheckboxListTile(
                        value: selectedUserIds.contains(userId),
                        title: Text(data['username'] ?? 'Unknown'),
                        subtitle: Text(data['email'] ?? ''),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedUserIds.add(userId);
                            } else {
                              selectedUserIds.remove(userId);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text("Create Group"),
              onPressed: () async {
                if (groupNameController.text.isEmpty || selectedUserIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a group name and select members.')),
                  );
                  return;
                }

                final groupDoc = FirebaseFirestore.instance.collection('groups').doc();
                final allMembers = [currentUser!.uid, ...selectedUserIds];

                await groupDoc.set({
                  'name': groupNameController.text.trim(),
                  'createdAt': Timestamp.now(),
                  'createdBy': currentUser?.uid,
                  'members': allMembers,
                });

                Navigator.pop(context); // Go back to group list
              },
            ),
          ],
        ),
      ),
    );
  }
}
