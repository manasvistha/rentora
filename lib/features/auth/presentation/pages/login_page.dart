import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/common/my_snackbar.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/dashboard/presentation/pages/bottomnavigation_screen.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';

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
    ref.listen<AuthState>(authViewModelProvider, (previous, next) async {
      if (next.status == AuthStatus.authenticated) {
        showMySnackBar(
          context: context,
          message: "Login Successful",
          color: Colors.green,
        );
        final sessionService = ref.read(userSessionServiceProvider);
        final isAdmin = await sessionService.isAdmin();
        if (isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottomnavigationScreen()),
          );
        }
      } else if (next.status == AuthStatus.error) {
        showMySnackBar(
          context: context,
          message: next.errorMessage ?? "Login Failed",
          color: Colors.red,
        );
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F6F5), Color(0xFFD9EEEC), Color(0xFFF8FCFB)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _AuthBackgroundPattern(),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Form(
                            key: _formKey,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 52),
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    70,
                                    24,
                                    28,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFFDDE9E7),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1F4D4A,
                                        ).withValues(alpha: 0.08),
                                        blurRadius: 30,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        "Welcome Back",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF122B2A),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Sign in to continue your room-finding journey.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF5A7471),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        enabled: !isLoading,
                                        decoration: _inputDecoration(
                                          hint: "Email address",
                                          icon: Icons.alternate_email_rounded,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Enter email";
                                          }
                                          if (!value.contains("@")) {
                                            return "Invalid email";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passController,
                                        obscureText: !showPassword,
                                        enabled: !isLoading,
                                        decoration: _inputDecoration(
                                          hint: "Password",
                                          icon: Icons.lock_outline_rounded,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              showPassword
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                        .visibility_off_rounded,
                                              color: const Color(0xFF5B7673),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                showPassword = !showPassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Enter password";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/forgot',
                                                  );
                                                },
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF2A7370,
                                            ),
                                          ),
                                          child: const Text(
                                            "Forgot Password?",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF2D8A86,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    ref
                                                        .read(
                                                          authViewModelProvider
                                                              .notifier,
                                                        )
                                                        .login(
                                                          _emailController.text
                                                              .trim(),
                                                          _passController.text,
                                                        );
                                                  }
                                                },
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.3,
                                                      ),
                                                )
                                              : const Text(
                                                  "Continue",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "New to Rentora?",
                                            style: TextStyle(
                                              color: Color(0xFF637D7A),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: isLoading
                                                ? null
                                                : () => Navigator.pushNamed(
                                                    context,
                                                    '/signup',
                                                  ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF1A8F84,
                                              ),
                                            ),
                                            child: const Text(
                                              "Create account",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _FloatingAuthLogo(size: 98),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF3A8A85)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7FBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8E7E4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8E7E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4AA6A6), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE87777)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD84A4A), width: 1.2),
      ),
    );
  }
}

class _AuthBackgroundPattern extends StatelessWidget {
  const _AuthBackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF67C7BD).withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -45,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9FD9D2).withValues(alpha: 0.20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAuthLogo extends StatelessWidget {
  final double size;

  const _FloatingAuthLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC7E5E1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A6561).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset(
          "assets/images/Logo.png",
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.home_work_rounded,
            color: Color(0xFF4AA6A6),
            size: 52,
          ),
        ),
      ),
    );
  }
}
