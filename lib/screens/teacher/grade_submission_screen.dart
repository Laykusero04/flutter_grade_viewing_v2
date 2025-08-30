import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../service/firestore_subject_teacher_service.dart';
import '../../service/firestore_subject_service.dart';
import '../../bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'teacher_component/teacher_drawer.dart';

class GradeSubmissionScreen extends StatefulWidget {
  const GradeSubmissionScreen({super.key});

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  List<Map<String, dynamic>> _teacherSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherSubjects();
  }

  Future<void> _loadTeacherSubjects() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final teacherId = authState.user.email;
      if (teacherId != null) {
        final subjects = await FirestoreSubjectTeacherService.getAssignmentDetails(teacherId);
        setState(() {
          _teacherSubjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subjects: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Grade Management',
        centerTitle: true,
      ),
      drawer: const TeacherDrawer(currentRoute: '/teacher/grade-submission'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a subject to manage grades:',
                    style: AppTextStyles.title.copyWith(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_teacherSubjects.isEmpty)
                    const Center(
                      child: Text(
                        'No subjects assigned yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _teacherSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _teacherSubjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColor.primary,
                                child: Icon(Icons.book, color: Colors.white),
                              ),
                              title: Text(
                                subject['subjectName'] ?? 'Unknown Subject',
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                subject['subjectCode'] ?? '',
                                style: AppTextStyles.body,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                context.pushNamed(
                                  'teacher-grade-management',
                                  pathParameters: {
                                    'subjectId': subject['subjectId'],
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
