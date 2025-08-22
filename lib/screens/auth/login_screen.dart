import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../components/constants/app_text_styles.dart';
import '../../components/constants/app_color.dart';
import '../../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Manual navigation since router redirect isn't working
          switch (state.user.userRole) {
            case 1: // admin
              context.go('/admin');
              break;
            case 2: // teacher
              context.go('/teacher');
              break;
            case 3: // student
              context.go('/student');
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid user role')),
              );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Login')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 20),
                  state is AuthLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              BlocProvider.of<AuthBloc>(context).add(
                                LoginRequested(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                ),
                              );
                            }
                          },
                          child: const Text('Login'),
                        ),
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: AppTextStyles.body,
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: AppTextStyles.body.copyWith(
                            color: AppColor.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.go('/register');
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}