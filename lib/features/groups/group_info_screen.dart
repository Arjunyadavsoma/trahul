import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupId;
  const GroupInfoScreen({super.key, required this.groupId});

  Future<Map<String, dynamic>?> fetchGroupData() async {
    final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchGroupData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final groupData = snapshot.data!;
        final memberIds = List<String>.from(groupData['members'] ?? []);
        final groupName = groupData['name'] ?? 'Group';
        final groupDesc = groupData['description'] ?? '';
        final createdBy = groupData['createdBy'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text("Group Info"),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/group_placeholder.png'), // optional asset
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (groupDesc.isNotEmpty)
                      Text(groupDesc, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text("${memberIds.length} members", style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchGroupMembers(memberIds),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data!;
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['photoUrl'] != null
                                ? NetworkImage(user['photoUrl'])
                                : null,
                            child: user['photoUrl'] == null
                                ? Text(user['username']?.substring(0, 1) ?? '?')
                                : null,
                          ),
                          title: Text(user['username'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: user['id'] == createdBy
                              ? const Chip(label: Text("Admin"), backgroundColor: Colors.greenAccent)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
