import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_service.dart';
import 'auth_service.dart';
import 'user_service.dart';

class FirebaseService {
  static bool _isInitialized = false;

  // Initialize Firebase
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await BaseService.initialize();
      _isInitialized = true;
    }
  }

  // Check if Firebase is initialized
  static bool get isInitialized => _isInitialized && BaseService.isInitialized;

  // Get Firebase Auth instance
  static FirebaseAuth get auth => BaseService.auth;

  // Get Firebase Firestore instance
  static FirebaseFirestore get firestore => BaseService.firestore;

  // Get current user
  static User? get currentUser => AuthService.currentUser;

  // Get auth state changes stream
  static Stream<User?> get authStateChanges => AuthService.authStateChanges;

  // Authentication methods
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await AuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await AuthService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await AuthService.signOut();
  }

  // User data methods
  static Future<dynamic> getUserData(String email) async {
    return await AuthService.getUserData(email);
  }

  static Future<void> saveUserData(dynamic user) async {
    return await AuthService.saveUserData(user);
  }

  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    return await AuthService.updateUserData(uid, data);
  }

  static Future<void> deleteUserData(String uid) async {
    return await AuthService.deleteUserData(uid);
  }

  // User service methods
  static Future<dynamic> getUserByEmail(String email) async {
    return await UserService.getUserByEmail(email);
  }

  static Future<dynamic> getUserByUid(String uid) async {
    return await UserService.getUserByUid(uid);
  }

  static Future<List<dynamic>> getUsersByRole(String role) async {
    return await UserService.getUsersByRole(role);
  }

  static Future<List<dynamic>> getAllUsers() async {
    return await UserService.getAllUsers();
  }

  static Future<void> createUser(dynamic user) async {
    return await UserService.createUser(user);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    return await UserService.updateUser(uid, data);
  }

  static Future<void> deleteUser(String uid) async {
    return await UserService.deleteUser(uid);
  }

  static Future<List<dynamic>> searchUsersByName(String searchTerm) async {
    return await UserService.searchUsersByName(searchTerm);
  }

  static Future<int> getUsersCountByRole(String role) async {
    return await UserService.getUsersCountByRole(role);
  }

  // Utility methods
  static Future<void> clearAllData() async {
    // This method should be used carefully and only in development/testing
    try {
      // Note: listCollections() is not available in current Firebase version
      // This method would need to be implemented differently based on your needs
      throw UnimplementedError('clearAllData method needs to be implemented based on specific requirements');
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  // Check connection status
  static Future<bool> checkConnection() async {
    try {
      await firestore.runTransaction((transaction) async {
        return true;
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
