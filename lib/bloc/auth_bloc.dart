import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../service/firebase_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    
    // Listen to Firebase auth state changes using the service
    FirebaseService.authStateChanges.listen((User? user) {
      if (user == null) {
        add(AuthStateChanged());
      } else {
        add(AuthStateChanged());
      }
    });
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Use the service for authentication
      await FirebaseService.signIn(
        email: event.email,
        password: event.password,
      );
      
      // Get user data using the service
      final appUser = await FirebaseService.getUserData(event.email);
      if (appUser == null) {
        emit(const AuthError('User data not found.'));
        return;
      }
      
      // Check role matches
      if (event.expectedRoles != null && !event.expectedRoles!.contains(appUser.userRole)) {
        emit(const AuthError('User role not allowed.'));
        return;
      }
      
      emit(AuthAuthenticated(appUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Login failed.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Use the service for user creation
      await FirebaseService.signUp(
        email: event.email,
        password: event.password,
      );
      
      final appUser = AppUser(
        uid: event.email, // use email as uid
        email: event.email,
        firstName: event.firstName,
        lastName: event.lastName,
        schoolId: event.schoolId,
        userRole: event.userRole,
      );
      
      // Save user data using the service
      await FirebaseService.saveUserData(appUser);
      emit(AuthAuthenticated(appUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Registration failed.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    // Use the service for logout
    await FirebaseService.signOut();
    emit(AuthInitial());
  }

  Future<void> _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      emit(AuthInitial());
    } else {
      try {
        // Get user data using the service
        final appUser = await FirebaseService.getUserData(user.email!);
        if (appUser != null) {
          emit(AuthAuthenticated(appUser));
        } else {
          emit(const AuthError('User data not found.'));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    }
  }
}
