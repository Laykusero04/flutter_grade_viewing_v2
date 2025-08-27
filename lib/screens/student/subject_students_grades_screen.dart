import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectStudentsGradesScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  
  const SubjectStudentsGradesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  @override
  State<SubjectStudentsGradesScreen> createState() => _SubjectStudentsGradesScreenState();
}

class _SubjectStudentsGradesScreenState extends State<SubjectStudentsGradesScreen> {
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledStudents();
  }

    Future<void> _loadEnrolledStudents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current student's enrollment info for this subject
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final studentId = authState.user.uid;
        final enrollments = await FirestoreSubjectEnrollmentService.getStudentEnrollments(studentId);
        
        // Find the enrollment for this specific subject
        final subjectEnrollment = enrollments.firstWhere(
          (enrollment) => enrollment['subjectId'] == widget.subjectId,
          orElse: () => {},
        );

        if (subjectEnrollment.isNotEmpty) {
          // Show current student's info
          final studentsData = [{
            'studentId': studentId,
            'studentName': '${authState.user.firstName} ${authState.user.lastName}'.trim(),
            'studentIdNumber': authState.user.schoolId,
            'email': authState.user.email,
            'status': 'active',
            'enrollmentType': subjectEnrollment['enrolledVia'] ?? 'regular',
          }];

          setState(() {
            _enrolledStudents = studentsData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _enrolledStudents = [];
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
          SnackBar(content: Text('Failed to load enrollment: $e')),
        );
      }
    }
  }

  void _showGradeRequestDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request Grade for ${student['studentName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Subject: ${widget.subjectName}'),
              const SizedBox(height: 16),
              const Text(
                'This will send a grade request to the teacher. The teacher will be notified and can update the student\'s grades.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestGrade(student);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Grade'),
            ),
          ],
        );
      },
    );
  }

  void _requestGrade(Map<String, dynamic> student) {
    // TODO: Implement grade request functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grade request sent for ${student['studentName']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showGradesOptions(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Grades for ${student['studentName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Subject: ${widget.subjectName}'),
              const SizedBox(height: 16),
              const Text(
                'Grade options and viewing functionality will be implemented here.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                 title: Text(
           '${widget.subjectName}',
           style: AppTextStyles.headline.copyWith(
             fontSize: 20,
             color: Colors.white,
           ),
         ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/enrolled-subjects'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrolledStudents,
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
                  Text(
                    'List of Students',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                   // Divider
                   Divider(
                     color: Colors.grey[300],
                     thickness: 1,
                     height: 32,
                   ),

                   // Students List
                  Expanded(
                    child: _enrolledStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Not enrolled in this subject',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                                                 : ListView.builder(
                             itemCount: _enrolledStudents.length,
                             itemBuilder: (context, index) {
                               final student = _enrolledStudents[index];
                               
                               return ListTile(
                                 leading: CircleAvatar(
                                   backgroundColor: AppColor.primary,
                                   child: Icon(
                                     Icons.person,
                                     color: Colors.white,
                                   ),
                                 ),
                                 title: Text(
                                   student['studentName'] ?? 'Unknown Student',
                                   style: AppTextStyles.headline.copyWith(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                                                                    subtitle: Text(
                                     'ID: ${student['studentIdNumber'] ?? 'N/A'}',
                                     style: AppTextStyles.body.copyWith(
                                       color: Colors.grey[600],
                                       fontSize: 12,
                                     ),
                                   ),
                                 
                               );
                             },
                           ),
                  ),
                ],
              ),
            ),
        floatingActionButton: SpeedDial(
          icon: Icons.menu,
          activeIcon: Icons.close,
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          activeBackgroundColor: Colors.red,
          activeForegroundColor: Colors.white,
          buttonSize: const Size(56.0, 56.0),
          visible: true,
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: [
            SpeedDialChild(
              child: const Icon(Icons.request_page),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              label: 'Request Grade Update',
              onTap: () {
                if (_enrolledStudents.isNotEmpty) {
                  _showGradeRequestDialog(_enrolledStudents.first);
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.grade),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              label: 'View My Grades',
              onTap: () {
                if (_enrolledStudents.isNotEmpty) {
                  _showGradesOptions(_enrolledStudents.first);
                }
              },
            ),
          ],
        ),
      );
    }
  }
