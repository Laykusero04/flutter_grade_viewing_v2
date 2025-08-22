import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class FirestoreStudentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  // Get all students (users with userRole = 3)
  static Future<List<Student>> getAllStudents() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 3)
          .get();

      return querySnapshot.docs
          .map((doc) => Student.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Get student by UID
  static Future<Student?> getStudentById(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userRole'] == 3) {
          return Student.fromMap({
            ...data,
            'uid': doc.id,
          });
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  // Add new student
  static Future<bool> addStudent(Student student) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(student.uid)
          .set(student.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to add student: $e');
    }
  }

  // Update existing student
  static Future<bool> updateStudent(Student student) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(student.uid)
          .update(student.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete student
  static Future<bool> deleteStudent(String uid) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Search students
  static Future<List<Student>> searchStudents(String query) async {
    try {
      if (query.isEmpty) {
        return getAllStudents();
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 3)
          .get();

      final students = querySnapshot.docs
          .map((doc) => Student.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();

      query = query.toLowerCase();
      return students.where((student) {
        return student.firstName.toLowerCase().contains(query) ||
               student.lastName.toLowerCase().contains(query) ||
               student.schoolId.toLowerCase().contains(query) ||
               student.email.toLowerCase().contains(query) ||
               (student.grade?.toLowerCase().contains(query) ?? false) ||
               (student.section?.toLowerCase().contains(query) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search students: $e');
    }
  }

  // Check if a student exists by email
  static Future<bool> studentExists(String email) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .where('userRole', isEqualTo: 3)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get students count
  static Future<int> getStudentsCount() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 3)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
