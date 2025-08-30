import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/grade.dart';
import '../../service/firestore_grade_service.dart';
import '../../service/firestore_subject_service.dart';
import '../../bloc/auth_bloc.dart';

class GradeStudentScreen extends StatefulWidget {
  final String subjectId;
  final String studentId;
  final String studentName;
  
  const GradeStudentScreen({
    super.key,
    required this.subjectId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<GradeStudentScreen> createState() => _GradeStudentScreenState();
}

class _GradeStudentScreenState extends State<GradeStudentScreen> {
  List<Grade> _grades = [];
  bool _isLoading = true;
  String? _subjectName;

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

      // Load subject name
      final subject = await FirestoreSubjectService.getSubjectById(widget.subjectId);
      
      // Load student grades
      final grades = await FirestoreGradeService.getStudentGrades(
        widget.studentId,
        widget.subjectId,
      );

      setState(() {
        _subjectName = subject?.name;
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Student Grades',
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColor.primary,
                          radius: 30,
                          child: Text(
                            widget.studentName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.studentName,
                                style: AppTextStyles.title.copyWith(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _subjectName ?? 'Unknown Subject',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColor.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Grades summary
                  if (_grades.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Assignments',
                            '${_grades.length}',
                            Icons.assignment,
                            AppColor.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Average Score',
                            _calculateAverageScore(),
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Grades list
                  Text(
                    'Assignment Grades',
                    style: AppTextStyles.title.copyWith(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_grades.isEmpty)
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
                            'No grades recorded yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _grades.length,
                        itemBuilder: (context, index) {
                          final grade = _grades[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getGradeColor(grade.percentage),
                                child: Text(
                                  grade.letterGrade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                grade.assignmentName,
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${grade.score}/${grade.maxScore} (${grade.percentage.toStringAsFixed(1)}%)'),
                                  if (grade.comments != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Comments: ${grade.comments}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recorded: ${grade.dateRecorded.toString().split(' ')[0]}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  grade.gradeType,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColor.secondary,
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
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.title.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColor.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateAverageScore() {
    if (_grades.isEmpty) return '0%';
    
    final totalPercentage = _grades.fold<double>(
      0,
      (sum, grade) => sum + grade.percentage,
    );
    final average = totalPercentage / _grades.length;
    return '${average.toStringAsFixed(1)}%';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}
