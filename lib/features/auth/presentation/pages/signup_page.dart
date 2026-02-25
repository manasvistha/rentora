import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  bool _showPassword = false;
  bool _showConfirmPass = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      final user = AuthEntity(
        id: '',
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passController.text.trim(),
      );

      final confirmPassword = _confirmPassController.text.trim();

      ref
          .read(authViewModelProvider.notifier)
          .register(user, confirmPassword: confirmPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created Successfully! Please Login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                      vertical: 20,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Color(0xFF2D6D69),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 52),
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        70,
                                        24,
                                        26,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
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
                                            "Create Account",
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
                                            "Set up your profile and discover better rentals.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF5A7471),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          _buildTextField(
                                            controller: _nameController,
                                            hint: "Full Name",
                                            icon: Icons.person_outline_rounded,
                                            validator: (val) => val!.isEmpty
                                                ? "Enter your name"
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _buildTextField(
                                            controller: _emailController,
                                            hint: "Email Address",
                                            icon: Icons.alternate_email_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (val) =>
                                                (val == null ||
                                                    !val.contains("@"))
                                                ? "Enter a valid email"
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _buildTextField(
                                            controller: _passController,
                                            hint: "Password",
                                            icon: Icons.lock_outline_rounded,
                                            obscureText: !_showPassword,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _showPassword
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: const Color(0xFF5B7673),
                                              ),
                                              onPressed: () => setState(
                                                () => _showPassword =
                                                    !_showPassword,
                                              ),
                                            ),
                                            validator: (val) => val!.length < 6
                                                ? "Min 6 characters"
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _buildTextField(
                                            controller: _confirmPassController,
                                            hint: "Confirm Password",
                                            icon: Icons.lock_reset_rounded,
                                            obscureText: !_showConfirmPass,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _showConfirmPass
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: const Color(0xFF5B7673),
                                              ),
                                              onPressed: () => setState(
                                                () => _showConfirmPass =
                                                    !_showConfirmPass,
                                              ),
                                            ),
                                            validator: (val) =>
                                                val != _passController.text
                                                ? "Passwords do not match"
                                                : null,
                                          ),
                                          const SizedBox(height: 24),
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
                                                  : _handleSignup,
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
                                                      "Create Account",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                "Already have an account?",
                                                style: TextStyle(
                                                  color: Color(0xFF637D7A),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: isLoading
                                                    ? null
                                                    : () => Navigator.pop(
                                                        context,
                                                      ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF1A8F84,
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Log in",
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
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: _FloatingAuthLogo(size: 98),
                                      ),
                                    ),
                                  ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF3A8A85)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7FBFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
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
      ),
      validator: validator,
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
