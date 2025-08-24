import 'package:flutter/material.dart';
import '../../components/widget/dear_v2_app_bar.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/academic_year.dart';
import '../../service/firestore_academic_year_service.dart';

class ManageAcademicYearsScreen extends StatefulWidget {
  const ManageAcademicYearsScreen({super.key});

  @override
  State<ManageAcademicYearsScreen> createState() => _ManageAcademicYearsScreenState();
}

class _ManageAcademicYearsScreenState extends State<ManageAcademicYearsScreen> {
  List<AcademicYear> _academicYears = [];
  AcademicYear? _activeAcademicYear;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
  }

  Future<void> _loadAcademicYears() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Clean up any invalid academic years first (for existing data)
      try {
        await FirestoreAcademicYearService.cleanupInvalidAcademicYears();
      } catch (e) {
        // If cleanup fails, continue anyway
        print('Cleanup warning: $e');
      }

      final academicYears = await FirestoreAcademicYearService.getAllAcademicYears();
      final activeYear = await FirestoreAcademicYearService.getActiveAcademicYear();

      // Sort academic years by endYear (descending), then by startYear (descending)
      academicYears.sort((a, b) {
        // First compare by endYear (newest first)
        if (a.endYear != b.endYear) {
          return b.endYear.compareTo(a.endYear);
        }
        // If endYear is the same, compare by startYear (newest first)
        return b.startYear.compareTo(a.startYear);
      });

      setState(() {
        _academicYears = academicYears;
        _activeAcademicYear = activeYear;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setActiveAcademicYear(String id) async {
    if (id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid academic year ID')),
        );
      }
      return;
    }

    try {
      await FirestoreAcademicYearService.setActiveAcademicYear(id);
      
      // Update local state without full refresh
      setState(() {
        // Deactivate all academic years first
        for (int i = 0; i < _academicYears.length; i++) {
          _academicYears[i] = _academicYears[i].copyWith(isActive: false);
        }
        
        // Activate the selected one
        final index = _academicYears.indexWhere((year) => year.id == id);
        if (index != -1) {
          _academicYears[index] = _academicYears[index].copyWith(isActive: true);
          _activeAcademicYear = _academicYears[index];
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active academic year updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update active academic year: $e')),
        );
      }
    }
  }

  Future<void> _deactivateAcademicYear(String id) async {
    print('Attempting to deactivate academic year with ID: "$id"');
    if (id.isEmpty) {
      print('ERROR: Academic year ID is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid academic year ID - please refresh the screen')),
        );
      }
      return;
    }

    try {
      await FirestoreAcademicYearService.updateAcademicYear(id, {'isActive': false});
      
      // Update local state without full refresh
      setState(() {
        final index = _academicYears.indexWhere((year) => year.id == id);
        if (index != -1) {
          _academicYears[index] = _academicYears[index].copyWith(isActive: false);
          // If this was the active academic year, clear it
          if (_activeAcademicYear?.id == id) {
            _activeAcademicYear = null;
          }
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Academic year deactivated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate academic year: $e')),
        );
      }
    }
  }

  Future<void> _deleteAcademicYear(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this academic year? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid academic year ID')),
          );
        }
        return;
      }

      try {
        await FirestoreAcademicYearService.deleteAcademicYear(id);
        await _loadAcademicYears();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Academic year deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete academic year: $e')),
          );
        }
      }
    }
  }

  void _showAddEditDialog([AcademicYear? academicYear]) {
    showDialog(
      context: context,
      builder: (context) => _AcademicYearDialog(
        academicYear: academicYear,
        onSaved: () {
          Navigator.of(context).pop();
          _loadAcademicYears();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DearV2AppBar(
        title: 'Manage Academic Years',
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: AppTextStyles.body),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAcademicYears,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      
                      // Academic Years List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Academic Years',
                            style: AppTextStyles.headline.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Academic Years List
                      Expanded(
                        child: _academicYears.isEmpty
                            ? Center(
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
                                      'No academic years found',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first academic year to get started',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _academicYears.length,
                                itemBuilder: (context, index) {
                                  final academicYear = _academicYears[index];
                                  final isActive = _activeAcademicYear?.id == academicYear.id;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                                                             leading: Switch(
                                         value: isActive,
                                         onChanged: (value) {
                                           if (value) {
                                             _setActiveAcademicYear(academicYear.id);
                                           } else {
                                             _deactivateAcademicYear(academicYear.id);
                                           }
                                         },
                                         activeColor: AppColor.primary,
                                       ),
                                                                                                                    title: Text(
                                         academicYear.displayName,
                                         style: AppTextStyles.body.copyWith(
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                       subtitle: Text(
                                         '${academicYear.startYear} - ${academicYear.endYear}',
                                         style: AppTextStyles.caption.copyWith(
                                           color: Colors.grey[600],
                                         ),
                                       ),
                                                                             trailing: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           IconButton(
                                             onPressed: () => _showAddEditDialog(academicYear),
                                             icon: const Icon(Icons.edit),
                                             tooltip: 'Edit',
                                           ),
                                           IconButton(
                                             onPressed: () => _deleteAcademicYear(academicYear.id),
                                             icon: const Icon(Icons.delete),
                                             tooltip: 'Delete',
                                             color: Colors.red,
                                           ),
                                         ],
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
}

class _AcademicYearDialog extends StatefulWidget {
  final AcademicYear? academicYear;
  final VoidCallback onSaved;

  const _AcademicYearDialog({
    this.academicYear,
    required this.onSaved,
  });

  @override
  State<_AcademicYearDialog> createState() => _AcademicYearDialogState();
}

class _AcademicYearDialogState extends State<_AcademicYearDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startYearController;
  late TextEditingController _endYearController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startYearController = TextEditingController(text: widget.academicYear?.startYear.toString() ?? DateTime.now().year.toString());
    _endYearController = TextEditingController(text: widget.academicYear?.endYear.toString() ?? (DateTime.now().year + 1).toString());
  }

  @override
  void dispose() {
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }



  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startYear = int.tryParse(_startYearController.text.trim()) ?? DateTime.now().year;
      final endYear = int.tryParse(_endYearController.text.trim()) ?? DateTime.now().year + 1;
      
      final academicYear = AcademicYear(
        id: widget.academicYear?.id ?? '',
        startYear: startYear,
        endYear: endYear,
        isActive: widget.academicYear?.isActive ?? false,
        createdAt: widget.academicYear?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.academicYear == null) {
        // Create new
        await FirestoreAcademicYearService.createAcademicYear(academicYear);
      } else {
        // Update existing - only pass the fields we want to update
        await FirestoreAcademicYearService.updateAcademicYear(
          widget.academicYear!.id,
          {
            'startYear': startYear,
            'endYear': endYear,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save academic year: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.academicYear == null ? 'Add Academic Year' : 'Edit Academic Year'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
                             Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _startYearController,
                       decoration: const InputDecoration(
                         labelText: 'Start Year *',
                         hintText: 'e.g., 2023',
                       ),
                       keyboardType: TextInputType.number,
                       validator: (value) {
                         if (value == null || value.trim().isEmpty) {
                           return 'Start year is required';
                         }
                         final year = int.tryParse(value.trim());
                         if (year == null || year < 2000 || year > 2100) {
                           return 'Please enter a valid year (2000-2100)';
                         }
                         return null;
                       },
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: TextFormField(
                       controller: _endYearController,
                       decoration: const InputDecoration(
                         labelText: 'End Year *',
                         hintText: 'e.g., 2024',
                       ),
                       keyboardType: TextInputType.number,
                       validator: (value) {
                         if (value == null || value.trim().isEmpty) {
                           return 'End year is required';
                         }
                         final year = int.tryParse(value.trim());
                         if (year == null || year < 2000 || year > 2100) {
                           return 'Please enter a valid year (2000-2100)';
                         }
                         final startYear = int.tryParse(_startYearController.text.trim());
                         if (startYear != null && year <= startYear) {
                           return 'End year must be after start year';
                         }
                         return null;
                       },
                     ),
                   ),
                 ],
               ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.academicYear == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
