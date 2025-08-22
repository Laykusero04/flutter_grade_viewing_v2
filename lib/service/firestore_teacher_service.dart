import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';

class FirestoreTeacherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  // Get all teachers (users with userRole = 2)
  static Future<List<Teacher>> getAllTeachers() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 2)
          .get();

      return querySnapshot.docs
          .map((doc) => Teacher.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  // Get teacher by UID
  static Future<Teacher?> getTeacherById(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userRole'] == 2) {
          return Teacher.fromMap({
            ...data,
            'uid': doc.id,
          });
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch teacher: $e');
    }
  }

  // Add new teacher
  static Future<bool> addTeacher(Teacher teacher) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(teacher.uid)
          .set(teacher.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to add teacher: $e');
    }
  }

  // Update existing teacher
  static Future<bool> updateTeacher(Teacher teacher) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(teacher.uid)
          .update(teacher.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  // Delete teacher
  static Future<bool> deleteTeacher(String uid) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  // Search teachers
  static Future<List<Teacher>> searchTeachers(String query) async {
    try {
      if (query.isEmpty) {
        return getAllTeachers();
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 2)
          .get();

      final teachers = querySnapshot.docs
          .map((doc) => Teacher.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();

      query = query.toLowerCase();
      return teachers.where((teacher) {
        return teacher.firstName.toLowerCase().contains(query) ||
               teacher.lastName.toLowerCase().contains(query) ||
               teacher.employeeId.toLowerCase().contains(query) ||
               teacher.email.toLowerCase().contains(query) ||
               (teacher.department?.toLowerCase().contains(query) ?? false) ||
               (teacher.subject?.toLowerCase().contains(query) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search teachers: $e');
    }
  }

  // Check if a teacher exists by email
  static Future<bool> teacherExists(String email) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .where('userRole', isEqualTo: 2)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get teachers count
  static Future<int> getTeachersCount() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userRole', isEqualTo: 2)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
