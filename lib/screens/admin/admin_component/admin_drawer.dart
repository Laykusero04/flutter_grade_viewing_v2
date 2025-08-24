import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../bloc/auth_bloc.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;
  
  const AdminDrawer({
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
            selected: currentRoute == '/admin',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: const Text('Manage Students'),
            selected: currentRoute == '/admin/students',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/students');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.green),
            title: const Text('Manage Teachers'),
            selected: currentRoute == '/admin/teachers',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/teachers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.orange),
            title: const Text('Manage Subjects'),
            selected: currentRoute == '/admin/subjects',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/subjects');
            },
          ),
          ListTile(
            leading: const Icon(Icons.grade, color: Colors.purple),
            title: const Text('Manage Grades'),
            selected: currentRoute == '/admin/grades',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/grades');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.indigo),
            title: const Text('Manage Academic Years'),
            selected: currentRoute == '/admin/academic_years',
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/academic_years');
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
