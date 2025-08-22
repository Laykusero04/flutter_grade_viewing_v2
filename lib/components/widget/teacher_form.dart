import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/teacher.dart';

class TeacherForm extends StatefulWidget {
  final Teacher? teacher;
  final Function(Teacher) onSubmit;
  final VoidCallback? onCancel;

  const TeacherForm({
    super.key,
    this.teacher,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _employeeIdController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _departmentController;
  late TextEditingController _subjectController;
  late TextEditingController _qualificationController;
  late TextEditingController _addressController;
  
  late DateTime _selectedDateOfBirth;
  late DateTime _selectedHireDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final teacher = widget.teacher;
    _employeeIdController = TextEditingController(text: teacher?.employeeId ?? '');
    _firstNameController = TextEditingController(text: teacher?.firstName ?? '');
    _lastNameController = TextEditingController(text: teacher?.lastName ?? '');
    _emailController = TextEditingController(text: teacher?.email ?? '');
    _phoneController = TextEditingController(text: teacher?.phoneNumber ?? '');
    _departmentController = TextEditingController(text: teacher?.department ?? '');
    _subjectController = TextEditingController(text: teacher?.subject ?? '');
    _qualificationController = TextEditingController(text: teacher?.qualification ?? '');
    _addressController = TextEditingController(text: teacher?.address ?? '');
    
    _selectedDateOfBirth = teacher?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    _selectedHireDate = teacher?.hireDate ?? DateTime.now();
    _isActive = teacher?.isActive ?? true;
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _subjectController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDateOfBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? _selectedDateOfBirth : _selectedHireDate,
      firstDate: isDateOfBirth ? DateTime(1900) : DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _selectedDateOfBirth = picked;
        } else {
          _selectedHireDate = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final teacher = Teacher(
        uid: widget.teacher?.uid ?? _emailController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        userRole: 2, // Teacher role
        phoneNumber: _phoneController.text.trim(),
        department: _departmentController.text.trim(),
        subject: _subjectController.text.trim(),
        qualification: _qualificationController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        hireDate: _selectedHireDate,
        isActive: _isActive,
      );
      
      widget.onSubmit(teacher);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.teacher != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Teacher' : 'Add New Teacher'),
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
              // Employee ID
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'Employee ID *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Employee ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department and Subject Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Qualification
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(
                  labelText: 'Qualification',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    '${_selectedDateOfBirth.day}/${_selectedDateOfBirth.month}/${_selectedDateOfBirth.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hire Date
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hire Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  child: Text(
                    '${_selectedHireDate.day}/${_selectedHireDate.month}/${_selectedHireDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Active Status
              SwitchListTile(
                title: const Text('Active Teacher'),
                subtitle: const Text('Is this teacher currently employed?'),
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
                      label: Text(isEditing ? 'Update Teacher' : 'Add Teacher'),
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
