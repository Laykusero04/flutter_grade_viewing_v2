import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'base_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = BaseService.firestore;

  // Get user by email
  static Future<AppUser?> getUserByEmail(String email) async {
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        return AppUser.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  // Get user by UID
  static Future<AppUser?> getUserByUid(String uid) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        return AppUser.fromMap(userQuery.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by UID: $e');
    }
  }

  // Get users by role
  static Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: role)
          .get();
      
      return userQuery.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  // Get all users
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final userQuery = await _firestore.collection('users').get();
      
      return userQuery.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Create new user
  static Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Search users by name
  static Future<List<AppUser>> searchUsersByName(String searchTerm) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('firstName', isGreaterThanOrEqualTo: searchTerm)
          .where('firstName', isLessThan: searchTerm + '\uf8ff')
          .get();
      
      final lastNameQuery = await _firestore
          .collection('users')
          .where('lastName', isGreaterThanOrEqualTo: searchTerm)
          .where('lastName', isLessThan: searchTerm + '\uf8ff')
          .get();
      
      final allDocs = [...userQuery.docs, ...lastNameQuery.docs];
      final uniqueDocs = allDocs.toSet().toList();
      
      return uniqueDocs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users by name: $e');
    }
  }

  // Get users count by role
  static Future<int> getUsersCountByRole(String role) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: role)
          .get();
      
      return userQuery.docs.length;
    } catch (e) {
      throw Exception('Failed to get users count by role: $e');
    }
  }
}
