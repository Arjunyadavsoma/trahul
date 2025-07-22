import 'package:flutter/material.dart';
import 'package:my_webapp/app/components/app_drawer.dart';
import 'package:my_webapp/features/dashboard/GroupListScreen.dart';
import 'package:my_webapp/features/dashboard/people_tab.dart';
import 'package:my_webapp/features/dashboard/all_users_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {}); // Rebuild FAB based on selected tab
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), // Your navigation drawer
      appBar: AppBar(
        title: const Text("Dashboard"),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'People'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          PeopleTab(),         // Tab 1: Private chats with users
          GroupListScreen(),   // Tab 2: Group chat list
        ],
      ),
      floatingActionButton: tabController.index == 0
          ? FloatingActionButton(
              tooltip: 'Add New User',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllUsersScreen()),
                );
              },
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
