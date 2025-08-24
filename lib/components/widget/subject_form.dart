import 'package:flutter/material.dart';
import '../../models/subject.dart';
import '../../models/department.dart';
import '../../service/firestore_academic_year_service.dart';
import '../../service/firestore_department_service.dart';

class SubjectForm extends StatefulWidget {
  final Subject? subject;
  final Function(Subject) onSubmit;
  final VoidCallback? onCancel;

  const SubjectForm({
    super.key,
    this.subject,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _creditsController;
  late TextEditingController _academicYearController;
  
  bool _isActive = true;
  bool _isLoadingAcademicYear = true;
  bool _isLoadingDepartments = true;
  
  List<Department> _departments = [];
  Department? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadActiveAcademicYear();
    _loadDepartments();
  }

  void _initializeControllers() {
    final subject = widget.subject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _codeController = TextEditingController(text: subject?.code ?? '');
    _descriptionController = TextEditingController(text: subject?.description ?? '');
    _creditsController = TextEditingController(text: subject?.credits?.toString() ?? '');
    _academicYearController = TextEditingController(text: subject?.academicYear ?? '');
    
    _isActive = subject?.isActive ?? true;
  }

  Future<void> _loadActiveAcademicYear() async {
    try {
      final activeYear = await FirestoreAcademicYearService.getActiveAcademicYear();
      if (activeYear != null && widget.subject == null) {
        // Only auto-fill if it's a new subject (not editing)
        _academicYearController.text = activeYear.displayName;
      }
    } catch (e) {
      // If we can't load the academic year, just continue
      print('Could not load active academic year: $e');
    } finally {
      setState(() {
        _isLoadingAcademicYear = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() {
        _isLoadingDepartments = true;
      });
      
      final departments = await FirestoreDepartmentService.getActiveDepartments();
      print('Loaded ${departments.length} departments: ${departments.map((d) => d.name).toList()}');
      
      setState(() {
        _departments = departments;
        
        // If editing, find and select the current department
        if (widget.subject != null && widget.subject!.department != null) {
          try {
            _selectedDepartment = departments.firstWhere(
              (dept) => dept.name == widget.subject!.department,
            );
          } catch (e) {
            // If department not found, select first available
            _selectedDepartment = departments.isNotEmpty ? departments.first : null;
          }
        } else if (departments.isNotEmpty) {
          _selectedDepartment = departments.first;
        }
      });
    } catch (e) {
      print('Could not load departments: $e');
      setState(() {
        _departments = [];
        _selectedDepartment = null;
      });
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    _academicYearController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final subject = Subject(
        uid: widget.subject?.uid ?? '', // Let Firestore generate the UID
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        department: _selectedDepartment?.name,
        credits: int.tryParse(_creditsController.text.trim()),
        academicYear: _academicYearController.text.trim(),
        isActive: _isActive,
      );
      
      widget.onSubmit(subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subject' : 'Add New Subject'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subject Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject code is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Department and Credits Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingDepartments)
                          const Center(child: CircularProgressIndicator())
                        else if (_departments.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                'No departments available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<Department>(
                            value: _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'Department *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: _departments.map((Department department) {
                              return DropdownMenuItem<Department>(
                                value: department,
                                child: Text(
                                  department.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (Department? newValue) {
                              print('Department selected: ${newValue?.name}');
                              setState(() {
                                _selectedDepartment = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a department';
                              }
                              return null;
                            },
                            isExpanded: true,
                            menuMaxHeight: 200,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _creditsController,
                      decoration: const InputDecoration(
                        labelText: 'Credits',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final credits = int.tryParse(value);
                          if (credits == null || credits <= 0) {
                            return 'Credits must be a positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Academic Year
              TextFormField(
                controller: _academicYearController,
                decoration: InputDecoration(
                  labelText: 'Academic Year',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _isLoadingAcademicYear 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                  hintText: 'Loading current academic year...',
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Active Status
              SwitchListTile(
                title: const Text('Active Subject'),
                subtitle: const Text('Is this subject currently offered?'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Update Subject' : 'Add Subject'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (widget.onCancel != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
