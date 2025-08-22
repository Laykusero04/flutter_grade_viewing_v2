import 'package:flutter/material.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import 'admin_component/admin_drawer.dart';

class ManageGradesScreen extends StatelessWidget {
  const ManageGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'Manage Grades'),
      drawer: const AdminDrawer(currentRoute: '/admin/grades'),
      body: const Center(
        child: Text(
          'Manage Grades',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
