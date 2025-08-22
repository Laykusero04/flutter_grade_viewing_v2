import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/student.dart';

class StudentListItem extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const StudentListItem({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
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
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: BorderRadius.zero,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.firstName[0] + student.lastName[0],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Student Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (student.isActive ?? true) ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (student.isActive ?? true) ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Student ID
                      Text(
                        'ID: ${student.schoolId}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Contact Info
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              student.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Academic Info
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatYear(student.grade)} • Section ${student.section ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
