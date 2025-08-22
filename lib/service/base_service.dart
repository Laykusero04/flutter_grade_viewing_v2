import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
  
  static bool get isInitialized => Firebase.apps.isNotEmpty;
}
