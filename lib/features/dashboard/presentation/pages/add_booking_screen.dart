import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/presentation/pages/dashboard_lists_screen.dart';
import 'package:rentora/features/dashboard/presentation/providers/dashboard_data_providers.dart';

class AddBookingScreen extends ConsumerStatefulWidget {
  const AddBookingScreen({super.key});

  @override
  ConsumerState<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends ConsumerState<AddBookingScreen> {
  DashboardPropertyEntity? _selectedProperty;
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (_selectedProperty == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a property')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = ref.read(apiClientProvider);
      final body = <String, dynamic>{'propertyId': _selectedProperty!.id};

      if (_messageController.text.trim().isNotEmpty) {
        body['message'] = _messageController.text.trim();
      }

      final tenantInfo = <String, String>{};
      if (_nameController.text.trim().isNotEmpty) {
        tenantInfo['name'] = _nameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        tenantInfo['email'] = _emailController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        tenantInfo['phone'] = _phoneController.text.trim();
      }
      if (tenantInfo.isNotEmpty) {
        body['tenantInfo'] = tenantInfo;
      }

      await client.post(ApiEndpoints.bookingCreate, data: body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully!'),
          backgroundColor: Color(0xFF2F9E9A),
        ),
      );

      // Clear form
      setState(() {
        _selectedProperty = null;
        _messageController.clear();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to submit booking';
      final errStr = e.toString();
      if (errStr.contains('already booked')) {
        msg = 'You have already booked this property';
      } else if (errStr.contains('own property')) {
        msg = 'You cannot book your own property';
      } else if (errStr.contains('not available')) {
        msg = 'This property is not available for booking';
      } else if (errStr.contains('already rented')) {
        msg = 'This property is already rented';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(allPropertiesProvider(false));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Add Booking',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Property Selector Card
                      _FormCard(
                        title: 'Select Property',
                        icon: Icons.home_outlined,
                        child: propertiesAsync.when(
                          data: (properties) {
                            if (properties.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'No properties available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return DropdownButtonFormField<
                              DashboardPropertyEntity
                            >(
                              value: _selectedProperty,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Choose a property',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2F9E9A),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              items: properties.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${p.title} — ${p.location}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProperty = v),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2F9E9A),
                              ),
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Error loading properties',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message Card
                      _FormCard(
                        title: 'Message (Optional)',
                        icon: Icons.message_outlined,
                        child: _StyledTextField(
                          controller: _messageController,
                          hint: 'Write a message to the owner...',
                          maxLines: 3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tenant Info Card
                      _FormCard(
                        title: 'Your Information (Optional)',
                        icon: Icons.person_outline,
                        child: Column(
                          children: [
                            _StyledTextField(
                              controller: _nameController,
                              hint: 'Full Name',
                              prefixIcon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 12),
                            _StyledTextField(
                              controller: _emailController,
                              hint: 'Email Address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _StyledTextField(
                              controller: _phoneController,
                              hint: 'Phone Number',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F9E9A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(
                              0xFF2F9E9A,
                            ).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Booking Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick links
                      Row(
                        children: [
                          Expanded(
                            child: _QuickLinkButton(
                              label: 'My Bookings',
                              icon: Icons.bookmark_outline,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MyBookingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickLinkButton(
                              label: 'Requests',
                              icon: Icons.inbox_outlined,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BookingRequestsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ───────────────────────── Helper Widgets ─────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2F9E9A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F9E9A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2F9E9A)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick links navigate to MyBookingsScreen / BookingRequestsScreen
// from dashboard_lists_screen.dart (imported above).
