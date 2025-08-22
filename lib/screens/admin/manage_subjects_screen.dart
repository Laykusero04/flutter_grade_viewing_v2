import 'package:flutter/material.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import 'admin_component/admin_drawer.dart';

class ManageSubjectsScreen extends StatelessWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'Manage Subjects'),
      drawer: const AdminDrawer(currentRoute: '/admin/subjects'),
      body: const Center(
        
        child: Text(
          'Manage Subjects',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
