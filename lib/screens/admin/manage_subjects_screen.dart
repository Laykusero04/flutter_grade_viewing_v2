import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/subject_bloc.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/widget/subject_form.dart';
import '../../components/widget/subject_list_item.dart';
import '../../components/widget/subject_filters.dart';
import 'subject_detail_view.dart';
import '../../models/subject.dart';

import 'admin_component/admin_drawer.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    // Load subjects when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectBloc>().add(LoadSubjects());
    });
  }

  void _showAddSubjectForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectForm(
          onSubmit: (Subject subject) {
            context.read<SubjectBloc>().add(AddSubject(subject));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showEditSubjectForm(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectForm(
          subject: subject,
          onSubmit: (Subject updatedSubject) {
            context.read<SubjectBloc>().add(UpdateSubject(updatedSubject));
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showSubjectDetail(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectDetailView(
          subject: subject,
          onEdit: () {
            Navigator.of(context).pop(); // Close detail view
            _showEditSubjectForm(subject); // Show edit form
          },
          onDelete: () {
            Navigator.of(context).pop(); // Close detail view
            _showDeleteConfirmation(subject); // Show delete confirmation
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Subject subject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: Text(
            'Are you sure you want to delete ${subject.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SubjectBloc>().add(DeleteSubject(subject.uid));
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

  void _handleSearch(String query) {
    if (query.isEmpty) {
      context.read<SubjectBloc>().add(LoadSubjects());
    } else {
      context.read<SubjectBloc>().add(SearchSubjects(query));
    }
  }

  void _handleClearSearch() {
    context.read<SubjectBloc>().add(LoadSubjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DearV2AppBar(
        title: 'Manage Subjects',
      ),
      drawer: const AdminDrawer(currentRoute: '/admin/subjects'),
      body: BlocListener<SubjectBloc, SubjectState>(
        listener: (context, state) {
          if (state is SubjectOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SubjectError) {
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
            SubjectFilters(
              onSearch: _handleSearch,
              onClearSearch: _handleClearSearch,
            ),

            // Subjects List Section
            Expanded(
              child: BlocBuilder<SubjectBloc, SubjectState>(
                builder: (context, state) {
                  if (state is SubjectInitial) {
                    return const Center(
                      child: Text('Click "Load Subjects" to get started'),
                    );
                  }

                  if (state is SubjectLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading subjects...'),
                        ],
                      ),
                    );
                  }

                  if (state is SubjectsLoaded) {
                    if (state.subjects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subjects found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery != null
                                  ? 'Try adjusting your search criteria'
                                  : 'Add your first subject to get started',
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
                                'Showing ${state.subjects.length} subject${state.subjects.length == 1 ? '' : 's'}',
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

                        // Subjects List
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.subjects.length,
                            itemBuilder: (context, index) {
                              final subject = state.subjects[index];
                              return SubjectListItem(
                                subject: subject,
                                onEdit: () => _showEditSubjectForm(subject),
                                onDelete: () => _showDeleteConfirmation(subject),
                                onTap: () => _showSubjectDetail(subject),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is SubjectError) {
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
                            'Error loading subjects',
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
                              context.read<SubjectBloc>().add(LoadSubjects());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Handle SubjectTeachersLoaded state (when returning from detail view)
                  if (state is SubjectTeachersLoaded) {
                    // Don't reload subjects automatically - this causes glitching
                    // Just show the last known subjects state
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Viewing Subject Details',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Return to subjects list to continue',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // If we reach here, it means we have an unhandled state
                  // This should not happen in normal operation
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unexpected state',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try refreshing the page',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<SubjectBloc>().add(LoadSubjects());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
