part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final List<int>? expectedRoles; // e.g. [2,3] for teacher/student
  const LoginRequested({required this.email, required this.password, this.expectedRoles});
  @override
  List<Object?> get props => [email, password, expectedRoles];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String schoolId;
  final int userRole; // 2=teacher, 3=student
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.userRole,
  });
  @override
  List<Object?> get props => [email, password, firstName, lastName, schoolId, userRole];
}

class LogoutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {}
