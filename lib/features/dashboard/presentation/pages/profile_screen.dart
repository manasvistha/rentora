import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/dashboard/presentation/pages/edit_profile_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/about_screen.dart';

final profileImageProvider = NotifierProvider<ProfileImageNotifier, File?>(
  ProfileImageNotifier.new,
);

class ProfileImageNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void setImage(File file) {
    state = file;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        final imageFile = File(image.path);
        ref.read(profileImageProvider.notifier).setImage(imageFile);
        try {
          final authViewModel = ref.read(authViewModelProvider.notifier);
          await authViewModel.uploadPhoto(imageFile);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture uploaded successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileImage = ref.watch(profileImageProvider);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final profilePictureUrl = _resolveProfilePictureUrl(user?.profilePicture);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: Column(
        children: [
          Container(
            height: 310,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4AA6A6), Color(0xFF5BC0BE)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 44,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/bottomnavigation',
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),

                // Profile Picture
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () => _pickImage(context, ref),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: profileImage != null
                                    ? FileImage(profileImage)
                                    : (profilePictureUrl != null
                                              ? NetworkImage(profilePictureUrl)
                                              : null)
                                          as ImageProvider?,
                                child:
                                    (profileImage == null &&
                                        profilePictureUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF4AA6A6),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4AA6A6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Color(0xFF4AA6A6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tap to change photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Info Section
          Transform.translate(
            offset: const Offset(0, -46),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4AA6A6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.name ?? "User",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Menu Options
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Edit Profile Option
                    _buildMenuOption(
                      context,
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      subtitle:
                          "Edit all the basic profile information associated with your profile",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // About Us Option
                    _buildMenuOption(
                      context,
                      icon: Icons.help_outline,
                      title: "About Us",
                      subtitle: "Learn more about Rentora",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMenuOption(
                      context,
                      icon: Icons.logout,
                      title: "Sign Out",
                      iconColor: Colors.red[400],
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && context.mounted) {
                          final auth = ref.read(authViewModelProvider.notifier);
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (_) => false,
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EFEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFF4AA6A6)).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF4AA6A6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4AA6A6).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF4AA6A6),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
