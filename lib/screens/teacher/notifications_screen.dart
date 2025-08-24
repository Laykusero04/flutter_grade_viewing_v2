import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import 'teacher_component/teacher_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Notifications',
        centerTitle: true,
      ),
      drawer: const TeacherDrawer(currentRoute: '/teacher/notifications'),
      body: const Center(
        child: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
