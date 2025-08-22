import 'package:flutter/material.dart';
import '../../models/student.dart';

class StudentDetailView extends StatelessWidget {
  final Student student;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StudentDetailView({
    super.key,
    required this.student,
    this.onEdit,
    this.onDelete,
  });

  String _formatYear(String? year) {
    if (year == null || year.isEmpty) return 'N/A';
    
    try {
      final yearNum = int.parse(year);
      if (yearNum == 1) return '1st Year';
      if (yearNum == 2) return '2nd Year';
      if (yearNum == 3) return '3rd Year';
      if (yearNum >= 4) return '${yearNum}th Year';
      return year;
    } catch (e) {
      return year;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit Student',
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: Colors.red[200],
              tooltip: 'Delete Student',
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                    // Profile Icon
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        student.firstName[0] + student.lastName[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Name
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Student ID
                    Text(
                      student.schoolId,
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
                        color: (student.isActive ?? true) ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (student.isActive ?? true) ? 'Active Student' : 'Inactive Student',
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
            if (onEdit != null)
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit Student Information', style: TextStyle(fontSize: 16)),
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
            if (onEdit != null) const SizedBox(height: 20),

            // Personal Information
            _buildSection(
              context,
              title: 'Personal Information',
              icon: Icons.person,
              children: [
                _buildInfoRow('First Name', student.firstName),
                _buildInfoRow('Last Name', student.lastName),
                _buildInfoRow('Date of Birth', _formatDate(student.dateOfBirth)),
                _buildInfoRow('Email', student.email),
                _buildInfoRow('Phone Number', student.phoneNumber ?? 'N/A'),
                _buildInfoRow('Address', student.address ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 20),

            // Academic Information
            _buildSection(
              context,
              title: 'Academic Information',
              icon: Icons.school,
              children: [
                _buildInfoRow('Year', _formatYear(student.grade)),
                _buildInfoRow('Section', student.section ?? 'N/A'),
                _buildInfoRow('Academic Year', student.academicYear ?? 'N/A'),
                _buildInfoRow('Enrollment Date', _formatDate(student.enrollmentDate)),
              ],
            ),
            const SizedBox(height: 20),

            // Parent/Guardian Information
            _buildSection(
              context,
              title: 'Parent/Guardian Information',
              icon: Icons.family_restroom,
              children: [
                _buildInfoRow('Name', student.parentName ?? 'N/A'),
                _buildInfoRow('Phone Number', student.parentPhone ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 20),

            // Additional Information
            if (student.additionalInfo.isNotEmpty)
              _buildSection(
                context,
                title: 'Additional Information',
                icon: Icons.info,
                children: student.additionalInfo.entries.map((entry) {
                  return _buildInfoRow(entry.key, entry.value.toString());
                }).toList(),
              ),
          ],
        ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
