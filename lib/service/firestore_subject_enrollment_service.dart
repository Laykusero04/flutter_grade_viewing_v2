import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class FirestoreSubjectEnrollmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all students enrolled in a specific subject
  static Future<List<Student>> getEnrolledStudents(String subjectId) async {
    try {
      // Query the enrollments collection for the specific subject
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Get all student IDs enrolled in this subject
      final studentIds = querySnapshot.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toList();

      // Fetch the actual student documents
      final students = <Student>[];
      for (final studentId in studentIds) {
        try {
          final studentDoc = await _firestore
              .collection('students')
              .doc(studentId)
              .get();

          if (studentDoc.exists) {
            final studentData = studentDoc.data()!;
            // Add the document ID as uid to the map
            studentData['uid'] = studentId;
            students.add(Student.fromMap(studentData));
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }

      return students;
    } catch (e) {
      print('Error getting enrolled students: $e');
      rethrow;
    }
  }

  /// Get enrollment details for a subject
  static Future<List<Map<String, dynamic>>> getEnrollmentDetails(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'enrollmentId': doc.id,
          'studentId': data['studentId'],
          'enrolledAt': data['enrolledAt'],
          'status': data['status'] ?? 'active',
        };
      }).toList();
    } catch (e) {
      print('Error getting enrollment details: $e');
      rethrow;
    }
  }
}
