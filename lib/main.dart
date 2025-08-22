import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'service/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the service
  await FirebaseService.initialize();
  
  // Fallback to direct initialization if service fails
  if (!FirebaseService.isInitialized) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const MyApp());
}
