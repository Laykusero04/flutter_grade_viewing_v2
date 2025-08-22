import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/teacher.dart';
import '../service/firestore_teacher_service.dart';

// Events
abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeachers extends TeacherEvent {}

class SearchTeachers extends TeacherEvent {
  final String query;
  const SearchTeachers(this.query);

  @override
  List<Object?> get props => [query];
}

class AddTeacher extends TeacherEvent {
  final Teacher teacher;
  const AddTeacher(this.teacher);

  @override
  List<Object?> get props => [teacher];
}

class UpdateTeacher extends TeacherEvent {
  final Teacher teacher;
  const UpdateTeacher(this.teacher);

  @override
  List<Object?> get props => [teacher];
}

class DeleteTeacher extends TeacherEvent {
  final String id;
  const DeleteTeacher(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class TeacherState extends Equatable {
  const TeacherState();

  @override
  List<Object?> get props => [];
}

class TeacherInitial extends TeacherState {}

class TeacherLoading extends TeacherState {}

class TeachersLoaded extends TeacherState {
  final List<Teacher> teachers;
  final String? searchQuery;

  const TeachersLoaded({
    required this.teachers,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [teachers, searchQuery];
}

class TeacherOperationSuccess extends TeacherState {
  final String message;
  final List<Teacher> teachers;

  const TeacherOperationSuccess({
    required this.message,
    required this.teachers,
  });

  @override
  List<Object?> get props => [message, teachers];
}

class TeacherError extends TeacherState {
  final String message;

  const TeacherError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  TeacherBloc() : super(TeacherInitial()) {
    on<LoadTeachers>(_onLoadTeachers);
    on<SearchTeachers>(_onSearchTeachers);
    on<AddTeacher>(_onAddTeacher);
    on<UpdateTeacher>(_onUpdateTeacher);
    on<DeleteTeacher>(_onDeleteTeacher);
  }

  Future<void> _onLoadTeachers(LoadTeachers event, Emitter<TeacherState> emit) async {
    emit(TeacherLoading());
    try {
      final teachers = await FirestoreTeacherService.getAllTeachers();
      emit(TeachersLoaded(teachers: teachers));
    } catch (e) {
      emit(TeacherError('Failed to load teachers: ${e.toString()}'));
    }
  }

  Future<void> _onSearchTeachers(SearchTeachers event, Emitter<TeacherState> emit) async {
    emit(TeacherLoading());
    try {
      final teachers = await FirestoreTeacherService.searchTeachers(event.query);
      emit(TeachersLoaded(
        teachers: teachers,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(TeacherError('Failed to search teachers: ${e.toString()}'));
    }
  }

  Future<void> _onAddTeacher(AddTeacher event, Emitter<TeacherState> emit) async {
    emit(TeacherLoading());
    try {
      final success = await FirestoreTeacherService.addTeacher(event.teacher);
      if (success) {
        final teachers = await FirestoreTeacherService.getAllTeachers();
        emit(TeacherOperationSuccess(
          message: 'Teacher added successfully',
          teachers: teachers,
        ));
      } else {
        emit(const TeacherError('Failed to add teacher'));
      }
    } catch (e) {
      emit(TeacherError('Failed to add teacher: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTeacher(UpdateTeacher event, Emitter<TeacherState> emit) async {
    emit(TeacherLoading());
    try {
      final success = await FirestoreTeacherService.updateTeacher(event.teacher);
      if (success) {
        final teachers = await FirestoreTeacherService.getAllTeachers();
        emit(TeacherOperationSuccess(
          message: 'Teacher updated successfully',
          teachers: teachers,
        ));
      } else {
        emit(const TeacherError('Failed to update teacher'));
      }
    } catch (e) {
      emit(TeacherError('Failed to update teacher: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTeacher(DeleteTeacher event, Emitter<TeacherState> emit) async {
    emit(TeacherLoading());
    try {
      final success = await FirestoreTeacherService.deleteTeacher(event.id);
      if (success) {
        final teachers = await FirestoreTeacherService.getAllTeachers();
        emit(TeacherOperationSuccess(
          message: 'Teacher deleted successfully',
          teachers: teachers,
        ));
      } else {
        emit(const TeacherError('Failed to delete teacher'));
      }
    } catch (e) {
      emit(TeacherError('Failed to delete teacher: ${e.toString()}'));
    }
  }
}
