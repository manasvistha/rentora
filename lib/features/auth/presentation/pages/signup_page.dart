import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';

// Provider to hold selected profile image
final signupProfileImageProvider = StateProvider<File?>((ref) => null);

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4AA6A6)),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF4AA6A6),
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        ref.read(signupProfileImageProvider.notifier).state = File(image.path);
      }
    }
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      final user = AuthEntity(
        id: '',
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passController.text.trim(),
      );

      final profileImage = ref.read(signupProfileImageProvider);
      final confirmPassword = _confirmPassController.text.trim();

      ref
          .read(authViewModelProvider.notifier)
          .register(
            user,
            profileImage: profileImage,
            confirmPassword: confirmPassword,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final profileImage = ref.watch(signupProfileImageProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.registered) {
        // Clear the profile image
        ref.read(signupProfileImageProvider.notifier).state = null;

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
      backgroundColor: const Color(0xFFB7E3E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4AA6A6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset("assets/images/Logo.png", height: 100)),
              const SizedBox(height: 20),

              // Profile Picture Selection
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF4AA6A6),
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4AA6A6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Tap to add profile picture",
                  style: TextStyle(color: Color(0xFF4AA6A6), fontSize: 14),
                ),
              ),

              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person_outline,
                validator: (val) => val!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => (val == null || !val.contains("@"))
                    ? "Enter a valid email"
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passController,
                label: "Password",
                icon: Icons.lock_outline,
                obscureText: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
                validator: (val) => val!.length < 6 ? "Min 6 characters" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPassController,
                label: "Confirm Password",
                icon: Icons.lock_reset_outlined,
                obscureText: !_showConfirmPass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _showConfirmPass = !_showConfirmPass),
                ),
                validator: (val) => val != _passController.text
                    ? "Passwords do not match"
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4AA6A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: authState.status == AuthStatus.loading
                      ? null
                      : _handleSignup,
                  child: authState.status == AuthStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4AA6A6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      validator: validator,
    );
  }
}
