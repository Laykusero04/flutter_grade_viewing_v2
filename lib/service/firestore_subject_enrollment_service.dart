import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class FirestoreSubjectEnrollmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all students enrolled in a specific subject
  static Future<List<Student>> getEnrolledStudents(String subjectId) async {
    try {
      final students = <Student>[];
      
      // Query the enrollments collection for the specific subject
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get all student IDs enrolled in this subject
        final studentIds = querySnapshot.docs
            .map((doc) => doc.data()['studentId'] as String)
            .toList();

        // Fetch the actual student documents
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
      }

      // Also check subject_teachers collection for QR enrollments
      final subjectTeachersQuery = await _firestore
          .collection('subject_teachers')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final subjectTeacherDoc in subjectTeachersQuery.docs) {
        try {
          // Get all enrolled students from the subcollection
          final enrolledStudentsSnapshot = await _firestore
              .collection('subject_teachers')
              .doc(subjectTeacherDoc.id)
              .collection('enrolled_students')
              .get();

          for (final enrolledStudentDoc in enrolledStudentsSnapshot.docs) {
            try {
              final enrollmentData = enrolledStudentDoc.data();
              
              // Try to get student from users collection first (since that's where student data is stored)
              final studentQuery = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: enrollmentData['studentEmail'])
                  .limit(1)
                  .get();

              if (studentQuery.docs.isNotEmpty) {
                final studentData = studentQuery.docs.first.data();
                // Add the document ID as uid to the map
                studentData['uid'] = studentQuery.docs.first.id;
                students.add(Student.fromMap(studentData));
              } else {
                // Fallback: create a student object from enrollment data
                final student = Student(
                  uid: enrollmentData['studentEmail'] ?? '',
                  firstName: enrollmentData['studentName']?.split(' ').first ?? '',
                  lastName: enrollmentData['studentName']?.split(' ').skip(1).join(' ') ?? '',
                  email: enrollmentData['studentEmail'] ?? '',
                  schoolId: enrollmentData['studentId'] ?? '',
                  userRole: 3, // Student role
                );
                students.add(student);
              }
            } catch (e) {
              print('Error processing enrolled student ${enrolledStudentDoc.id}: $e');
            }
          }
        } catch (e) {
          print('Error checking subject teacher ${subjectTeacherDoc.id}: $e');
        }
      }

      return students;
    } catch (e) {
      print('Error getting enrolled students: $e');
      rethrow;
    }
  }

  /// Get all subjects that a specific student is enrolled in
  static Future<List<Map<String, dynamic>>> getStudentEnrollments(String studentEmail) async {
    try {
      final List<Map<String, dynamic>> enrollments = [];

      // Get regular enrollments from main enrollments collection
      print('Checking regular enrollments for student: $studentEmail');
      final regularEnrollments = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentEmail)
          .where('status', isEqualTo: 'active')
          .get();
      print('Found ${regularEnrollments.docs.length} regular enrollments');

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
            final enrollmentData = {
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
            };
            print('Adding regular enrollment: ${enrollmentData['subjectName']} (${enrollmentData['subjectId']})');
            enrollments.add(enrollmentData);
          }
        } catch (e) {
          print('Error fetching subject ${data['subjectId']}: $e');
        }
      }

      // Get QR enrollments from subject_teachers subcollections
      print('Checking QR enrollments for student email: $studentEmail');
      final subjectTeachersQuery = await _firestore
          .collection('subject_teachers')
          .get();
      print('Found ${subjectTeachersQuery.docs.length} subject teachers');

      for (final subjectTeacherDoc in subjectTeachersQuery.docs) {
        try {
          final subjectTeacherData = subjectTeacherDoc.data();
          print('Checking subject teacher: ${subjectTeacherDoc.id}');
          print('Subject ID: ${subjectTeacherData['subjectId']}');
          print('Teacher ID: ${subjectTeacherData['teacherId']}');
          
          final enrolledStudentDoc = await _firestore
              .collection('subject_teachers')
              .doc(subjectTeacherDoc.id)
              .collection('enrolled_students')
              .doc(studentEmail)
              .get();

          print('Checking enrolled student document for: $studentEmail');
          print('Document exists: ${enrolledStudentDoc.exists}');
          
          if (enrolledStudentDoc.exists) {
            final enrollmentData = enrolledStudentDoc.data()!;
            final subjectTeacherData = subjectTeacherDoc.data();
            print('Enrollment data: $enrollmentData');
            
            // Get subject details from the subject_teachers document
            final subjectDoc = await _firestore
                .collection('subjects')
                .doc(subjectTeacherData['subjectId'])
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
              
              final qrEnrollmentData = {
                'enrollmentId': enrolledStudentDoc.id,
                'subjectId': subjectTeacherData['subjectId'],
                'subjectName': subjectData['name'],
                'subjectCode': subjectData['code'],
                'enrolledAt': enrollmentData['enrolledAt'],
                'enrolledVia': 'qr_code',
                'status': enrollmentData['status'] ?? 'active',
                'teacherId': subjectTeacherData['teacherId'],
                'teacherName': teacherName,
                'subjectTeacherId': subjectTeacherDoc.id,
              };
              print('Adding QR enrollment: ${qrEnrollmentData['subjectName']} (${qrEnrollmentData['subjectId']})');
              enrollments.add(qrEnrollmentData);
            }
          }
        } catch (e) {
          print('Error checking QR enrollment for ${subjectTeacherDoc.id}: $e');
        }
      }

      // Remove duplicates based on subjectId
      final uniqueEnrollments = <Map<String, dynamic>>[];
      final seenSubjectIds = <String>{};
      
      for (final enrollment in enrollments) {
        final subjectId = enrollment['subjectId'];
        if (!seenSubjectIds.contains(subjectId)) {
          seenSubjectIds.add(subjectId);
          uniqueEnrollments.add(enrollment);
        } else {
          print('Duplicate enrollment found for subject: $subjectId, skipping...');
        }
      }
      
      print('Total enrollments: ${enrollments.length}, Unique enrollments: ${uniqueEnrollments.length}');
      return uniqueEnrollments;
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

  /// Get all students enrolled in a specific subject with enrollment type information
  static Future<List<Map<String, dynamic>>> getEnrolledStudentsWithDetails(String subjectId) async {
    try {
      final enrollments = <Map<String, dynamic>>[];
      
      // Query the enrollments collection for the specific subject
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get all student IDs enrolled in this subject
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          try {
            final studentDoc = await _firestore
                .collection('students')
                .doc(data['studentId'])
                .get();

            if (studentDoc.exists) {
              final studentData = studentDoc.data()!;
              enrollments.add({
                'student': Student.fromMap({...studentData, 'uid': data['studentId']}),
                'enrollmentType': data['enrolledVia'] ?? 'regular',
                'enrolledAt': data['enrolledAt'],
                'status': data['status'] ?? 'active',
              });
            }
          } catch (e) {
            print('Error fetching student ${data['studentId']}: $e');
          }
        }
      }

      // Also check subject_teachers collection for QR enrollments
      final subjectTeachersQuery = await _firestore
          .collection('subject_teachers')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final subjectTeacherDoc in subjectTeachersQuery.docs) {
        try {
          // Get all enrolled students from the subcollection
          final enrolledStudentsSnapshot = await _firestore
              .collection('subject_teachers')
              .doc(subjectTeacherDoc.id)
              .collection('enrolled_students')
              .get();

          for (final enrolledStudentDoc in enrolledStudentsSnapshot.docs) {
            try {
              final enrollmentData = enrolledStudentDoc.data();
              
              // Try to get student from users collection first (since that's where student data is stored)
              final studentQuery = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: enrollmentData['studentEmail'])
                  .limit(1)
                  .get();

              if (studentQuery.docs.isNotEmpty) {
                final studentData = studentQuery.docs.first.data();
                // Add the document ID as uid to the map
                studentData['uid'] = studentQuery.docs.first.id;
                enrollments.add({
                  'student': Student.fromMap(studentData),
                  'enrollmentType': 'qr_code',
                  'enrolledAt': enrollmentData['enrolledAt'],
                  'status': enrollmentData['status'] ?? 'active',
                });
              } else {
                // Fallback: create a student object from enrollment data
                final student = Student(
                  uid: enrollmentData['studentEmail'] ?? '',
                  firstName: enrollmentData['studentName']?.split(' ').first ?? '',
                  lastName: enrollmentData['studentName']?.split(' ').skip(1).join(' ') ?? '',
                  email: enrollmentData['studentEmail'] ?? '',
                  schoolId: enrollmentData['studentId'] ?? '',
                  userRole: 3, // Student role
                );
                enrollments.add({
                  'student': student,
                  'enrollmentType': 'qr_code',
                  'enrolledAt': enrollmentData['enrolledAt'],
                  'status': enrollmentData['status'] ?? 'active',
                });
              }
            } catch (e) {
              print('Error processing enrolled student ${enrolledStudentDoc.id}: $e');
            }
          }
        } catch (e) {
          print('Error checking subject teacher ${subjectTeacherDoc.id}: $e');
        }
      }

      return enrollments;
    } catch (e) {
      print('Error getting enrolled students with details: $e');
      rethrow;
    }
  }
}
