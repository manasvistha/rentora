import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentora/core/api/api_endpoints.dart';
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
  File? _selectedImage;

  String? _resolveProfilePictureUrl(String? rawPath) {
    if (rawPath == null) return null;

    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final host = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    if (trimmed.startsWith('/public/')) {
      return '$host$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return '$host$trimmed';
    }

    return '$host/public/profile-pictures/$trimmed';
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4AA6A6)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7FBFB),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1ECEC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4AA6A6), width: 1.6),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (image == null) return;
    final file = File(image.path);
    setState(() => _selectedImage = file);
    try {
      final authViewModel = ref.read(authViewModelProvider.notifier);
      await authViewModel.uploadPhoto(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final user = authState.user;
    final profilePictureUrl = _resolveProfilePictureUrl(user?.profilePicture);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4AA6A6),
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4EEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4AA6A6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4AA6A6),
                                    width: 1.8,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                            as ImageProvider
                                      : (profilePictureUrl != null
                                            ? NetworkImage(profilePictureUrl)
                                            : null),
                                  child:
                                      (_selectedImage == null &&
                                          profilePictureUrl == null)
                                      ? const Icon(
                                          Icons.person,
                                          size: 56,
                                          color: Color(0xFF4AA6A6),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF4AA6A6),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Color(0xFF4AA6A6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap icon to update your profile image',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: _fieldDecoration(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter your email';
                        if (!value.contains('@'))
                          return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4AA6A6),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Change Password',
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
                      TextFormField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: !_showPassword,
                        decoration: _fieldDecoration(
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF4AA6A6),
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: _isChangingPassword
                            ? (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please enter a password';
                                if (value.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        obscureText: !_showConfirmPassword,
                        decoration: _fieldDecoration(
                          label: 'Confirm New Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF4AA6A6),
                            ),
                            onPressed: () => setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            ),
                          ),
                        ),
                        validator: _isChangingPassword
                            ? (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please confirm your password';
                                if (value != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              }
                            : null,
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4AA6A6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                                'Save Changes',
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
          ],
        ),
      ),
    );
  }
}
