import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/auth/domain/entities/auth_entity.dart';
import 'package:rentora/features/auth/presentation/state/auth_state.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill current user data
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(authViewModelProvider).user;

      if (currentUser == null) return;

      final updatedUser = AuthEntity(
        id: currentUser.id,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _isChangingPassword && _passwordController.text.isNotEmpty
            ? _passwordController.text.trim()
            : null,
        profilePicture: currentUser.profilePicture,
      );

      ref.read(authViewModelProvider.notifier).updateUser(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status == AuthStatus.loading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
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

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

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
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF4AA6A6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4AA6A6),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF4AA6A6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4AA6A6),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Change Password Toggle
              CheckboxListTile(
                title: const Text(
                  "Change Password",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4AA6A6),
                  ),
                ),
                value: _isChangingPassword,
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isChangingPassword = value ?? false;
                          if (!_isChangingPassword) {
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          }
                        });
                      },
                activeColor: const Color(0xFF4AA6A6),
                contentPadding: EdgeInsets.zero,
              ),

              if (_isChangingPassword) ...[
                const SizedBox(height: 8),

                // New Password Field
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF4AA6A6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF4AA6A6),
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4AA6A6),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: _isChangingPassword
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        }
                      : null,
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF4AA6A6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF4AA6A6),
                      ),
                      onPressed: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4AA6A6),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: _isChangingPassword
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        }
                      : null,
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4AA6A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: isLoading ? null : _handleSave,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Changes",
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
}
