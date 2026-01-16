import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/common/my_snackbar.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/dashboard/presentation/pages/bottomnavigation_screen.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen for State Changes (Side Effects like SnackBar or Navigation)
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        showMySnackBar(
          context: context,
          message: "Login Successful",
          color: Colors.green,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomnavigationScreen()),
        );
      } else if (next.status == AuthStatus.error) {
        showMySnackBar(
          context: context,
          message: next.errorMessage ?? "Login Failed",
          color: Colors.red,
        );
      }
    });

    // 2. Watch the state for UI changes (Loading indicators)
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4AA6A6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Login", style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: const Color(0xFFB7E3E4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  "assets/images/Logo.png",
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.home_work,
                    size: 100,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Login",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // EMAIL FIELD
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading, // Disable during loading
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter email";
                  if (!value.contains("@")) return "Invalid email";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // PASSWORD FIELD
              TextFormField(
                controller: _passController,
                obscureText: !showPassword,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter password";
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/forgot');
                        },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref
                                .read(authViewModelProvider.notifier)
                                .login(
                                  _emailController.text.trim(),
                                  _passController.text,
                                );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Login", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  InkWell(
                    onTap: isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
