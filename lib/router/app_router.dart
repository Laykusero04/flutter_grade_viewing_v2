import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_students_screen.dart';
import '../screens/admin/manage_teachers_screen.dart';
import '../screens/admin/manage_subjects_screen.dart';
import '../screens/admin/manage_grades_screen.dart';
import '../screens/admin/manage_academic_years_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/grade_submission_screen.dart';
import '../screens/teacher/notifications_screen.dart';
import '../screens/teacher/request_screen.dart';
import '../screens/teacher/subject_students_screen.dart';
import '../screens/student/student_dashboard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Get the current route location
      final currentLocation = state.matchedLocation;
      
      // Always allow access to auth routes
      if (currentLocation == '/login' || currentLocation == '/register') {
        return null; // No redirect needed
      }
      
      // For all other routes, check authentication
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        
        // If not authenticated, redirect to login
        if (authState is! AuthAuthenticated) {
          return '/login';
        }
        
        // If authenticated and trying to access root, redirect based on role
        if (currentLocation == '/') {
          switch (authState.user.userRole) {
            case 1: // admin
              return '/admin';
            case 2: // teacher
              return '/teacher';
            case 3: // student
              return '/student';
            default:
              return '/login';
          }
        }
        
        // User is authenticated and accessing a valid route
        return null;
      } catch (e) {
        // If AuthBloc is not available, redirect to login
        return '/login';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'students',
            name: 'admin-students',
            builder: (context, state) => const ManageStudentsScreen(),
          ),
          GoRoute(
            path: 'teachers',
            name: 'admin-teachers',
            builder: (context, state) => const ManageTeachersScreen(),
          ),
          GoRoute(
            path: 'subjects',
            name: 'admin-subjects',
            builder: (context, state) => const ManageSubjectsScreen(),
          ),
          GoRoute(
            path: 'grades',
            name: 'admin-grades',
            builder: (context, state) => const ManageGradesScreen(),
          ),
          GoRoute(
            path: 'academic_years',
            name: 'admin-academic-years',
            builder: (context, state) => const ManageAcademicYearsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        name: 'teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: 'grade-submission',
            name: 'teacher-grade-submission',
            builder: (context, state) => const GradeSubmissionScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'teacher-notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'request',
            name: 'teacher-request',
            builder: (context, state) => const RequestScreen(),
          ),
          GoRoute(
            path: 'subject-students/:subjectId',
            name: 'teacher-subject-students',
            builder: (context, state) {
              final subjectId = state.pathParameters['subjectId']!;
              return SubjectStudentsScreen(subjectId: subjectId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/student',
        name: 'student',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.matchedLocation}" was not found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
