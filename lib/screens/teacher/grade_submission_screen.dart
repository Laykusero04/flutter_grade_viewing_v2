import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import 'teacher_component/teacher_drawer.dart';

class GradeSubmissionScreen extends StatelessWidget {
  const GradeSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Grade Submission',
        centerTitle: true,
      ),
      drawer: const TeacherDrawer(currentRoute: '/teacher/grade-submission'),
      body: const Center(
        child: Text(
          'Grade Submission',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
