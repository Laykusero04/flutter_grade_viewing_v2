import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/subject.dart';
import '../../models/assignment.dart';
import '../../models/grade.dart';
import '../../models/student.dart';
import '../../service/firestore_grade_service.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import '../../bloc/auth_bloc.dart';
import 'teacher_component/teacher_drawer.dart';

class GradeEntryScreen extends StatefulWidget {
  final Assignment assignment;
  final Subject subject;
  final List<Student> students;
  
  const GradeEntryScreen({
    super.key,
    required this.assignment,
    required this.subject,
    required this.students,
  });

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};
  bool _isLoading = false;
  List<Grade> _existingGrades = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingGrades();
  }

  @override
  void dispose() {
    _scoreControllers.values.forEach((controller) => controller.dispose());
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    for (final student in widget.students) {
      _scoreControllers[student.uid] = TextEditingController();
      _commentControllers[student.uid] = TextEditingController();
    }
  }

  Future<void> _loadExistingGrades() async {
    try {
      final grades = await FirestoreGradeService.getAssignmentGrades(
        widget.assignment.name,
        widget.subject.uid,
      );
      
      setState(() {
        _existingGrades = grades;
      });

      // Pre-fill existing grades
      for (final grade in grades) {
        if (_scoreControllers.containsKey(grade.studentId)) {
          _scoreControllers[grade.studentId]!.text = grade.score.toString();
          if (grade.comments != null) {
            _commentControllers[grade.studentId]!.text = grade.comments!;
          }
        }
      }
    } catch (e) {
      print('Error loading existing grades: $e');
    }
  }

  Future<void> _saveGrades() async {
    if (!_validateGrades()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final grades = <Grade>[];
      final now = DateTime.now();

      for (final student in widget.students) {
        final scoreText = _scoreControllers[student.uid]!.text.trim();
        if (scoreText.isNotEmpty) {
          final score = double.parse(scoreText);
          final comments = _commentControllers[student.uid]!.text.trim();
          
          // Check if grade already exists
          final existingGrade = _existingGrades.firstWhere(
            (g) => g.studentId == student.uid && g.assignmentName == widget.assignment.name,
            orElse: () => Grade(
              uid: '',
              enrollmentId: '', // Will be set when saving
              subjectId: widget.subject.uid,
              studentId: student.uid,
              teacherId: authState.user.email ?? '',
              assignmentName: widget.assignment.name,
              score: 0,
              maxScore: widget.assignment.maxScore,
              gradeType: widget.assignment.gradeType,
              dateRecorded: now,
              comments: null,
              weight: widget.assignment.weight,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
          );

          if (existingGrade.uid.isEmpty) {
            // Create new grade
            final grade = Grade(
              uid: '',
              enrollmentId: '', // Will be set when saving
              subjectId: widget.subject.uid,
              studentId: student.uid,
              teacherId: authState.user.email ?? '',
              assignmentName: widget.assignment.name,
              score: score,
              maxScore: widget.assignment.maxScore,
              gradeType: widget.assignment.gradeType,
              dateRecorded: now,
              comments: comments.isEmpty ? null : comments,
              weight: widget.assignment.weight,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            );
            grades.add(grade);
          } else {
            // Update existing grade
            final updatedGrade = existingGrade.copyWith(
              score: score,
              comments: comments.isEmpty ? null : comments,
              updatedAt: now,
            );
            await FirestoreGradeService.updateGrade(existingGrade.uid, updatedGrade);
          }
        }
      }

      // Save new grades in batch
      if (grades.isNotEmpty) {
        await FirestoreGradeService.bulkAddGrades(grades);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grades saved successfully!')),
      );

      // Navigate back
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving grades: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateGrades() {
    for (final student in widget.students) {
      final scoreText = _scoreControllers[student.uid]!.text.trim();
      if (scoreText.isNotEmpty) {
        final score = double.tryParse(scoreText);
        if (score == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid score for ${student.fullName}')),
          );
          return false;
        }
        if (score < 0 || score > widget.assignment.maxScore) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Score for ${student.fullName} must be between 0 and ${widget.assignment.maxScore}',
              ),
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Enter Grades',
        centerTitle: true,
      ),
      drawer: const TeacherDrawer(currentRoute: '/teacher/grade-entry'),
      body: Column(
        children: [
          // Assignment info header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColor.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: AppColor.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.assignment.name,
                            style: AppTextStyles.title.copyWith(
                              color: AppColor.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.subject.name} (${widget.subject.code})',
                            style: AppTextStyles.body.copyWith(
                              color: AppColor.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Max: ${widget.assignment.maxScore}',
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.assignment.description,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.assignment.gradeType,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColor.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight: ${widget.assignment.weight}%',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${widget.assignment.dueDate.toString().split(' ')[0]}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter scores for each student. Leave blank to skip. You can add optional comments.',
                    style: AppTextStyles.body.copyWith(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          
          // Grades list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final existingGrade = _existingGrades.firstWhere(
                  (g) => g.studentId == student.uid && g.assignmentName == widget.assignment.name,
                  orElse: () => Grade(
                    uid: '',
                    enrollmentId: '',
                    subjectId: widget.subject.uid,
                    studentId: student.uid,
                    teacherId: '',
                    assignmentName: widget.assignment.name,
                    score: 0,
                    maxScore: widget.assignment.maxScore,
                    gradeType: widget.assignment.gradeType,
                    dateRecorded: DateTime.now(),
                    comments: null,
                    weight: widget.assignment.weight,
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColor.primary,
                              child: Text(
                                student.firstName[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullName,
                                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'ID: ${student.schoolId}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            if (existingGrade.uid.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Graded',
                                  style: AppTextStyles.caption.copyWith(color: Colors.green[700]),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _scoreControllers[student.uid]!,
                                decoration: InputDecoration(
                                  labelText: 'Score',
                                  hintText: '0 - ${widget.assignment.maxScore}',
                                  border: const OutlineInputBorder(),
                                  suffixText: '/ ${widget.assignment.maxScore}',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Percentage',
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPercentageText(student.uid),
                                      style: AppTextStyles.title.copyWith(
                                        color: _getPercentageColor(student.uid),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _commentControllers[student.uid]!,
                          decoration: const InputDecoration(
                            labelText: 'Comments (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'Add any comments about this student\'s performance...',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGrades,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save All Grades',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPercentageText(String studentId) {
    final scoreText = _scoreControllers[studentId]?.text.trim() ?? '';
    if (scoreText.isEmpty) return '0%';
    
    final score = double.tryParse(scoreText);
    if (score == null) return '0%';
    
    final percentage = (score / widget.assignment.maxScore) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  Color _getPercentageColor(String studentId) {
    final scoreText = _scoreControllers[studentId]?.text.trim() ?? '';
    if (scoreText.isEmpty) return Colors.grey;
    
    final score = double.tryParse(scoreText);
    if (score == null) return Colors.grey;
    
    final percentage = (score / widget.assignment.maxScore) * 100;
    
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}
