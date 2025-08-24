import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../bloc/auth_bloc.dart';

class TeacherDrawer extends StatelessWidget {
  final String currentRoute;
  
  const TeacherDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'D E A R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Version 2.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == '/teacher',
            onTap: () {
              Navigator.pop(context);
              context.go('/teacher');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blue),
            title: const Text('Grade Submission'),
            selected: currentRoute == '/teacher/grade-submission',
            onTap: () {
              Navigator.pop(context);
              context.go('/teacher/grade-submission');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.green),
            title: const Text('Notifications'),
            selected: currentRoute == '/teacher/notifications',
            onTap: () {
              Navigator.pop(context);
              context.go('/teacher/notifications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.request_page, color: Colors.orange),
            title: const Text('Request'),
            selected: currentRoute == '/teacher/request',
            onTap: () {
              Navigator.pop(context);
              context.go('/teacher/request');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // Dispatch logout and navigate
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
