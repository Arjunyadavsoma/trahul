import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_webapp/core/services/firebase_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;

            final photoUrl = userData?['photoUrl'] ??
                "https://ui-avatars.com/api/?name=${currentUser?.displayName ?? 'User'}";
            final username = userData?['username'] ?? currentUser?.displayName ?? 'User';

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(photoUrl),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Dashboard"),
                  onTap: () => context.go('/dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text("People"),
                  onTap: () => context.go('/dashboard/people'),
                ),ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text("Ai Bot"),
                  onTap: () => context.go('/ai-bot'),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  onTap: () {
                    if (currentUser != null) {
                      context.go('/profile', extra: currentUser.uid);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseService.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
