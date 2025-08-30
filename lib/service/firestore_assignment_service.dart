import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';

class FirestoreAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new assignment
  static Future<String> createAssignment(Assignment assignment) async {
    try {
      final docRef = await _firestore.collection('assignments').add(assignment.toFirestoreMap());
      return docRef.id;
    } catch (e) {
      print('Error creating assignment: $e');
      rethrow;
    }
  }

  /// Update an existing assignment
  static Future<void> updateAssignment(String assignmentId, Assignment assignment) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update(assignment.toFirestoreMap());
    } catch (e) {
      print('Error updating assignment: $e');
      rethrow;
    }
  }

  /// Delete an assignment
  static Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .delete();
    } catch (e) {
      print('Error deleting assignment: $e');
      rethrow;
    }
  }

  /// Get all assignments for a specific subject
  static Future<List<Assignment>> getSubjectAssignments(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .orderBy('dateCreated', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Assignment.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting subject assignments: $e');
      rethrow;
    }
  }

  /// Get all assignments created by a specific teacher
  static Future<List<Assignment>> getTeacherAssignments(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('dateCreated', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Assignment.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting teacher assignments: $e');
      rethrow;
    }
  }

  /// Get a specific assignment by ID
  static Future<Assignment?> getAssignmentById(String assignmentId) async {
    try {
      final doc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return Assignment.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting assignment by ID: $e');
      rethrow;
    }
  }

  /// Get assignments by grade type
  static Future<List<Assignment>> getAssignmentsByType(String subjectId, String gradeType) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .where('gradeType', isEqualTo: gradeType)
          .where('isActive', isEqualTo: true)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Assignment.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting assignments by type: $e');
      rethrow;
    }
  }

  /// Get upcoming assignments (due date in the future)
  static Future<List<Assignment>> getUpcomingAssignments(String subjectId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .where('dueDate', isGreaterThan: now)
          .where('isActive', isEqualTo: true)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Assignment.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting upcoming assignments: $e');
      rethrow;
    }
  }

  /// Get past assignments (due date in the past)
  static Future<List<Assignment>> getPastAssignments(String subjectId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .where('dueDate', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .orderBy('dueDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Assignment.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting past assignments: $e');
      rethrow;
    }
  }

  /// Get assignment statistics for a subject
  static Future<Map<String, dynamic>> getAssignmentStats(String subjectId) async {
    try {
      final assignments = await getSubjectAssignments(subjectId);
      if (assignments.isEmpty) {
        return {
          'totalAssignments': 0,
          'totalWeight': 0.0,
          'averageWeight': 0.0,
          'types': <String, int>{},
        };
      }

      final totalWeight = assignments.fold(0.0, (sum, a) => sum + a.weight);
      final types = <String, int>{};
      
      for (final assignment in assignments) {
        types[assignment.gradeType] = (types[assignment.gradeType] ?? 0) + 1;
      }

      return {
        'totalAssignments': assignments.length,
        'totalWeight': totalWeight,
        'averageWeight': totalWeight / assignments.length,
        'types': types,
      };
    } catch (e) {
      print('Error getting assignment statistics: $e');
      rethrow;
    }
  }
}
