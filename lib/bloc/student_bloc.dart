import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/student.dart';
import '../service/firestore_student_service.dart';

// Events
abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudents extends StudentEvent {}

class SearchStudents extends StudentEvent {
  final String query;
  const SearchStudents(this.query);

  @override
  List<Object?> get props => [query];
}

class AddStudent extends StudentEvent {
  final Student student;
  const AddStudent(this.student);

  @override
  List<Object?> get props => [student];
}

class UpdateStudent extends StudentEvent {
  final Student student;
  const UpdateStudent(this.student);

  @override
  List<Object?> get props => [student];
}

class DeleteStudent extends StudentEvent {
  final String id;
  const DeleteStudent(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentsLoaded extends StudentState {
  final List<Student> students;
  final String? searchQuery;

  const StudentsLoaded({
    required this.students,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [students, searchQuery];
}

class StudentOperationSuccess extends StudentState {
  final String message;
  final List<Student> students;

  const StudentOperationSuccess({
    required this.message,
    required this.students,
  });

  @override
  List<Object?> get props => [message, students];
}

class StudentError extends StudentState {
  final String message;

  const StudentError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class StudentBloc extends Bloc<StudentEvent, StudentState> {
  StudentBloc() : super(StudentInitial()) {
    on<LoadStudents>(_onLoadStudents);
    on<SearchStudents>(_onSearchStudents);
    on<AddStudent>(_onAddStudent);
    on<UpdateStudent>(_onUpdateStudent);
    on<DeleteStudent>(_onDeleteStudent);
  }

  Future<void> _onLoadStudents(LoadStudents event, Emitter<StudentState> emit) async {
    emit(StudentLoading());
    try {
      final students = await FirestoreStudentService.getAllStudents();
      emit(StudentsLoaded(students: students));
    } catch (e) {
      emit(StudentError('Failed to load students: ${e.toString()}'));
    }
  }

  Future<void> _onSearchStudents(SearchStudents event, Emitter<StudentState> emit) async {
    emit(StudentLoading());
    try {
      final students = await FirestoreStudentService.searchStudents(event.query);
      emit(StudentsLoaded(
        students: students,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(StudentError('Failed to search students: ${e.toString()}'));
    }
  }

  Future<void> _onAddStudent(AddStudent event, Emitter<StudentState> emit) async {
    emit(StudentLoading());
    try {
      final success = await FirestoreStudentService.addStudent(event.student);
      if (success) {
        final students = await FirestoreStudentService.getAllStudents();
        emit(StudentOperationSuccess(
          message: 'Student added successfully',
          students: students,
        ));
      } else {
        emit(const StudentError('Failed to add student'));
      }
    } catch (e) {
      emit(StudentError('Failed to add student: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStudent(UpdateStudent event, Emitter<StudentState> emit) async {
    emit(StudentLoading());
    try {
      final success = await FirestoreStudentService.updateStudent(event.student);
      if (success) {
        final students = await FirestoreStudentService.getAllStudents();
        emit(StudentOperationSuccess(
          message: 'Student updated successfully',
          students: students,
        ));
      } else {
        emit(const StudentError('Failed to update student'));
      }
    } catch (e) {
      emit(StudentError('Failed to update student: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteStudent(DeleteStudent event, Emitter<StudentState> emit) async {
    emit(StudentLoading());
    try {
      final success = await FirestoreStudentService.deleteStudent(event.id);
      if (success) {
        final students = await FirestoreStudentService.getAllStudents();
        emit(StudentOperationSuccess(
          message: 'Student deleted successfully',
          students: students,
        ));
      } else {
        emit(const StudentError('Failed to delete student'));
      }
    } catch (e) {
      emit(StudentError('Failed to delete student: ${e.toString()}'));
    }
  }
}
