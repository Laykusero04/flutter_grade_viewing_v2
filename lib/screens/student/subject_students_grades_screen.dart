import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import '../../service/firestore_grade_service.dart';
import '../../models/grade.dart';
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

class _SubjectStudentsGradesScreenState extends State<SubjectStudentsGradesScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Grade> _studentGrades = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrolledStudents();
    _loadStudentGrades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

    Future<void> _loadEnrolledStudents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First check if current user is enrolled in this subject
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final currentStudentEmail = authState.user.email;
        print('Checking enrollment for student email: $currentStudentEmail');
        print('Subject ID to check: ${widget.subjectId}');
        
        final currentEnrollments = await FirestoreSubjectEnrollmentService.getStudentEnrollments(currentStudentEmail);
        print('Found enrollments: ${currentEnrollments.length}');
        for (final enrollment in currentEnrollments) {
          print('Enrollment: ${enrollment['subjectId']} vs ${widget.subjectId}');
        }
        
        final isEnrolled = currentEnrollments.any((enrollment) => enrollment['subjectId'] == widget.subjectId);
        print('Is enrolled: $isEnrolled');
        
        if (!isEnrolled) {
          if (mounted) {
            setState(() {
              _enrolledStudents = [];
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are not enrolled in this subject. Please enroll first.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // Get all students enrolled in this subject
      final enrolledStudents = await FirestoreSubjectEnrollmentService.getEnrolledStudents(widget.subjectId);
      
      if (mounted) {
        setState(() {
          _enrolledStudents = enrolledStudents.map((student) => {
            'studentId': student.uid,
            'studentName': '${student.firstName} ${student.lastName}'.trim(),
            'studentIdNumber': student.schoolId,
            'email': student.email,
            'status': 'active',
            'enrollmentType': 'regular',
          }).toList();
          _filteredStudents = List.from(_enrolledStudents);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load enrolled students: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentGrades() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final currentStudentEmail = authState.user.email;
      if (currentStudentEmail != null) {
        final grades = await FirestoreGradeService.getStudentGrades(
          currentStudentEmail,
          widget.subjectId,
        );
        
        if (mounted) {
          setState(() {
            _studentGrades = grades;
          });
        }
      }
    } catch (e) {
      print('Error loading student grades: $e');
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

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_enrolledStudents);
      } else {
        _filteredStudents = _enrolledStudents.where((student) {
          final name = student['studentName']?.toString().toLowerCase() ?? '';
          final id = student['studentIdNumber']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          return name.contains(searchQuery) || 
                 id.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _showStudentSelectionDialog(String action, Function(Map<String, dynamic>) onStudentSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Student for $action'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
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
                  onTap: () {
                    Navigator.of(context).pop();
                    onStudentSelected(student);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveSubjectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Subject: ${widget.subjectName}'),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to leave this subject? This action cannot be undone and you will lose access to all subject materials and grades.',
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
                _leaveSubject();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave Subject'),
            ),
          ],
        );
      },
    );
  }

  void _leaveSubject() {
    // TODO: Implement leave subject functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave subject functionality will be implemented here'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // For now, just navigate back to enrolled subjects
    // In the future, this should:
    // 1. Remove student from subject enrollments
    // 2. Update database records
    // 3. Navigate back to enrolled subjects
    context.go('/student/enrolled-subjects');
  }

  Widget _buildStudentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Enrolled Students',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredStudents.length}/${_enrolledStudents.length} students',
                  style: AppTextStyles.body.copyWith(
                    color: AppColor.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'View all students enrolled in this subject. You can request grade updates or view grades for any enrolled student.',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _filterStudents,
            decoration: InputDecoration(
              hintText: 'Search students by name or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterStudents('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 32,
          ),

          // Students List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _enrolledStudents.isEmpty && !_isLoading 
                              ? 'You are not enrolled in this subject'
                              : _searchController.text.isNotEmpty
                                  ? 'No students found matching your search'
                                  : 'No students enrolled in this subject',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_enrolledStudents.isEmpty && !_isLoading) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Please enroll in this subject first to view enrolled students',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/student/enrolled-subjects'),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Enrolled Subjects'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                        if (_enrolledStudents.isNotEmpty && _searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
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
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Enrolled',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTab() {
    // Get grades for prelim, midterm, and final
    final prelimGrade = _studentGrades.firstWhere(
      (g) => g.assignmentName.toLowerCase() == 'prelim',
      orElse: () => Grade(
        uid: '',
        enrollmentId: '',
        subjectId: '',
        studentId: '',
        teacherId: '',
        assignmentName: 'Prelim',
        score: 0,
        maxScore: 5.0, // Philippine scale max
        gradeType: '',
        dateRecorded: DateTime.now(),
        comments: null,
        weight: 30,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final midtermGrade = _studentGrades.firstWhere(
      (g) => g.assignmentName.toLowerCase() == 'midterm',
      orElse: () => Grade(
        uid: '',
        enrollmentId: '',
        subjectId: '',
        studentId: '',
        teacherId: '',
        assignmentName: 'Midterm',
        score: 0,
        maxScore: 5.0, // Philippine scale max
        gradeType: '',
        dateRecorded: DateTime.now(),
        comments: null,
        weight: 30,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final finalGrade = _studentGrades.firstWhere(
      (g) => g.assignmentName.toLowerCase() == 'final',
      orElse: () => Grade(
        uid: '',
        enrollmentId: '',
        subjectId: '',
        studentId: '',
        teacherId: '',
        assignmentName: 'Final',
        score: 0,
        maxScore: 5.0, // Philippine scale max
        gradeType: '',
        dateRecorded: DateTime.now(),
        comments: null,
        weight: 40,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Calculate total grade
    double totalGrade = 0.0;
    double totalWeight = 0.0;
    
    if (prelimGrade.uid.isNotEmpty) {
      totalGrade += (prelimGrade.score * (prelimGrade.weight ?? 30));
      totalWeight += (prelimGrade.weight ?? 30);
    }
    if (midtermGrade.uid.isNotEmpty) {
      totalGrade += (midtermGrade.score * (midtermGrade.weight ?? 30));
      totalWeight += (midtermGrade.weight ?? 30);
    }
    if (finalGrade.uid.isNotEmpty) {
      totalGrade += (finalGrade.score * (finalGrade.weight ?? 40));
      totalWeight += (finalGrade.weight ?? 40);
    }
    
    final finalTotalGrade = totalWeight > 0 ? totalGrade / totalWeight : 0.0;
    // Grades are already in Philippine scale, no need to convert
    final philippineGrade = finalTotalGrade > 0 ? finalTotalGrade.toStringAsFixed(1) : 'N/A';
    final gradeColor = _getGradeColor(philippineGrade);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Grades',
            style: AppTextStyles.headline.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View your grades and performance in this subject',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Grade Breakdown
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade Breakdown',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_studentGrades.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.grade_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No grades recorded yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your teacher will input your grades here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _buildGradeRow('Prelim', 30, prelimGrade.uid.isNotEmpty ? prelimGrade.score.toString() : 'N/A'),
                      _buildGradeRow('Midterm', 30, midtermGrade.uid.isNotEmpty ? midtermGrade.score.toString() : 'N/A'),
                      _buildGradeRow('Final', 40, finalGrade.uid.isNotEmpty ? finalGrade.score.toString() : 'N/A'),
                      const Divider(height: 24),
                      _buildGradeRow('Total', 100, finalTotalGrade > 0 ? finalTotalGrade.toStringAsFixed(1) : 'N/A', isTotal: true),
                      
                      if (finalTotalGrade > 0) ...[
                        const SizedBox(height: 16),
                        _buildGradeEquivalentRow(philippineGrade),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard({
    required String title,
    required String grade,
    required String letterGrade,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              grade,
              style: AppTextStyles.headline.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                letterGrade,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(String component, int weight, dynamic grade, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              component,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? AppColor.primary : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$weight%',
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? AppColor.primary : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              grade is double ? grade.toStringAsFixed(1) : grade.toString(),
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? AppColor.primary : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // Get grade description based on Philippine scale
  String _getGradeDescription(String grade) {
    if (grade == 'N/A') return 'No Grade';
    
    final gradeValue = double.tryParse(grade);
    if (gradeValue == null) return 'Unknown';
    
    if (gradeValue >= 1.0 && gradeValue <= 1.9) return 'Excellent';
    if (gradeValue >= 2.0 && gradeValue <= 2.9) return 'Good';
    if (gradeValue >= 3.0 && gradeValue <= 3.9) return 'Satisfactory';
    if (gradeValue >= 4.0 && gradeValue <= 4.9) return 'Passing';
    if (gradeValue == 5.0) return 'Fail';
    return 'Unknown';
  }

  // Get color for grade (Philippine scale 1.0-5.0)
  Color _getGradeColor(String grade) {
    if (grade == 'N/A') return Colors.grey;
    
    final gradeValue = double.tryParse(grade);
    if (gradeValue == null) return Colors.grey;
    
    if (gradeValue >= 1.0 && gradeValue <= 1.9) return Colors.green;
    if (gradeValue >= 2.0 && gradeValue <= 2.9) return Colors.blue;
    if (gradeValue >= 3.0 && gradeValue <= 3.9) return Colors.orange;
    if (gradeValue >= 4.0 && gradeValue <= 4.9) return Colors.yellow.shade700;
    if (gradeValue == 5.0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildGradeEquivalentRow(String grade) {
    final description = _getGradeDescription(grade);
    final color = _getGradeColor(grade);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.grade,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      grade,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
            onPressed: () {
              _loadEnrolledStudents();
              _loadStudentGrades();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.grade),
              text: 'Grades',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Students',
            ),
          ],
        ),
      ),
              body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                                 children: [
                   // Tab 1: Grades
                   _buildGradesTab(),
                   // Tab 2: Students List
                   _buildStudentsTab(),
                 ],
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
                   if (_filteredStudents.isNotEmpty) {
                     _showStudentSelectionDialog('Request Grade Update', _showGradeRequestDialog);
                   }
                 },
               ),
               SpeedDialChild(
                 child: const Icon(Icons.grade),
                 backgroundColor: Colors.green,
                 foregroundColor: Colors.white,
                 label: 'View Grades',
                 onTap: () {
                   if (_filteredStudents.isNotEmpty) {
                     _showStudentSelectionDialog('View Grades', _showGradesOptions);
                   }
                 },
               ),
               SpeedDialChild(
                 child: const Icon(Icons.exit_to_app),
                 backgroundColor: Colors.red,
                 foregroundColor: Colors.white,
                 label: 'Leave Subject',
                 onTap: () {
                   _showLeaveSubjectDialog();
                 },
               ),
             ],
           ),
      );
    }
  }
