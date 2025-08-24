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
      
      // Load enrolled students
      final students = await FirestoreSubjectEnrollmentService.getEnrolledStudents(widget.subjectId);
      
      setState(() {
        _subject = subject;
        _enrolledStudents = students;
        _isLoading = false;
      });
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
            label: 'QR Code',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap: () {
              // TODO: Implement QR code functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Code functionality coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
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
                        if (subject.department != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Department: ${subject.department}',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
                  'Enrolled Students (${_enrolledStudents.length})',
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
                            'No students enrolled yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _enrolledStudents.length,
                      itemBuilder: (context, index) {
                        final student = _enrolledStudents[index];
                        return Card(
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
