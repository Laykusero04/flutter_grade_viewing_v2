import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final userDoc = await _firestore.collection('users').doc(event.email).get();
      if (!userDoc.exists) {
        emit(const AuthError('User data not found.'));
        return;
      }
      final appUser = AppUser.fromMap(userDoc.data()!);
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
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
      await _firestore.collection('users').doc(event.email).set(appUser.toMap());
      emit(AuthAuthenticated(appUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Registration failed.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(AuthInitial());
  }
}
