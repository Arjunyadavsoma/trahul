import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/profile_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchTerm = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name, username, or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          // Filter based on search term
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName']?.toString().toLowerCase() ?? '';
            final username = data['username']?.toString().toLowerCase() ?? '';
            final email = data['email']?.toString().toLowerCase() ?? '';
            return name.contains(searchTerm) ||
                   username.contains(searchTerm) ||
                   email.contains(searchTerm);
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    data['photoUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(data['username'] ?? 'Unknown'),
                subtitle: Text(data['email'] ?? 'No email'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: filteredDocs[index].id),
                    ),
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
