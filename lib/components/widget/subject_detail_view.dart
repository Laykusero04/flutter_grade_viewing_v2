import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../bloc/subject_bloc.dart';
import '../../service/firestore_subject_service.dart';

class SubjectDetailView extends StatefulWidget {
  final Subject subject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubjectDetailView({
    super.key,
    required this.subject,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SubjectDetailView> createState() => _SubjectDetailViewState();
}

class _SubjectDetailViewState extends State<SubjectDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SubjectBloc _detailBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Create a separate bloc instance for this detail view to avoid state conflicts
    _detailBloc = SubjectBloc();
    
    // Load teachers for this subject
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detailBloc.add(LoadSubjectTeachers(widget.subject.uid));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _detailBloc.close(); // Close the bloc when disposing
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Assigned Teachers',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'Subject Info',
            ),
          ],
        ),
        actions: [
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: widget.onEdit,
              tooltip: 'Edit Subject',
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
              color: Colors.red[200],
              tooltip: 'Delete Subject',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersTab(),
          _buildSubjectInfoTab(),
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    return BlocBuilder<SubjectBloc, SubjectState>(
      bloc: _detailBloc, // Use the local bloc instance
      builder: (context, state) {
        // Only handle states that are relevant to this subject's teachers
        if (state is SubjectTeachersLoaded && state.subjectId == widget.subject.uid) {
          final assignedTeachers = state.teachers;
          
          return Column(
            children: [
              // Header with add teacher button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Teachers',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Teachers currently assigned to ${widget.subject.name}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAssignTeacherDialog,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assign Teachers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Teachers list
              Expanded(
                child: assignedTeachers.isEmpty
                    ? _buildEmptyTeachersState()
                    : _buildTeachersList(assignedTeachers),
              ),
            ],
          );
        }
        
        // Handle error state only if it's related to this subject's teachers
        if (state is SubjectError) {
          // Check if this error is related to loading teachers for this subject
          if (state.message.contains('Failed to load subject teachers') || 
              state.message.contains('Failed to fetch subject teachers')) {
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
                      _detailBloc.add(LoadSubjectTeachers(widget.subject.uid));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        }
        
        // Loading state (for any other state or initial state)
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
      },
    );
  }

  Widget _buildEmptyTeachersState() {
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
            'No Teachers Assigned',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This subject doesn\'t have any teachers assigned yet.',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
                     ElevatedButton.icon(
             onPressed: _showAssignTeacherDialog,
             icon: const Icon(Icons.person_add),
             label: const Text('Assign Teachers'),
             style: ElevatedButton.styleFrom(
               backgroundColor: Theme.of(context).primaryColor,
               foregroundColor: Colors.white,
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTeachersList(List<Teacher> teachers) {
    return ListView.builder(
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                teacher.firstName.isNotEmpty ? teacher.firstName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              teacher.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher.email),
                if (teacher.department != null)
                  Text(
                    'Department: ${teacher.department}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (teacher.qualification != null)
                  Text(
                    'Qualification: ${teacher.qualification}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    // TODO: Navigate to teacher detail view
                    break;
                  case 'remove':
                    _showRemoveTeacherDialog(teacher);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Assignment', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveTeacherDialog(Teacher teacher) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Teacher Assignment'),
          content: Text(
            'Are you sure you want to remove ${teacher.fullName} from ${widget.subject.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Store references before closing dialog
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
                  Navigator.of(context).pop();
                  
                  // Remove teacher assignment from Firestore
                  await FirestoreSubjectService.removeTeacherFromSubject(
                    widget.subject.uid,
                    teacher.uid,
                  );
                  
                  // Reload teachers
                  _detailBloc.add(LoadSubjectTeachers(widget.subject.uid));
                   
                   // Check if still mounted before showing SnackBar
                   if (mounted) {
                     scaffoldMessenger.showSnackBar(
                       SnackBar(
                         content: Text('${teacher.fullName} removed from ${widget.subject.name}'),
                         backgroundColor: Colors.orange,
                       ),
                     );
                   }
                } catch (e) {
                  // Check if still mounted before showing error SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to remove teacher: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

    void _showAssignTeacherDialog() async {
    try {
      // Get available teachers from Firestore
      final availableTeachers = await FirestoreSubjectService.getAvailableTeachers(widget.subject.uid);

      if (!mounted) return;

      // Create the selected teachers set outside StatefulBuilder to persist selections
      final Set<String> selectedTeacherIds = <String>{};

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text('Assign Teachers to ${widget.subject.name}'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400, // Fixed height for better UX
                  child: Column(
                    children: [
                      if (availableTeachers.isEmpty) ...[
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Available Teachers',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All teachers are currently assigned or no teachers are available.',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Select teachers to assign to this subject:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = availableTeachers[index];
                              return CheckboxListTile(
                                value: selectedTeacherIds.contains(teacher.uid),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedTeacherIds.add(teacher.uid);
                                    } else {
                                      selectedTeacherIds.remove(teacher.uid);
                                    }
                                  });
                                },
                                title: Text(
                                  teacher.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(teacher.email),
                                    if (teacher.department != null)
                                      Text(
                                        'Department: ${teacher.department}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                secondary: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    teacher.firstName.isNotEmpty ? teacher.firstName[0].toUpperCase() : 'T',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                // Ensure the checkbox is tappable
                                tristate: false,
                                dense: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedTeacherIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${selectedTeacherIds.length} teacher${selectedTeacherIds.length == 1 ? '' : 's'} selected',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        

                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (availableTeachers.isNotEmpty && selectedTeacherIds.isNotEmpty)
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Store references before closing dialog
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          Navigator.of(context).pop();
                          
                                                     // Assign all selected teachers to subject in Firestore
                           int successCount = 0;
                           int errorCount = 0;
                           
                                                       for (String teacherId in selectedTeacherIds) {
                              try {
                                await FirestoreSubjectService.assignTeacherToSubject(
                                  widget.subject.uid,
                                  teacherId,
                                );
                                successCount++;
                              } catch (e) {
                                errorCount++;
                              }
                            }
                          
                                                     // Reload teachers
                           _detailBloc.add(LoadSubjectTeachers(widget.subject.uid));
                           
                           // Check if still mounted before showing SnackBar
                           if (mounted) {
                             if (errorCount == 0) {
                               scaffoldMessenger.showSnackBar(
                                 SnackBar(
                                   content: Text('$successCount teacher${successCount == 1 ? '' : 's'} assigned to ${widget.subject.name}'),
                                   backgroundColor: Colors.green,
                                 ),
                               );
                               
                                                             } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('$successCount teacher${successCount == 1 ? '' : 's'} assigned, $errorCount failed'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                           }
                        } catch (e) {
                          // Check if still mounted before showing error SnackBar
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to assign teachers: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Assign ${selectedTeacherIds.length} Teacher${selectedTeacherIds.length == 1 ? '' : 's'}'),
                    ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      // Check if still mounted before showing error SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load available teachers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Widget _buildSubjectInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Subject Icon
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.book,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject Name
                  Text(
                    widget.subject.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subject Code
                  Text(
                    widget.subject.code,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (widget.subject.isActive ?? true) ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (widget.subject.isActive ?? true) ? 'Active Subject' : 'Inactive Subject',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Edit Button (Prominent)
          if (widget.onEdit != null)
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Subject Information', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (widget.onEdit != null) const SizedBox(height: 20),

          // Basic Information
          _buildSection(
            context,
            title: 'Basic Information',
            icon: Icons.info,
            children: [
              _buildInfoRow('Name', widget.subject.name),
              _buildInfoRow('Code', widget.subject.code),
              _buildInfoRow('Description', widget.subject.description ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 20),

          // Academic Information
          _buildSection(
            context,
            title: 'Academic Information',
            icon: Icons.school,
            children: [
              _buildInfoRow('Department', widget.subject.department ?? 'N/A'),
              _buildInfoRow('Credits', '${widget.subject.credits ?? 'N/A'} credits'),
              _buildInfoRow('Academic Year', widget.subject.academicYear ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 20),

          // Additional Information
          if (widget.subject.additionalInfo.isNotEmpty)
            _buildSection(
              context,
              title: 'Additional Information',
              icon: Icons.more_horiz,
              children: widget.subject.additionalInfo.entries.map((entry) {
                return _buildInfoRow(entry.key, entry.value.toString());
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
