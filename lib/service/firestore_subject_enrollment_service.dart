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

  /// Get all subjects that a specific student is enrolled in
  static Future<List<Map<String, dynamic>>> getStudentEnrollments(String studentId) async {
    try {
      final List<Map<String, dynamic>> enrollments = [];

      // Get regular enrollments from main enrollments collection
      final regularEnrollments = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in regularEnrollments.docs) {
        final data = doc.data();
        try {
          // Get subject details
          final subjectDoc = await _firestore
              .collection('subjects')
              .doc(data['subjectId'])
              .get();

          if (subjectDoc.exists) {
            final subjectData = subjectDoc.data()!;
            // Get teacher details
            String teacherName = 'Unknown Teacher';
            if (data['teacherId'] != null) {
              try {
                // First try to find teacher by teacherId
                final teacherDoc = await _firestore
                    .collection('users')
                    .doc(data['teacherId'])
                    .get();
                
                if (teacherDoc.exists) {
                  final teacherData = teacherDoc.data()!;
                  final firstName = teacherData['firstName'] ?? '';
                  final lastName = teacherData['lastName'] ?? '';
                  teacherName = '$firstName $lastName'.trim();
                  if (teacherName.isEmpty) {
                    teacherName = 'Unknown Teacher';
                  }
                } else {
                  // If not found by teacherId, try to find by email (uid)
                  final teacherQuery = await _firestore
                      .collection('users')
                      .where('uid', isEqualTo: data['teacherId'])
                      .limit(1)
                      .get();
                  
                  if (teacherQuery.docs.isNotEmpty) {
                    final teacherData = teacherQuery.docs.first.data();
                    final firstName = teacherData['firstName'] ?? '';
                    final lastName = teacherData['lastName'] ?? '';
                    teacherName = '$firstName $lastName'.trim();
                    if (teacherName.isEmpty) {
                      teacherName = 'Unknown Teacher';
                    }
                  }
                }
              } catch (e) {
                print('Error fetching teacher ${data['teacherId']}: $e');
              }
            }
            enrollments.add({
              'enrollmentId': doc.id,
              'subjectId': data['subjectId'],
              'subjectName': subjectData['name'],
              'subjectCode': subjectData['code'],
              'enrolledAt': data['enrolledAt'],
              'enrolledVia': data['enrolledVia'] ?? 'regular',
              'status': data['status'] ?? 'active',
              'teacherId': data['teacherId'],
              'subjectTeacherId': data['subjectTeacherId'],
              'teacherName': teacherName,
            });
          }
        } catch (e) {
          print('Error fetching subject ${data['subjectId']}: $e');
        }
      }

      // Get QR enrollments from subject_teachers subcollections
      final subjectTeachersQuery = await _firestore
          .collection('subject_teachers')
          .get();

      for (final subjectTeacherDoc in subjectTeachersQuery.docs) {
        try {
          final enrolledStudentDoc = await _firestore
              .collection('subject_teachers')
              .doc(subjectTeacherDoc.id)
              .collection('enrolled_students')
              .doc(studentId)
              .get();

          if (enrolledStudentDoc.exists) {
            final enrollmentData = enrolledStudentDoc.data()!;
            
            // Get subject details
            final subjectDoc = await _firestore
                .collection('subjects')
                .doc(enrollmentData['subjectId'])
                .get();

            if (subjectDoc.exists) {
              final subjectData = subjectDoc.data()!;
              
              // Get teacher details from subject_teachers document
              String teacherName = 'Unknown Teacher';
              final subjectTeacherData = subjectTeacherDoc.data();
              if (subjectTeacherData['teacherId'] != null) {
                try {
                  // First try to find teacher by teacherId
                  final teacherDoc = await _firestore
                      .collection('users')
                      .doc(subjectTeacherData['teacherId'])
                      .get();
                  
                  if (teacherDoc.exists) {
                    final teacherData = teacherDoc.data()!;
                    final firstName = teacherData['firstName'] ?? '';
                    final lastName = teacherData['lastName'] ?? '';
                    teacherName = '$firstName $lastName'.trim();
                    if (teacherName.isEmpty) {
                      teacherName = 'Unknown Teacher';
                    }
                  } else {
                    // If not found by teacherId, try to find by email (uid)
                    final teacherQuery = await _firestore
                        .collection('users')
                        .where('uid', isEqualTo: subjectTeacherData['teacherId'])
                        .limit(1)
                        .get();
                    
                    if (teacherQuery.docs.isNotEmpty) {
                      final teacherData = teacherQuery.docs.first.data();
                      final firstName = teacherData['firstName'] ?? '';
                      final lastName = teacherData['lastName'] ?? '';
                      teacherName = '$firstName $lastName'.trim();
                      if (teacherName.isEmpty) {
                        teacherName = 'Unknown Teacher';
                      }
                    }
                  }
                } catch (e) {
                  print('Error fetching teacher ${subjectTeacherData['teacherId']}: $e');
                }
              }
              
              enrollments.add({
                'enrollmentId': enrolledStudentDoc.id,
                'subjectId': enrollmentData['subjectId'],
                'subjectName': subjectData['name'],
                'subjectCode': subjectData['code'],
                'enrolledAt': enrollmentData['enrolledAt'],
                'enrolledVia': 'qr_code',
                'status': enrollmentData['status'] ?? 'active',
                'teacherId': subjectTeacherData['teacherId'],
                'teacherName': teacherName,
                'subjectTeacherId': subjectTeacherDoc.id,
              });
            }
          }
        } catch (e) {
          print('Error checking QR enrollment for ${subjectTeacherDoc.id}: $e');
        }
      }

      return enrollments;
    } catch (e) {
      print('Error getting student enrollments: $e');
      return [];
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
