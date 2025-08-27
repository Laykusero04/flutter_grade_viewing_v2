import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_session.dart';

class FirestoreSubjectTeacherQRService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create QR session for a subject-teacher assignment
  /// This creates a stable QR code based on the existing assignment
  static Future<QRSession> getOrCreateQRSession({
    required String subjectTeacherId,
    required String teacherId,
    required String subjectId,
    required DateTime assignedAt,
  }) async {
    try {
      // Check if QR session already exists for this assignment
      final qrDoc = await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .get();

      if (qrDoc.exists) {
        // Return existing QR session
        final data = qrDoc.data()!;
        return QRSession.fromMap({
          'subjectTeacherId': subjectTeacherId,
          'teacherId': teacherId,
          'subjectId': subjectId,
          'assignedAt': data['assignedAt'],
          'isActive': data['isActive'] ?? true,
          'maxEnrollments': data['maxEnrollments'] ?? 50,
          'currentEnrollments': data['currentEnrollments'] ?? 0,
        });
      } else {
        // Create new QR session
        final qrSession = QRSession(
          subjectTeacherId: subjectTeacherId,
          teacherId: teacherId,
          subjectId: subjectId,
          assignedAt: assignedAt,
          isActive: true,
          maxEnrollments: 50,
          currentEnrollments: 0,
        );

        // Save to qr_info subcollection
        await _firestore
            .collection('subject_teachers')
            .doc(subjectTeacherId)
            .collection('qr_info')
            .doc('enrollment')
            .set(qrSession.toMap());

        return qrSession;
      }
    } catch (e) {
      print('Error getting/creating QR session: $e');
      rethrow;
    }
  }

  /// Enroll a student in a subject via QR code
  static Future<Map<String, dynamic>> enrollStudent({
    required String subjectTeacherId,
    required String studentId,
    required String studentEmail,
    required String studentName,
  }) async {
    try {
      // Check if student is already enrolled
      final existingEnrollment = await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('enrolled_students')
          .doc(studentId)
          .get();

      if (existingEnrollment.exists) {
        return {'success': false, 'error': 'Student is already enrolled in this subject'};
      }

      // Get QR session info
      final qrDoc = await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .get();

      if (!qrDoc.exists) {
        return {'success': false, 'error': 'QR session not found'};
      }

      final qrData = qrDoc.data()!;
      final currentEnrollments = qrData['currentEnrollments'] ?? 0;
      final maxEnrollments = qrData['maxEnrollments'] ?? 50;

      if (currentEnrollments >= maxEnrollments) {
        return {'success': false, 'error': 'Enrollment limit reached for this subject'};
      }

      // Add student to enrolled_students subcollection
      final enrollmentData = {
        'studentId': studentId,
        'studentEmail': studentEmail,
        'studentName': studentName,
        'enrolledAt': FieldValue.serverTimestamp(),
        'enrolledVia': 'qr_code',
        'status': 'active',
      };

      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('enrolled_students')
          .doc(studentId)
          .set(enrollmentData);

      // Update enrollment count
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({
        'currentEnrollments': currentEnrollments + 1,
      });

      // Also add to main enrollments collection for compatibility
      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'studentEmail': studentEmail,
        'subjectId': qrData['subjectId'],
        'teacherId': qrData['teacherId'],
        'enrolledAt': FieldValue.serverTimestamp(),
        'enrolledVia': 'qr_code',
        'subjectTeacherId': subjectTeacherId,
        'status': 'active',
      });

      return {
        'success': true,
        'message': 'Successfully enrolled in subject',
      };
    } catch (e) {
      print('Error enrolling student: $e');
      return {'success': false, 'error': 'Failed to enroll: $e'};
    }
  }

  /// Get enrolled students for a subject-teacher assignment
  static Future<List<Map<String, dynamic>>> getEnrolledStudents(String subjectTeacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('enrolled_students')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'studentId': doc.id,
          'studentEmail': data['studentEmail'],
          'studentName': data['studentName'],
          'enrolledAt': data['enrolledAt'],
          'enrolledVia': data['enrolledVia'],
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      print('Error getting enrolled students: $e');
      return [];
    }
  }

  /// Get QR session info for a subject-teacher assignment
  static Future<QRSession?> getQRSession(String subjectTeacherId) async {
    try {
      final doc = await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return QRSession.fromMap({
          'subjectTeacherId': subjectTeacherId,
          'teacherId': data['teacherId'],
          'subjectId': data['subjectId'],
          'assignedAt': data['assignedAt'],
          'isActive': data['isActive'] ?? true,
          'maxEnrollments': data['maxEnrollments'] ?? 50,
          'currentEnrollments': data['currentEnrollments'] ?? 0,
        });
      }
      return null;
    } catch (e) {
      print('Error getting QR session: $e');
      return null;
    }
  }

  /// Deactivate QR enrollment for a subject
  static Future<bool> deactivateQREnrollment(String subjectTeacherId) async {
    try {
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({'isActive': false});
      return true;
    } catch (e) {
      print('Error deactivating QR enrollment: $e');
      return false;
    }
  }

  /// Reactivate QR enrollment for a subject
  static Future<bool> reactivateQREnrollment(String subjectTeacherId) async {
    try {
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({'isActive': true});
      return true;
    } catch (e) {
      print('Error reactivating QR enrollment: $e');
      return false;
    }
  }

  /// Update enrollment limits
  static Future<bool> updateEnrollmentLimits({
    required String subjectTeacherId,
    required int maxEnrollments,
  }) async {
    try {
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({'maxEnrollments': maxEnrollments});
      return true;
    } catch (e) {
      print('Error updating enrollment limits: $e');
      return false;
    }
  }

  /// Toggle QR enrollment status between active and inactive
  /// Returns the new status after toggling
  static Future<bool?> toggleQREnrollmentStatus(String subjectTeacherId) async {
    try {
      // Get current status first
      final currentSession = await getQRSession(subjectTeacherId);
      if (currentSession == null) {
        print('QR session not found for toggling');
        return null;
      }

      // Toggle the status
      final newStatus = !currentSession.isActive;
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({'isActive': newStatus});

      return newStatus;
    } catch (e) {
      print('Error toggling QR enrollment status: $e');
      return null;
    }
  }

  /// Get current QR enrollment status
  /// Returns true if active, false if inactive, null if not found
  static Future<bool?> getQREnrollmentStatus(String subjectTeacherId) async {
    try {
      final session = await getQRSession(subjectTeacherId);
      return session?.isActive;
    } catch (e) {
      print('Error getting QR enrollment status: $e');
      return null;
    }
  }

  /// Set QR enrollment status to a specific value
  /// Useful for setting to true/false without toggling
  static Future<bool> setQREnrollmentStatus({
    required String subjectTeacherId,
    required bool isActive,
  }) async {
    try {
      await _firestore
          .collection('subject_teachers')
          .doc(subjectTeacherId)
          .collection('qr_info')
          .doc('enrollment')
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Error setting QR enrollment status: $e');
      return false;
    }
  }
}
