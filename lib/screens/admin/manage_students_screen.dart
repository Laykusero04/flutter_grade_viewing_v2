import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/student_bloc.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/widget/student_form.dart';
import '../../components/widget/student_list_item.dart';
import '../../components/widget/student_filters.dart';
import '../../components/widget/student_detail_view.dart';
import '../../models/student.dart';
import 'admin_component/admin_drawer.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  @override
  void initState() {
    super.initState();
    // Load students when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentBloc>().add(LoadStudents());
    });
  }

  void _showAddStudentForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentForm(
          onSubmit: (Student student) {
            context.read<StudentBloc>().add(AddStudent(student));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showEditStudentForm(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentForm(
          student: student,
          onSubmit: (Student updatedStudent) {
            context.read<StudentBloc>().add(UpdateStudent(updatedStudent));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text(
            'Are you sure you want to delete ${student.fullName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<StudentBloc>().add(DeleteStudent(student.uid));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showStudentDetail(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentDetailView(
          student: student,
          onEdit: () {
            Navigator.of(context).pop(); // Close detail view
            _showEditStudentForm(student); // Show edit form
          },
          onDelete: () {
            Navigator.of(context).pop(); // Close detail view
            _showDeleteConfirmation(student); // Show delete confirmation
          },
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      context.read<StudentBloc>().add(LoadStudents());
    } else {
      context.read<StudentBloc>().add(SearchStudents(query));
    }
  }

  void _handleClearSearch() {
    context.read<StudentBloc>().add(LoadStudents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'Manage Students'),
      drawer: const AdminDrawer(currentRoute: '/admin/students'),
      body: BlocListener<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is StudentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is StudentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Search Section
            StudentFilters(
              onSearch: _handleSearch,
              onClearSearch: _handleClearSearch,
            ),

            // Students List Section
            Expanded(
              child: BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentInitial) {
                    return const Center(
                      child: Text('Click "Load Students" to get started'),
                    );
                  }

                  if (state is StudentLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading students...'),
                        ],
                      ),
                    );
                  }

                  if (state is StudentsLoaded) {
                    if (state.students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery != null
                                  ? 'Try adjusting your search criteria'
                                  : 'Add your first student to get started',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Results Summary
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Showing ${state.students.length} student${state.students.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              if (state.searchQuery != null) ...[
                                const SizedBox(width: 16),
                                Text(
                                  'for "${state.searchQuery}"',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Students List
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.students.length,
                            itemBuilder: (context, index) {
                              final student = state.students[index];
                              return StudentListItem(
                                student: student,
                                onEdit: () => _showEditStudentForm(student),
                                onDelete: () => _showDeleteConfirmation(student),
                                onTap: () => _showStudentDetail(student),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is StudentError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading students',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              color: Colors.red[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<StudentBloc>().add(LoadStudents());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return const Center(
                    child: Text('Unknown state'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
