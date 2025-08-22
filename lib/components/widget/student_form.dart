import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/student.dart';

class StudentForm extends StatefulWidget {
  final Student? student;
  final Function(Student) onSubmit;
  final VoidCallback? onCancel;

  const StudentForm({
    super.key,
    this.student,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _studentIdController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _gradeController;
  late TextEditingController _sectionController;
  late TextEditingController _academicYearController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _addressController;
  
  late DateTime _selectedDateOfBirth;
  late DateTime _selectedEnrollmentDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final student = widget.student;
    _studentIdController = TextEditingController(text: student?.schoolId ?? '');
    _firstNameController = TextEditingController(text: student?.firstName ?? '');
    _lastNameController = TextEditingController(text: student?.lastName ?? '');
    _emailController = TextEditingController(text: student?.email ?? '');
    _phoneController = TextEditingController(text: student?.phoneNumber ?? '');
    _gradeController = TextEditingController(text: student?.grade ?? '');
    _sectionController = TextEditingController(text: student?.section ?? '');
    _academicYearController = TextEditingController(text: student?.academicYear ?? '');
    _parentNameController = TextEditingController(text: student?.parentName ?? '');
    _parentPhoneController = TextEditingController(text: student?.parentPhone ?? '');
    _addressController = TextEditingController(text: student?.address ?? '');
    
    _selectedDateOfBirth = student?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 16));
    _selectedEnrollmentDate = student?.enrollmentDate ?? DateTime.now();
    _isActive = student?.isActive ?? true;
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _sectionController.dispose();
    _academicYearController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDateOfBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? _selectedDateOfBirth : _selectedEnrollmentDate,
      firstDate: isDateOfBirth ? DateTime(1900) : DateTime(2000),
      lastDate: isDateOfBirth ? DateTime.now() : DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _selectedDateOfBirth = picked;
        } else {
          _selectedEnrollmentDate = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final student = Student(
        uid: widget.student?.uid ?? _emailController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        schoolId: _studentIdController.text.trim(),
        userRole: 3, // Student role
        phoneNumber: _phoneController.text.trim(),
        grade: _gradeController.text.trim(),
        section: _sectionController.text.trim(),
        academicYear: _academicYearController.text.trim(),
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        enrollmentDate: _selectedEnrollmentDate,
        isActive: _isActive,
      );
      
      widget.onSubmit(student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
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
                             // School ID
               TextFormField(
                 controller: _studentIdController,
                 decoration: const InputDecoration(
                   labelText: 'School ID *',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.badge),
                 ),
                 validator: (value) {
                   if (value == null || value.trim().isEmpty) {
                     return 'School ID is required';
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
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Grade and Section Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Year *',
                        hintText: 'Enter year (e.g., 1, 2, 3, 4)',
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Year is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Section is required';
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
                decoration: const InputDecoration(
                  labelText: 'Academic Year *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Academic year is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
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

              // Enrollment Date
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Date *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  child: Text(
                    '${_selectedEnrollmentDate.day}/${_selectedEnrollmentDate.month}/${_selectedEnrollmentDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Parent Name
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Parent/Guardian Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Parent/Guardian name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Parent Phone
              TextFormField(
                controller: _parentPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Parent/Guardian Phone *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Parent/Guardian phone is required';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Active Status
              SwitchListTile(
                title: const Text('Active Student'),
                subtitle: const Text('Is this student currently enrolled?'),
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
                      label: Text(isEditing ? 'Update Student' : 'Add Student'),
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
