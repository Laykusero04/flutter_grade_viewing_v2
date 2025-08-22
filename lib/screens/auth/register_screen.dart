import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../components/constants/app_text_styles.dart';
import '../../components/constants/app_color.dart';
import '../../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _registerAs = 'Student';
  final _schoolIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _schoolIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int getRoleValue(String role) {
    switch (role) {
      case 'Teacher':
        return 2;
      case 'Student':
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Manual navigation since router redirect isn't working
          switch (state.user.userRole) {
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
            appBar: AppBar(title: const Text('Register')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _schoolIdController,
                      decoration: const InputDecoration(labelText: 'School ID'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _registerAs,
                      decoration: const InputDecoration(labelText: 'Register As'),
                      items: const [
                        DropdownMenuItem(value: 'Student', child: Text('Student')),
                        DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _registerAs = value!;
                        });
                      },
                    ),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
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
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                      validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 20),
                    state is AuthLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                BlocProvider.of<AuthBloc>(context).add(
                                  RegisterRequested(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    firstName: _firstNameController.text.trim(),
                                    lastName: _lastNameController.text.trim(),
                                    schoolId: _schoolIdController.text.trim(),
                                    userRole: getRoleValue(_registerAs),
                                  ),
                                );
                              }
                            },
                            child: const Text('Register'),
                          ),
                    RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.body,
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: AppTextStyles.body.copyWith(
                              color: AppColor.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.go('/login');
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