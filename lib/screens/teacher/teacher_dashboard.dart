import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/subject.dart';
import '../../service/firestore_subject_teacher_service.dart';
import 'teacher_component/teacher_drawer.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<Subject> _assignedSubjects = [];
  bool _isLoading = true;
  String? _teacherId;

  @override
  void initState() {
    super.initState();
    _loadAssignedSubjects();
  }

  Future<void> _loadAssignedSubjects() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the current teacher ID from auth bloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _teacherId = authState.user.email;
        if (_teacherId != null) {
          final subjects = await FirestoreSubjectTeacherService.getAssignedSubjects(_teacherId!);
          setState(() {
            _assignedSubjects = subjects;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assigned subjects: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'D E A R', centerTitle: true),
      drawer: const TeacherDrawer(currentRoute: '/teacher'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'My Assigned Subjects',
              style: AppTextStyles.headline.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            
            // Subjects List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _assignedSubjects.isEmpty
                      ? const Center(
                          child: Text(
                            'No subjects assigned yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _assignedSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = _assignedSubjects[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  // Navigate to subject students screen
                                  context.go('/teacher/subject-students/${subject.uid}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColor.primary,
                                    child: Text(
                                      subject.code.substring(0, 2).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    subject.name,
                                    style: AppTextStyles.headline.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Code: ${subject.code}',
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (subject.department != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Department: ${subject.department}',
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      if (subject.credits != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Credits: ${subject.credits}',
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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