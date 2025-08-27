import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import '../../service/firestore_subject_service.dart';
import '../../service/firestore_subject_teacher_qr_service.dart';
import '../../service/firestore_subject_teacher_service.dart';
import '../../models/qr_session.dart';
import '../../components/widget/qr_code_modal.dart';
import '../../bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectStudentsScreen extends StatefulWidget {
  final String subjectId;
  
  const SubjectStudentsScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<SubjectStudentsScreen> createState() => _SubjectStudentsScreenState();
}

class _SubjectStudentsScreenState extends State<SubjectStudentsScreen> {
  List<Student> _enrolledStudents = [];
  Subject? _subject;
  bool _isLoading = true;
  List<QRSession> _activeQRSessions = [];
  List<Map<String, dynamic>> _qrEnrolledStudents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load subject data
      final subject = await FirestoreSubjectService.getSubjectById(widget.subjectId);
      
      // Load enrolled students from main enrollments collection
      final students = await FirestoreSubjectEnrollmentService.getEnrolledStudents(widget.subjectId);
      
      // Load active QR sessions for this subject and get QR-enrolled students
      final authState = context.read<AuthBloc>().state;
      List<QRSession> activeSessions = [];
      List<Map<String, dynamic>> qrEnrolledStudents = [];
      
      if (authState is AuthAuthenticated) {
        final teacherId = authState.user.email;
        if (teacherId != null) {
          try {
            // Get QR session for this specific subject-teacher assignment
            final assignmentDetails = await FirestoreSubjectTeacherService.getAssignmentDetails(teacherId);
            final assignment = assignmentDetails.firstWhere(
              (detail) => detail['subjectId'] == widget.subjectId,
              orElse: () => {},
            );
            
            if (assignment.isNotEmpty) {
              final assignmentId = assignment['assignmentId']!;
              final qrSession = await FirestoreSubjectTeacherQRService.getQRSession(assignmentId);
              if (qrSession != null && qrSession.isActive) {
                activeSessions = [qrSession];
              }
              
              // Get students enrolled via QR code from the enrolled_students subcollection
              qrEnrolledStudents = await FirestoreSubjectTeacherQRService.getEnrolledStudents(assignmentId);
            }
          } catch (e) {
            // Ignore QR session loading errors for now
            print('Error loading QR sessions: $e');
          }
        }
      }
      
      setState(() {
        _subject = subject;
        _enrolledStudents = students;
        _activeQRSessions = activeSessions;
        _isLoading = false;
      });
      
