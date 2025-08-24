import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/student_bloc.dart';
import 'bloc/teacher_bloc.dart';
import 'bloc/subject_bloc.dart';
import 'router/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => StudentBloc()),
        BlocProvider(create: (_) => TeacherBloc()),
        BlocProvider(create: (_) => SubjectBloc()),
      ],
      child: MaterialApp.router(
        title: 'Grade Viewing App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
