import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject.dart';
import '../models/teacher.dart';

class FirestoreSubjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _subjectsCollection = 'subjects';
  static const String _subjectTeachersCollection = 'subject_teachers';

  // Get all subjects
  static Future<List<Subject>> getAllSubjects() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectsCollection)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Subject.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  // Get subject by UID
  static Future<Subject?> getSubjectById(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_subjectsCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return Subject.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'uid': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch subject: $e');
    }
  }

  // Add new subject
  static Future<String> addSubject(Subject subject) async {
    try {
      // Use toFirestoreMap() to avoid saving uid field in document data
      final DocumentReference docRef = await _firestore
          .collection(_subjectsCollection)
          .add(subject.toFirestoreMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add subject: $e');
    }
  }

  // Update existing subject
  static Future<bool> updateSubject(Subject subject) async {
    try {
      // Use toFirestoreMap() to avoid saving uid field in document data
      await _firestore
          .collection(_subjectsCollection)
          .doc(subject.uid)
          .update(subject.toFirestoreMap());
      return true;
    } catch (e) {
      throw Exception('Failed to update subject: $e');
    }
  }

  // Delete subject
  static Future<bool> deleteSubject(String uid) async {
    try {
      await _firestore
          .collection(_subjectsCollection)
          .doc(uid)
          .delete();
      
      // Also delete related teacher assignments
      await _deleteSubjectTeacherAssignments(uid);
      
      return true;
    } catch (e) {
      throw Exception('Failed to delete subject: $e');
    }
  }

  // Search subjects
  static Future<List<Subject>> searchSubjects(String query) async {
    try {
      if (query.isEmpty) {
        return getAllSubjects();
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectsCollection)
          .get();

      final subjects = querySnapshot.docs
          .map((doc) => Subject.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();

      query = query.toLowerCase();
      return subjects.where((subject) {
        return subject.name.toLowerCase().contains(query) ||
               subject.code.toLowerCase().contains(query) ||
               (subject.department?.toLowerCase().contains(query) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search subjects: $e');
    }
  }

  // Get teachers assigned to a subject
  static Future<List<Teacher>> getSubjectTeachers(String subjectId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectTeachersCollection)
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final List<Teacher> teachers = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teacherId = data['teacherId'] as String;
        
        // Get teacher details from users collection
        final teacherDoc = await _firestore
            .collection('users')
            .doc(teacherId)
            .get();
            
        if (teacherDoc.exists) {
          final teacherData = teacherDoc.data() as Map<String, dynamic>;
          if (teacherData['userRole'] == 2) { // Teacher role
            teachers.add(Teacher.fromMap({
              ...teacherData,
              'uid': teacherId,
            }));
          }
        }
      }
      
      return teachers;
    } catch (e) {
      throw Exception('Failed to fetch subject teachers: $e');
    }
  }

  // Assign teacher to subject
  static Future<bool> assignTeacherToSubject(String subjectId, String teacherId) async {
    try {
      // Check if assignment already exists
      final QuerySnapshot existingAssignment = await _firestore
          .collection(_subjectTeachersCollection)
          .where('subjectId', isEqualTo: subjectId)
          .where('teacherId', isEqualTo: teacherId)
          .limit(1)
          .get();

      if (existingAssignment.docs.isNotEmpty) {
        throw Exception('Teacher is already assigned to this subject');
      }

      // Add new assignment
      await _firestore
          .collection(_subjectTeachersCollection)
          .add({
            'subjectId': subjectId,
            'teacherId': teacherId,
            'assignedAt': FieldValue.serverTimestamp(),
            'assignedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin', // Fallback if no current user
          });

      return true;
    } catch (e) {
      throw Exception('Failed to assign teacher: $e');
    }
  }

  // Remove teacher from subject
  static Future<bool> removeTeacherFromSubject(String subjectId, String teacherId) async {
    try {
      final QuerySnapshot assignmentQuery = await _firestore
          .collection(_subjectTeachersCollection)
          .where('subjectId', isEqualTo: subjectId)
          .where('teacherId', isEqualTo: teacherId)
          .get();

      if (assignmentQuery.docs.isNotEmpty) {
        await assignmentQuery.docs.first.reference.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to remove teacher: $e');
    }
  }

  // Get available teachers (not assigned to this subject)
  static Future<List<Teacher>> getAvailableTeachers(String subjectId) async {
    try {
      // Get all teachers
      final QuerySnapshot allTeachersQuery = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: 2)
          .get();

      final List<Teacher> allTeachers = allTeachersQuery.docs
          .map((doc) => Teacher.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();

      // Get assigned teachers for this subject
      final List<Teacher> assignedTeachers = await getSubjectTeachers(subjectId);
      
      // Filter out already assigned teachers
      final assignedTeacherIds = assignedTeachers.map((t) => t.uid).toSet();
      return allTeachers.where((teacher) => !assignedTeacherIds.contains(teacher.uid)).toList();
    } catch (e) {
      throw Exception('Failed to fetch available teachers: $e');
    }
  }

  // Delete all teacher assignments for a subject
  static Future<void> _deleteSubjectTeacherAssignments(String subjectId) async {
    try {
      final QuerySnapshot assignments = await _firestore
          .collection(_subjectTeachersCollection)
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final batch = _firestore.batch();
      for (final doc in assignments.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Log error but don't throw, as this is cleanup operation
    }
  }

  // Check if subject exists by code
  static Future<bool> subjectExists(String code) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectsCollection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get subjects count
  static Future<int> getSubjectsCount() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectsCollection)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clean up existing subjects by removing the uid field from document data
  /// This fixes the issue where uid was being saved as a field instead of using document ID
  static Future<void> cleanupSubjectUidFields() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_subjectsCollection)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if the document has a uid field that's not empty
        if (data.containsKey('uid') && data['uid'] != null && data['uid'].toString().isNotEmpty) {
          // Remove the uid field from the document data
          data.remove('uid');
          
          // Update the document to remove the uid field
          batch.update(doc.reference, data);
        }
      }
      
      // Commit the batch if there are operations
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup subject UID fields: $e');
    }
  }
}
