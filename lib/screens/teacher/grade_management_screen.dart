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
import '../../service/firestore_subject_service.dart';
import '../../service/firestore_assignment_service.dart';
import '../../service/firestore_grade_service.dart';
import '../../service/firestore_subject_enrollment_service.dart';
import '../../bloc/auth_bloc.dart';
import 'teacher_component/teacher_drawer.dart';

class GradeManagementScreen extends StatefulWidget {
  final String subjectId;
  
  const GradeManagementScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Subject? _subject;
  List<Assignment> _assignments = [];
  List<Student> _enrolledStudents = [];
  List<Grade> _grades = [];
  bool _isLoading = true;
  
  // Assignment creation form
  final _formKey = GlobalKey<FormState>();
  final _assignmentNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGradeType = 'Quiz';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assignmentNameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load subject data
      final subject = await FirestoreSubjectService.getSubjectById(widget.subjectId);
      
      // Load assignments
      final assignments = await FirestoreAssignmentService.getSubjectAssignments(widget.subjectId);
      
      // Load enrolled students
      final students = await FirestoreSubjectEnrollmentService.getEnrolledStudents(widget.subjectId);
      
      // Load grades
      final grades = await FirestoreGradeService.getSubjectGrades(widget.subjectId);

      if (mounted) {
        setState(() {
          _subject = subject;
          _assignments = assignments;
          _enrolledStudents = students;
          _grades = grades;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final assignment = Assignment(
        uid: '',
        subjectId: widget.subjectId,
        teacherId: authState.user.email ?? '',
        name: _assignmentNameController.text.trim(),
        description: _descriptionController.text.trim(),
        maxScore: double.parse(_maxScoreController.text),
        gradeType: _selectedGradeType,
        weight: double.parse(_weightController.text),
        dueDate: _selectedDueDate,
        dateCreated: DateTime.now(),
        isActive: true,
      );

      await FirestoreAssignmentService.createAssignment(assignment);
      
      // Clear form
      _assignmentNameController.clear();
      _descriptionController.clear();
      _maxScoreController.clear();
      _weightController.clear();
      
      // Reload data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating assignment: $e')),
        );
      }
    }
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreAssignmentService.deleteAssignment(assignment.uid);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting assignment: $e')),
          );
        }
      }
    }
  }

  void _navigateToGradeEntry(Assignment assignment) {
    context.pushNamed(
      'teacher-grade-entry',
      extra: {
        'assignment': assignment,
        'subject': _subject,
        'students': _enrolledStudents,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Grade Management',
        centerTitle: true,
      ),
      drawer: const TeacherDrawer(currentRoute: '/teacher/grade-management'),
      body: Column(
        children: [
          // Subject info header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColor.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.book, color: AppColor.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _subject?.name ?? 'Unknown Subject',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _subject?.code ?? '',
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
                    '${_enrolledStudents.length} Students',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColor.primary,
            unselectedLabelColor: AppColor.secondary,
            indicatorColor: AppColor.primary,
            tabs: const [
              Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
              Tab(text: 'Grades', icon: Icon(Icons.grade)),
              Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(),
                _buildGradesTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create assignment section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Assignment',
                      style: AppTextStyles.title.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _assignmentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Assignment Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter assignment name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Max Score',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter max score';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGradeType,
                            decoration: const InputDecoration(
                              labelText: 'Grade Type',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Quiz', 'Homework', 'Exam', 'Project', 'Participation']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGradeType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Weight (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter weight';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDueDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Due: ${_selectedDueDate.toString().split(' ')[0]}',
                                    style: AppTextStyles.body,
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Create Assignment',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Assignments list
          Text(
            'Current Assignments',
            style: AppTextStyles.title.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_assignments.isEmpty)
            const Center(
              child: Text(
                'No assignments created yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _assignments.length,
                itemBuilder: (context, index) {
                  final assignment = _assignments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColor.primary,
                        child: Icon(Icons.assignment, color: Colors.white),
                      ),
                      title: Text(
                        assignment.name,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assignment.description),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColor.secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  assignment.gradeType,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColor.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Max: ${assignment.maxScore}',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Weight: ${assignment.weight}%',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'grade',
                            child: Row(
                              children: [
                                Icon(Icons.grade, color: AppColor.primary),
                                const SizedBox(width: 8),
                                const Text('Enter Grades'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppColor.secondary),
                                const SizedBox(width: 8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'grade':
                              _navigateToGradeEntry(assignment);
                              break;
                            case 'edit':
                              // TODO: Implement edit functionality
                              break;
                            case 'delete':
                              _deleteAssignment(assignment);
                              break;
                          }
                        },
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
    // Group grades by assignment
    final gradesByAssignment = <String, List<Grade>>{};
    for (final grade in _grades) {
      gradesByAssignment.putIfAbsent(grade.assignmentName, () => []).add(grade);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Grades',
            style: AppTextStyles.title.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (gradesByAssignment.isEmpty)
            const Center(
              child: Text(
                'No grades recorded yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: gradesByAssignment.length,
                itemBuilder: (context, index) {
                  final assignmentName = gradesByAssignment.keys.elementAt(index);
                  final grades = gradesByAssignment[assignmentName]!;
                   
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        assignmentName,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${grades.length} students graded'),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: grades.length,
                          itemBuilder: (context, gradeIndex) {
                            final grade = grades[gradeIndex];
                            final student = _enrolledStudents.firstWhere(
                              (s) => s.uid == grade.studentId,
                              orElse: () => Student(
                                uid: grade.studentId,
                                email: grade.studentId,
                                firstName: 'Unknown',
                                lastName: 'Student',
                                schoolId: 'N/A',
                                userRole: 3,
                              ),
                            );
                            
                            return ListTile(
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
                              title: Text(student.fullName),
                              subtitle: Text('${grade.score}/${grade.maxScore} (${grade.percentage.toStringAsFixed(1)}%)'),
                              trailing: Text(
                                grade.dateRecorded.toString().split(' ')[0],
                                style: AppTextStyles.caption,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grade Statistics',
            style: AppTextStyles.title.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Students',
                  '${_enrolledStudents.length}',
                  Icons.people,
                  AppColor.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Assignments',
                  '${_assignments.length}',
                  Icons.assignment,
                  AppColor.secondary,
                ),
              ),
            ],
          ),
          

          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Graded Students',
                  '${_grades.map((g) => g.studentId).toSet().length}',
                  Icons.grade,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Grades',
                  '${_grades.length}',
                  Icons.assessment,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Grade distribution chart
          if (_grades.isNotEmpty) ...[
            Text(
              'Grade Distribution',
              style: AppTextStyles.title.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGradeDistributionChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildGradeDistributionChart() {
    final gradeCounts = <String, int>{};
    for (final grade in _grades) {
      gradeCounts[grade.letterGrade] = (gradeCounts[grade.letterGrade] ?? 0) + 1;
    }

    final totalGrades = _grades.length;
    if (totalGrades == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: gradeCounts.entries.map((entry) {
            final percentage = (entry.value / totalGrades) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.key,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value / totalGrades,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getGradeColor(_getGradePercentage(entry.key)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  double _getGradePercentage(String letterGrade) {
    switch (letterGrade) {
      case 'A': return 95;
      case 'B': return 85;
      case 'C': return 75;
      case 'D': return 65;
      case 'F': return 55;
      default: return 0;
    }
  }
}
