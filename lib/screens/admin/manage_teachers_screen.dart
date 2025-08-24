import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/teacher_bloc.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/widget/teacher_form.dart';
import '../../components/widget/teacher_list_item.dart';
import '../../components/widget/teacher_filters.dart';
import 'teacher_detail_view.dart';
import '../../models/teacher.dart';
import 'admin_component/admin_drawer.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  @override
  void initState() {
    super.initState();
    // Load teachers when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherBloc>().add(LoadTeachers());
    });
  }

  void _showAddTeacherForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherForm(
          onSubmit: (Teacher teacher) {
            context.read<TeacherBloc>().add(AddTeacher(teacher));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showEditTeacherForm(Teacher teacher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherForm(
          teacher: teacher,
          onSubmit: (Teacher updatedTeacher) {
            context.read<TeacherBloc>().add(UpdateTeacher(updatedTeacher));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Teacher teacher) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Teacher'),
          content: Text(
            'Are you sure you want to delete ${teacher.fullName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<TeacherBloc>().add(DeleteTeacher(teacher.uid));
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

  void _showTeacherDetail(Teacher teacher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeacherDetailView(
          teacher: teacher,
          onEdit: () {
            Navigator.of(context).pop(); // Close detail view
            _showEditTeacherForm(teacher); // Show edit form
          },
          onDelete: () {
            Navigator.of(context).pop(); // Close detail view
            _showDeleteConfirmation(teacher); // Show delete confirmation
          },
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      context.read<TeacherBloc>().add(LoadTeachers());
    } else {
      context.read<TeacherBloc>().add(SearchTeachers(query));
    }
  }

  void _handleClearSearch() {
    context.read<TeacherBloc>().add(LoadTeachers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(title: 'Manage Teachers'),
      drawer: const AdminDrawer(currentRoute: '/admin/teachers'),
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is TeacherError) {
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
            TeacherFilters(
              onSearch: _handleSearch,
              onClearSearch: _handleClearSearch,
            ),

            // Teachers List Section
            Expanded(
              child: BlocBuilder<TeacherBloc, TeacherState>(
                builder: (context, state) {
                  if (state is TeacherInitial) {
                    return const Center(
                      child: Text('Click "Load Teachers" to get started'),
                    );
                  }

                  if (state is TeacherLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading teachers...'),
                        ],
                      ),
                    );
                  }

                  if (state is TeachersLoaded) {
                    if (state.teachers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No teachers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery != null
                                  ? 'Try adjusting your search criteria'
                                  : 'Add your first teacher to get started',
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
                                'Showing ${state.teachers.length} teacher${state.teachers.length == 1 ? '' : 's'}',
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

                        // Teachers List
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = state.teachers[index];
                              return TeacherListItem(
                                teacher: teacher,
                                onEdit: () => _showEditTeacherForm(teacher),
                                onDelete: () => _showDeleteConfirmation(teacher),
                                onTap: () => _showTeacherDetail(teacher),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is TeacherError) {
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
                            'Error loading teachers',
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
                              context.read<TeacherBloc>().add(LoadTeachers());
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
        onPressed: _showAddTeacherForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
