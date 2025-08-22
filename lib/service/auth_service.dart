import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'base_service.dart';

class AuthService {
  static final FirebaseAuth _auth = BaseService.auth;
  static final FirebaseFirestore _firestore = BaseService.firestore;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  static Future<AppUser?> getUserData(String email) async {
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        return AppUser.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Save user data to Firestore
  static Future<void> saveUserData(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Check if user exists
  static Future<bool> userExists(String email) async {
    try {
      final userDoc = await _firestore.collection('users').doc(email).get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Update user data
  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Delete user data
  static Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}
