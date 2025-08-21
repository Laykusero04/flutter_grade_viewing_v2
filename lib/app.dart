import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart'; 
import 'screens/admin/admin_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/student/student_dashboard.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/teacher_dashboard': (context) => const TeacherDashboardScreen(),
          '/student_dashboard': (context) => const StudentDashboardScreen(),
        },
      ),
    );
  }
}
