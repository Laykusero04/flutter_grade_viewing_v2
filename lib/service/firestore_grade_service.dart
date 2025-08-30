import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/assignment.dart';

class FirestoreGradeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new grade for a student
  static Future<String> addGrade(Grade grade) async {
    try {
      final docRef = await _firestore.collection('grades').add(grade.toFirestoreMap());
      return docRef.id;
    } catch (e) {
      print('Error adding grade: $e');
      rethrow;
    }
  }

  /// Update an existing grade
  static Future<void> updateGrade(String gradeId, Grade grade) async {
    try {
      await _firestore
          .collection('grades')
          .doc(gradeId)
          .update(grade.toFirestoreMap());
    } catch (e) {
      print('Error updating grade: $e');
      rethrow;
    }
  }

  /// Delete a grade
  static Future<void> deleteGrade(String gradeId) async {
    try {
      await _firestore
          .collection('grades')
          .doc(gradeId)
          .delete();
    } catch (e) {
      print('Error deleting grade: $e');
      rethrow;
    }
  }

  /// Get all grades for a specific student in a subject
  static Future<List<Grade>> getStudentGrades(String studentId, String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .orderBy('dateRecorded', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Grade.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting student grades: $e');
      rethrow;
    }
  }

  /// Get all grades for a specific assignment
  static Future<List<Grade>> getAssignmentGrades(String assignmentName, String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('assignmentName', isEqualTo: assignmentName)
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Grade.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting assignment grades: $e');
      rethrow;
    }
  }

  /// Get all grades for a subject (for teacher view)
  static Future<List<Grade>> getSubjectGrades(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .orderBy('assignmentName')
          .orderBy('studentId')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return Grade.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error getting subject grades: $e');
      rethrow;
    }
  }

  /// Get a specific grade by ID
  static Future<Grade?> getGradeById(String gradeId) async {
    try {
      final doc = await _firestore
          .collection('grades')
          .doc(gradeId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return Grade.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting grade by ID: $e');
      rethrow;
    }
  }

  /// Bulk add grades for multiple students
  static Future<List<String>> bulkAddGrades(List<Grade> grades) async {
    try {
      final batch = _firestore.batch();
      final docRefs = <String>[];

      for (final grade in grades) {
        final docRef = _firestore.collection('grades').doc();
        batch.set(docRef, grade.toFirestoreMap());
        docRefs.add(docRef.id);
      }

      await batch.commit();
      return docRefs;
    } catch (e) {
      print('Error bulk adding grades: $e');
      rethrow;
    }
  }

  /// Get student's final grade for a subject
  static Future<double?> getStudentFinalGrade(String studentId, String subjectId) async {
    try {
      final grades = await getStudentGrades(studentId, subjectId);
      if (grades.isEmpty) return null;

      double totalWeightedScore = 0;
      double totalWeight = 0;

      for (final grade in grades) {
        final weight = grade.weight ?? 1.0;
        totalWeightedScore += (grade.score / grade.maxScore) * weight;
        totalWeight += weight;
      }

      if (totalWeight == 0) return null;
      return (totalWeightedScore / totalWeight) * 100;
    } catch (e) {
      print('Error calculating final grade: $e');
      return null;
    }
  }

  /// Get grade statistics for a subject
  static Future<Map<String, dynamic>> getSubjectGradeStats(String subjectId) async {
    try {
      final grades = await getSubjectGrades(subjectId);
      if (grades.isEmpty) {
        return {
          'totalStudents': 0,
          'averageScore': 0.0,
          'highestScore': 0.0,
          'lowestScore': 0.0,
        };
      }

      final scores = grades.map((g) => g.percentage).toList();
      final totalStudents = grades.map((g) => g.studentId).toSet().length;

      return {
        'totalStudents': totalStudents,
        'averageScore': scores.reduce((a, b) => a + b) / scores.length,
        'highestScore': scores.reduce((a, b) => a > b ? a : b),
        'lowestScore': scores.reduce((a, b) => a < b ? a : b),
      };
    } catch (e) {
      print('Error getting grade statistics: $e');
      rethrow;
    }
  }
}