      // Store QR enrolled students separately for display
      _qrEnrolledStudents = qrEnrolledStudents;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _generateQRCode() async {
    if (_subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the current teacher ID from auth bloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final teacherId = authState.user.email;
      if (teacherId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the subject-teacher assignment ID
      final assignmentDetails = await FirestoreSubjectTeacherService.getAssignmentDetails(teacherId);
      final assignment = assignmentDetails.firstWhere(
        (detail) => detail['subjectId'] == widget.subjectId,
        orElse: () => {},
      );

      if (assignment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject assignment not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get or create QR session
      final qrSession = await FirestoreSubjectTeacherQRService.getOrCreateQRSession(
        subjectTeacherId: assignment['assignmentId']!,
        teacherId: teacherId,
        subjectId: widget.subjectId,
        assignedAt: assignment['assignedAt'] != null 
            ? (assignment['assignedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

      // Check if QR is inactive and show activation alert
      if (!qrSession.isActive) {
        if (mounted) {
          final shouldActivate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('QR Code Inactive'),
              content: const Text(
                'This QR code is currently inactive. Students cannot enroll using this code.\n\n'
                'Would you like to activate it now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Activate'),
                ),
              ],
            ),
          );

          if (shouldActivate == true) {
            // Activate the QR
            final newStatus = await FirestoreSubjectTeacherQRService.setQREnrollmentStatus(
              subjectTeacherId: assignment['assignmentId']!,
              isActive: true,
            );

            if (newStatus) {
              // Update the session with active status
              final updatedSession = qrSession.copyWith(isActive: true);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR code activated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Show QR code modal with active session
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => QRCodeModal(
                    qrSession: updatedSession,
                    subject: _subject!,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
                
                // Refresh QR sessions list
                _refreshQRSessions();
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to activate QR code'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
          return;
        }
      }

      // Show QR code modal (QR is already active)
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => QRCodeModal(
            qrSession: qrSession,
            subject: _subject!,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
        
        // Refresh QR sessions list
        _refreshQRSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshQRSessions() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final teacherId = authState.user.email;
        if (teacherId != null) {
          // Get QR session for this specific subject-teacher assignment
          final assignmentDetails = await FirestoreSubjectTeacherService.getAssignmentDetails(teacherId);
          final assignment = assignmentDetails.firstWhere(
            (detail) => detail['subjectId'] == widget.subjectId,
            orElse: () => {},
          );
          
          if (assignment.isNotEmpty) {
            final assignmentId = assignment['assignmentId']!;
            final qrSession = await FirestoreSubjectTeacherQRService.getQRSession(assignmentId);
            if (qrSession != null && qrSession.isActive) {
              setState(() {
                _activeQRSessions = [qrSession];
              });
            } else {
              setState(() {
                _activeQRSessions = [];
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error refreshing QR sessions: $e');
    }
  }

  Future<void> _deactivateQRSession(String subjectTeacherId) async {
    try {
      final success = await FirestoreSubjectTeacherQRService.deactivateQREnrollment(subjectTeacherId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR enrollment deactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the QR sessions list
        _refreshQRSessions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to deactivate QR enrollment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deactivating QR enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const DearV2AppBar(
          title: 'Subject Students',
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_subject == null) {
      return Scaffold(
        appBar: const DearV2AppBar(
          title: 'Subject Students',
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: BackButton(),
        ),
        body: const Center(
          child: Text('Subject not found'),
        ),
      );
    }

    final subject = _subject!;

    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Subject Students',
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: BackButton(),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
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
            child: const Icon(Icons.person_add, color: Colors.white),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Add/Invite Student',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap: () {
              // TODO: Implement add/invite student functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add/Invite Student functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code, color: Colors.white),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Generate QR Code',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap: () => _generateQRCode(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.assignment, color: Colors.white),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Submit Grades',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap: () {
              context.go('/teacher/grade-submission');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.primary,
                    radius: 25,
                    child: Text(
                      subject.code.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: AppTextStyles.headline.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${subject.code}',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (subject.academicYear != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Academic Year: ${subject.academicYear}',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                                                 // QR Session Status
                         Row(
                           children: [
                             Icon(
                               Icons.qr_code,
                               size: 16,
                               color: _activeQRSessions.isNotEmpty ? Colors.green : Colors.grey,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               _activeQRSessions.isNotEmpty 
                                   ? 'Active QR Code'
                                   : 'No Active QR Code',
                               style: AppTextStyles.body.copyWith(
                                 color: _activeQRSessions.isNotEmpty ? Colors.green : Colors.grey,
                                 fontSize: 12,
                               ),
                             ),
                           ],
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Students Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Students (${_enrolledStudents.length + _qrEnrolledStudents.length})',
                  style: AppTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            


            
                        // Students List
            Expanded(
              child: _enrolledStudents.isEmpty && _qrEnrolledStudents.isEmpty
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
                            'No students enrolled yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                                                 // Regular Enrollments Section
                         if (_enrolledStudents.isNotEmpty) ...[
                          ..._enrolledStudents.map((student) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColor.primary.withValues(alpha: 0.2),
                                child: Text(
                                  student.firstName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${student.firstName} ${student.lastName}',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Student ID: ${student.schoolId}',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (student.email != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Email: ${student.email}',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.grade),
                                onPressed: () {
                                  // Navigate to grade submission for this specific student
                                  context.go('/teacher/grade-submission');
                                },
                                tooltip: 'Grade Student',
                              ),
                            ),
                          )).toList(),
                        ],
                        
                                                 // QR Enrollments Section
                         if (_qrEnrolledStudents.isNotEmpty) ...[
                           if (_enrolledStudents.isNotEmpty) const SizedBox(height: 16),
                          ..._qrEnrolledStudents.map((student) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColor.primary.withValues(alpha: 0.2),
                                child: Text(
                                  student['studentName']?.substring(0, 1).toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student['studentName'] ?? 'Unknown Student',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Student ID: ${student['studentId']}',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (student['studentEmail'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Email: ${student['studentEmail']}',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enrolled via: QR Code',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (student['enrolledAt'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enrolled: ${_formatDateTime((student['enrolledAt'] as Timestamp).toDate())}',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'QR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.grade),
                                    onPressed: () {
                                      // Navigate to grade submission for this specific student
                                      context.go('/teacher/grade-submission');
                                    },
                                    tooltip: 'Grade Student',
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
