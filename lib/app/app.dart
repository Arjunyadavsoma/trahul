import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_webapp/features/ai/ai_chat_screen.dart';

// Screens
import 'package:my_webapp/features/auth/screens/splash_screen.dart';
import 'package:my_webapp/features/auth/screens/login_screen.dart';
import 'package:my_webapp/features/auth/screens/signup_screen.dart';
import 'package:my_webapp/features/dashboard/all_users_screen.dart';
import 'package:my_webapp/features/dashboard/dashboard_screen.dart';
import 'package:my_webapp/features/chat/screens/chat_list_screen.dart';
import 'package:my_webapp/features/dashboard/groups_tab.dart';
import 'package:my_webapp/features/dashboard/people_tab.dart';
import 'package:my_webapp/profile/edit_profile_screen.dart';
import 'package:my_webapp/profile/profile_screen.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/ai-bot',
        builder: (BuildContext context, GoRouterState state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'people',
            builder: (BuildContext context, GoRouterState state) => const AllUsersScreen(),
          ),
          GoRoute(
            path: 'groups',
            builder: (BuildContext context, GoRouterState state) =>
                const GroupChatScreen(groupId: ''), // <-- Pass a real groupId later
          ),
        ],
      ),
      GoRoute(
        path: '/chat-list',
        builder: (BuildContext context, GoRouterState state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          final userId = state.extra as String?;
          if (userId == null) {
            return const Scaffold(body: Center(child: Text('No user ID provided')));
          }
          return ProfileScreen(userId: userId);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              final userId = state.extra as String?;
              if (userId == null) {
                return const Scaffold(body: Center(child: Text('No user ID for editing')));
              }
              return EditProfileScreen(userId: userId);
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Professional Messaging App',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.light,
      ),
    );
  }
}
