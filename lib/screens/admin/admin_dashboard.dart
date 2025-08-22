import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import 'admin_component/admin_drawer.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'D E A R', centerTitle: true),
      drawer: const AdminDrawer(currentRoute: '/admin'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('Dashboard', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
        )
      ),
    );
  }
}