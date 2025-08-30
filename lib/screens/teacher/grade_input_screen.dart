import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/subject.dart';
import '../../models/grade.dart';
import '../../models/student.dart';
import '../../service/firestore_grade_service.dart';
import '../../bloc/auth_bloc.dart';
import 'teacher_component/teacher_drawer.dart';

class GradeInputScreen extends StatefulWidget {
  final String subjectId;
  final String studentId;
  final String studentName;
  final Subject subject;
  
  const GradeInputScreen({
    super.key,
    required this.subjectId,
    required this.studentId,
    required this.studentName,
    required this.subject,
  });

  @override
  State<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends State<GradeInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prelimController = TextEditingController();
  final _midtermController = TextEditingController();
  final _finalController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasExistingGrades = false;
  
  // Grade weights (Philippine system)
  static const double prelimWeight = 30.0;
  static const double midtermWeight = 30.0;
  static const double finalWeight = 40.0;

  @override
  void initState() {
    super.initState();
    _loadExistingGrades();
  }

  @override
  void dispose() {
    _prelimController.dispose();
    _midtermController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGrades() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load existing grades for this student in this subject
      final grades = await FirestoreGradeService.getStudentGrades(
        widget.studentId,
        widget.subjectId,
      );

      // Check for existing prelim, midterm, and final grades
      for (final grade in grades) {
        switch (grade.assignmentName.toLowerCase()) {
          case 'prelim':
            _prelimController.text = grade.score.toString();
            _hasExistingGrades = true;
            break;
          case 'midterm':
            _midtermController.text = grade.score.toString();
            _hasExistingGrades = true;
            break;
          case 'final':
            _finalController.text = grade.score.toString();
            _hasExistingGrades = true;
            break;
        }
        
        
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading existing grades: $e')),
        );
      }
    }
  }

  Future<void> _saveGrades() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final now = DateTime.now();
      final grades = <Grade>[];

      // Create/update prelim grade
      if (_prelimController.text.isNotEmpty) {
        final prelimScore = double.parse(_prelimController.text);
        final prelimGrade = Grade(
          uid: '',
          enrollmentId: '', // Will be set when saving
          subjectId: widget.subjectId,
          studentId: widget.studentId,
          teacherId: authState.user.email ?? '',
          assignmentName: 'Prelim',
          score: prelimScore,
          maxScore: 5.0, // Philippine scale max
          gradeType: 'Exam',
          dateRecorded: now,
          comments: null,
          weight: prelimWeight,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        grades.add(prelimGrade);
      }

      // Create/update midterm grade
      if (_midtermController.text.isNotEmpty) {
        final midtermScore = double.parse(_midtermController.text);
        final midtermGrade = Grade(
          uid: '',
          enrollmentId: '', // Will be set when saving
          subjectId: widget.subjectId,
          studentId: widget.studentId,
          teacherId: authState.user.email ?? '',
          assignmentName: 'Midterm',
          score: midtermScore,
          maxScore: 5.0, // Philippine scale max
          gradeType: 'Exam',
          dateRecorded: now,
          comments: null,
          weight: midtermWeight,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        grades.add(midtermGrade);
      }

      // Create/update final grade
      if (_finalController.text.isNotEmpty) {
        final finalScore = double.parse(_finalController.text);
        final finalGrade = Grade(
          uid: '',
          enrollmentId: '', // Will be set when saving
          subjectId: widget.subjectId,
          studentId: widget.studentId,
          teacherId: authState.user.email ?? '',
          assignmentName: 'Final',
          score: finalScore,
          maxScore: 5.0, // Philippine scale max
          gradeType: 'Exam',
          dateRecorded: now,
          comments: null,
          weight: finalWeight,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        grades.add(finalGrade);
      }

      // Save all grades
      if (grades.isNotEmpty) {
        await FirestoreGradeService.bulkAddGrades(grades);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grades saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateTotalGrade() {
    double total = 0.0;
    double totalWeight = 0.0;
    
    if (_prelimController.text.isNotEmpty) {
      total += (double.parse(_prelimController.text) * prelimWeight);
      totalWeight += prelimWeight;
    }
    
    if (_midtermController.text.isNotEmpty) {
      total += (double.parse(_midtermController.text) * midtermWeight);
      totalWeight += midtermWeight;
    }
    
    if (_finalController.text.isNotEmpty) {
      total += (double.parse(_finalController.text) * finalWeight);
      totalWeight += finalWeight;
    }
    
    return totalWeight > 0 ? total / totalWeight : 0.0;
  }

  String _getGradeDescription(double grade) {
    if (grade >= 1.0 && grade <= 1.9) return 'Excellent';
    if (grade >= 2.0 && grade <= 2.9) return 'Good';
    if (grade >= 3.0 && grade <= 3.9) return 'Satisfactory';
    if (grade >= 4.0 && grade <= 4.9) return 'Passing';
    if (grade == 5.0) return 'Fail';
    return 'Invalid Grade';
  }

  Color _getGradeColor(double grade) {
    if (grade >= 1.0 && grade <= 1.9) return Colors.green;
    if (grade >= 2.0 && grade <= 2.9) return Colors.blue;
    if (grade >= 3.0 && grade <= 3.9) return Colors.orange;
    if (grade >= 4.0 && grade <= 4.9) return Colors.yellow.shade700;
    if (grade == 5.0) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final totalGrade = _calculateTotalGrade();
    final gradeColor = _getGradeColor(totalGrade);
    final gradeDescription = _getGradeDescription(totalGrade);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Grades'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student and Subject Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                    '${widget.subject.name} (${widget.subject.code})',
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
                    ),
                    
                    const SizedBox(height: 24),
                    
                                         // Grade Input Form
                     Text(
                       'Enter Grades',
                       style: AppTextStyles.title.copyWith(
                         color: AppColor.primary,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                    
                    const SizedBox(height: 24),
                    
                                         // Prelim Grade
                     TextFormField(
                       controller: _prelimController,
                       decoration: InputDecoration(
                         labelText: 'Prelim Grade',
                         hintText: 'Enter prelim grade',
                         border: const OutlineInputBorder(),
                         prefixIcon: const Icon(Icons.grade),
                         suffixText: '30%',
                       ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final grade = double.tryParse(value);
                          if (grade == null || grade < 1.0 || grade > 5.0) {
                            return 'Grade must be between 1.0 and 5.0';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                                         // Midterm Grade
                     TextFormField(
                       controller: _midtermController,
                       decoration: InputDecoration(
                         labelText: 'Midterm Grade',
                         hintText: 'Enter midterm grade',
                         border: const OutlineInputBorder(),
                         prefixIcon: const Icon(Icons.grade),
                         suffixText: '30%',
                       ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final grade = double.tryParse(value);
                          if (grade == null || grade < 1.0 || grade > 5.0) {
                            return 'Grade must be between 1.0 and 5.0';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                                         // Final Grade
                     TextFormField(
                       controller: _finalController,
                       decoration: InputDecoration(
                         labelText: 'Final Grade',
                         hintText: 'Enter final grade',
                         border: const OutlineInputBorder(),
                         prefixIcon: const Icon(Icons.grade),
                         suffixText: '40%',
                       ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final grade = double.tryParse(value);
                          if (grade == null || grade < 1.0 || grade > 5.0) {
                            return 'Grade must be between 1.0 and 5.0';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    
                    
                    // Grade Summary
                    if (_prelimController.text.isNotEmpty || 
                        _midtermController.text.isNotEmpty || 
                        _finalController.text.isNotEmpty) ...[
                      Card(
                        color: gradeColor.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grade Summary',
                                style: AppTextStyles.title.copyWith(
                                  color: gradeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Grade breakdown
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGradeSummaryItem(
                                      'Prelim',
                                      _prelimController.text.isEmpty ? 'N/A' : _prelimController.text,
                                      prelimWeight,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGradeSummaryItem(
                                      'Midterm',
                                      _midtermController.text.isEmpty ? 'N/A' : _midtermController.text,
                                      midtermWeight,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGradeSummaryItem(
                                      'Final',
                                      _finalController.text.isEmpty ? 'N/A' : _finalController.text,
                                      finalWeight,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              // Total grade
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Final Grade:',
                                    style: AppTextStyles.title.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        totalGrade > 0 ? totalGrade.toStringAsFixed(2) : 'N/A',
                                        style: AppTextStyles.title.copyWith(
                                          color: gradeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: gradeColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          gradeDescription,
                                          style: AppTextStyles.title.copyWith(
                                            color: gradeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Save Button
                    SizedBox(
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
                                'Save Grades',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGradeSummaryItem(String label, String grade, double weight) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          grade,
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${weight.toStringAsFixed(0)}%',
          style: AppTextStyles.caption.copyWith(
            color: AppColor.secondary,
          ),
        ),
      ],
    );
  }
}
