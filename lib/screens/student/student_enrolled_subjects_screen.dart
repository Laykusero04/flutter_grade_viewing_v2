import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentEnrolledSubjectsScreen extends StatefulWidget {
  const StudentEnrolledSubjectsScreen({super.key});

  @override
  State<StudentEnrolledSubjectsScreen> createState() => _StudentEnrolledSubjectsScreenState();
}

class _StudentEnrolledSubjectsScreenState extends State<StudentEnrolledSubjectsScreen> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoading = true;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _studentId = authState.user.uid;
        if (_studentId != null) {
          final enrollments = await FirestoreSubjectEnrollmentService.getStudentEnrollments(_studentId!);
          if (mounted) {
            setState(() {
              _enrollments = enrollments;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load enrollments: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Enrolled Subjects',
          style: AppTextStyles.headline.copyWith(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Enrolled Subjects (${_enrollments.length})',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here are all the subjects you are currently enrolled in',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enrollments List
                  Expanded(
                    child: _enrollments.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No subjects enrolled yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Use the QR scanner to enroll in subjects',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _enrollments.length,
                            itemBuilder: (context, index) {
                              final enrollment = _enrollments[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                                                     onTap: () => context.go(
                                     '/student/subject-students-grades',
                                     extra: {
                                       'subjectId': enrollment['subjectId'],
                                       'subjectName': enrollment['subjectName'],
                                       'subjectCode': enrollment['subjectCode'],
                                     },
                                   ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Subject Header
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColor.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.book,
                                                size: 24,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    enrollment['subjectName'] ?? 'Unknown Subject',
                                                    style: AppTextStyles.headline.copyWith(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Code: ${enrollment['subjectCode'] ?? 'N/A'}',
                                                    style: AppTextStyles.body.copyWith(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Teacher: ${enrollment['teacherName'] ?? 'Unknown Teacher'}',
                                                    style: AppTextStyles.body.copyWith(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
