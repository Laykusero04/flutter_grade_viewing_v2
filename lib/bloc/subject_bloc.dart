import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../service/firestore_subject_service.dart';

// Events
abstract class SubjectEvent extends Equatable {
  const SubjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjects extends SubjectEvent {}

class AddSubject extends SubjectEvent {
  final Subject subject;

  const AddSubject(this.subject);

  @override
  List<Object?> get props => [subject];
}

class UpdateSubject extends SubjectEvent {
  final Subject subject;

  const UpdateSubject(this.subject);

  @override
  List<Object?> get props => [subject];
}

class DeleteSubject extends SubjectEvent {
  final String uid;

  const DeleteSubject(this.uid);

  @override
  List<Object?> get props => [uid];
}

class SearchSubjects extends SubjectEvent {
  final String query;

  const SearchSubjects(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadSubjectTeachers extends SubjectEvent {
  final String subjectId;

  const LoadSubjectTeachers(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

// States
abstract class SubjectState extends Equatable {
  const SubjectState();

  @override
  List<Object?> get props => [];
}

class SubjectInitial extends SubjectState {}

class SubjectLoading extends SubjectState {}

class SubjectsLoaded extends SubjectState {
  final List<Subject> subjects;
  final String? searchQuery;

  const SubjectsLoaded(this.subjects, {this.searchQuery});

  @override
  List<Object?> get props => [subjects, searchQuery];
}

class SubjectTeachersLoaded extends SubjectState {
  final List<Teacher> teachers;
  final String subjectId;

  const SubjectTeachersLoaded(this.teachers, this.subjectId);

  @override
  List<Object?> get props => [teachers, subjectId];
}

class SubjectOperationSuccess extends SubjectState {
  final String message;

  const SubjectOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SubjectError extends SubjectState {
  final String message;

  const SubjectError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class SubjectBloc extends Bloc<SubjectEvent, SubjectState> {
  SubjectBloc() : super(SubjectInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<AddSubject>(_onAddSubject);
    on<UpdateSubject>(_onUpdateSubject);
    on<DeleteSubject>(_onDeleteSubject);
    on<SearchSubjects>(_onSearchSubjects);
    on<LoadSubjectTeachers>(_onLoadSubjectTeachers);
  }

  void _onLoadSubjects(LoadSubjects event, Emitter<SubjectState> emit) async {
    emit(SubjectLoading());
    try {
      final subjects = await FirestoreSubjectService.getAllSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectError('Failed to load subjects: $e'));
    }
  }

  void _onAddSubject(AddSubject event, Emitter<SubjectState> emit) async {
    try {
      // Check if subject code already exists
      final exists = await FirestoreSubjectService.subjectExists(event.subject.code);
      if (exists) {
        emit(const SubjectError('Subject with this code already exists'));
        return;
      }

      // Add subject to Firestore
      final newUid = await FirestoreSubjectService.addSubject(event.subject);
      
      // Create updated subject with the new UID
      final updatedSubject = event.subject.copyWith(uid: newUid);
      
      emit(const SubjectOperationSuccess('Subject added successfully'));
      add(LoadSubjects());
    } catch (e) {
      emit(SubjectError('Failed to add subject: $e'));
    }
  }

  void _onUpdateSubject(UpdateSubject event, Emitter<SubjectState> emit) async {
    try {
      await FirestoreSubjectService.updateSubject(event.subject);
      
      emit(const SubjectOperationSuccess('Subject updated successfully'));
      add(LoadSubjects());
    } catch (e) {
      emit(SubjectError('Failed to update subject: $e'));
    }
  }

  void _onDeleteSubject(DeleteSubject event, Emitter<SubjectState> emit) async {
    try {
      await FirestoreSubjectService.deleteSubject(event.uid);
      
      emit(const SubjectOperationSuccess('Subject deleted successfully'));
      add(LoadSubjects());
    } catch (e) {
      emit(SubjectError('Failed to delete subject: $e'));
    }
  }

  void _onSearchSubjects(SearchSubjects event, Emitter<SubjectState> emit) async {
    try {
      final subjects = await FirestoreSubjectService.searchSubjects(event.query);
      
      emit(SubjectsLoaded(subjects, searchQuery: event.query));
    } catch (e) {
      emit(SubjectError('Failed to search subjects: $e'));
    }
  }

  void _onLoadSubjectTeachers(LoadSubjectTeachers event, Emitter<SubjectState> emit) async {
    try {
      final teachers = await FirestoreSubjectService.getSubjectTeachers(event.subjectId);
      
      emit(SubjectTeachersLoaded(teachers, event.subjectId));
    } catch (e) {
      emit(SubjectError('Failed to load subject teachers: $e'));
    }
  }
}
