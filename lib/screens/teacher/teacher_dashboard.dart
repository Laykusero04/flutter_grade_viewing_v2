import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/subject.dart';

import '../../service/firestore_subject_teacher_service.dart';
import '../../service/firestore_subject_teacher_qr_service.dart';
import '../../components/widget/qr_code_modal.dart';
import 'teacher_component/teacher_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _showQRCodeOptions() {
    if (_assignedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects assigned to generate QR codes for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate QR Code',
              style: AppTextStyles.headline.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a subject to generate a QR code for student enrollment:',
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _assignedSubjects.length,
                itemBuilder: (context, index) {
                  final subject = _assignedSubjects[index];
                  return ListTile(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Code: ${subject.code}',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _generateQRCode(subject);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQRCode(Subject subject) async {
    if (_teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the subject-teacher assignment ID
      final assignmentDetails = await FirestoreSubjectTeacherService.getAssignmentDetails(_teacherId!);
      final assignment = assignmentDetails.firstWhere(
        (detail) => detail['subjectId'] == subject.uid,
        orElse: () => {},
      );

      if (assignment.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject assignment not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get or create QR session
      final qrSession = await FirestoreSubjectTeacherQRService.getOrCreateQRSession(
        subjectTeacherId: assignment['assignmentId']!,
        teacherId: _teacherId!,
        subjectId: subject.uid,
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
                    subject: subject,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
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
            subject: subject,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'D E A R', centerTitle: true),
      drawer: const TeacherDrawer(currentRoute: '/teacher'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQRCodeOptions,
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code),
        label: const Text('QR Code'),
      ),
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