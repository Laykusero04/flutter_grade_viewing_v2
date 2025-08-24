import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class FirestoreSubjectTeacherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all subjects assigned to a specific teacher
  static Future<List<Subject>> getAssignedSubjects(String teacherId) async {
    try {
      // Query the subject_teachers collection for the specific teacher
      final querySnapshot = await _firestore
          .collection('subject_teachers')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Get all subject IDs assigned to this teacher
      final subjectIds = querySnapshot.docs
          .map((doc) => doc.data()['subjectId'] as String)
          .toList();

      // Fetch the actual subject documents
      final subjects = <Subject>[];
      for (final subjectId in subjectIds) {
        try {
          final subjectDoc = await _firestore
              .collection('subjects')
              .doc(subjectId)
              .get();

          if (subjectDoc.exists) {
            final subjectData = subjectDoc.data()!;
            // Add the document ID as uid to the map
            subjectData['uid'] = subjectId;
            subjects.add(Subject.fromMap(subjectData));
          }
        } catch (e) {
          print('Error fetching subject $subjectId: $e');
        }
      }

      return subjects;
    } catch (e) {
      print('Error getting assigned subjects: $e');
      rethrow;
    }
  }

  /// Get assignment details for a teacher
  static Future<List<Map<String, dynamic>>> getAssignmentDetails(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subject_teachers')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'assignmentId': doc.id,
          'subjectId': data['subjectId'],
          'assignedAt': data['assignedAt'],
          'assignedBy': data['assignedBy'],
        };
      }).toList();
    } catch (e) {
      print('Error getting assignment details: $e');
      rethrow;
    }
  }
}
