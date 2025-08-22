import 'package:flutter/material.dart';
import '../../models/teacher.dart';

class TeacherDetailView extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TeacherDetailView({
    super.key,
    required this.teacher,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit Teacher',
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: Colors.red[200],
              tooltip: 'Delete Teacher',
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
                        teacher.firstName[0] + teacher.lastName[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Teacher Name
                    Text(
                      teacher.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Employee ID
                    Text(
                      teacher.employeeId,
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
                        color: (teacher.isActive ?? true) ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (teacher.isActive ?? true) ? 'Active Teacher' : 'Inactive Teacher',
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
                  label: const Text('Edit Teacher Information', style: TextStyle(fontSize: 16)),
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
                _buildInfoRow('First Name', teacher.firstName),
                _buildInfoRow('Last Name', teacher.lastName),
                _buildInfoRow('Date of Birth', _formatDate(teacher.dateOfBirth)),
                _buildInfoRow('Email', teacher.email),
                _buildInfoRow('Phone Number', teacher.phoneNumber ?? 'N/A'),
                _buildInfoRow('Address', teacher.address ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 20),

            // Professional Information
            _buildSection(
              context,
              title: 'Professional Information',
              icon: Icons.work,
              children: [
                _buildInfoRow('Department', teacher.department ?? 'N/A'),
                _buildInfoRow('Subject', teacher.subject ?? 'N/A'),
                _buildInfoRow('Qualification', teacher.qualification ?? 'N/A'),
                _buildInfoRow('Hire Date', _formatDate(teacher.hireDate)),
              ],
            ),
            const SizedBox(height: 20),

            // Additional Information
            if (teacher.additionalInfo.isNotEmpty)
              _buildSection(
                context,
                title: 'Additional Information',
                icon: Icons.info,
                children: teacher.additionalInfo.entries.map((entry) {
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
