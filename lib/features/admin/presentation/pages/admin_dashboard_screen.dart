import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import '../../domain/entities/admin_overview_entity.dart';
import 'admin_bookings_screen.dart';
import 'admin_properties_screen.dart';
import '../pages/admin_users_screen.dart';
import '../providers/admin_providers.dart';

final adminSessionProvider = FutureProvider.autoDispose<Map<String, String?>>((
  ref,
) {
  return ref.read(userSessionServiceProvider).getUserSession();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOverview = ref.watch(adminOverviewProvider);
    final asyncSession = ref.watch(adminSessionProvider);
    final sessionName = asyncSession.asData?.value['name'] ?? 'Admin';
    final sessionEmail = asyncSession.asData?.value['email'] ?? '';
    final sessionRole = asyncSession.asData?.value['role'] ?? 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Rentora Admin',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profile menu',
            onSelected: (value) async {
              if (value == 'users') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              } else if (value == 'logout') {
                await ref.read(userSessionServiceProvider).deleteSession();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      sessionEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sessionRole.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'users',
                child: Text('Manage Users'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEDE9FE),
                child: Text(
                  sessionName.isNotEmpty ? sessionName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: asyncOverview.when(
        data: (either) => either.fold(
          (failure) => _buildError(context, failure.message),
          (overview) => _buildOverview(context, ref, overview, sessionName),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
        error: (e, st) => _buildError(context, e.toString()),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: _adminNavBar(context, ref),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Text(
          'Error: $message',
          style: const TextStyle(color: Color(0xFF92400E)),
        ),
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    WidgetRef ref,
    AdminOverviewEntity o,
    String name,
  ) {
    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        ref.invalidate(adminOverviewProvider);
        await ref.read(adminOverviewProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Overview of platform activity',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statPill(
                  'Total Users',
                  o.usersCount.toString(),
                  const Color(0xFF4F46E5),
                  Icons.group,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statPill(
                  'Properties',
                  o.propertiesCount.toString(),
                  const Color(0xFF10B981),
                  Icons.home_work,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPropertiesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statPill(
                  'Monitor Bookings',
                  o.bookingsCount.toString(),
                  const Color(0xFFF59E0B),
                  Icons.event_note,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminBookingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your platform efficiently',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          _actionCard(
            context,
            color: const Color(0xFF4F46E5),
            icon: Icons.people_alt,
            title: 'Manage Users',
            subtitle: 'View, edit, and manage user accounts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _actionCard(
            context,
            color: const Color(0xFF10B981),
            icon: Icons.apartment,
            title: 'Manage Properties',
            subtitle: 'Oversee property listings and approvals',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPropertiesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _actionCard(
            context,
            color: const Color(0xFFF59E0B),
            icon: Icons.calendar_month,
            title: 'Monitor Bookings',
            subtitle: 'Review booking activity and statuses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _adminNavBar(BuildContext context, WidgetRef ref) {
    Widget navButton({
      required String label,
      required IconData icon,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: active ? const Color(0xFF4F46E5) : Colors.white,
              foregroundColor: active ? Colors.white : const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(
                color: active
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          navButton(
            label: 'Home',
            icon: Icons.home_rounded,
            active: true,
            onTap: () {
              ref.invalidate(adminOverviewProvider);
            },
          ),
          const SizedBox(width: 10),
          navButton(
            label: 'Properties',
            icon: Icons.apartment_rounded,
            active: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPropertiesScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          navButton(
            label: 'Profile',
            icon: Icons.person_rounded,
            active: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _AdminProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statPill(
    String label,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEF2FF)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminProfileScreen extends ConsumerWidget {
  const _AdminProfileScreen();

  static const _teal = Color(0xFF2F9E9A);
  static const _tealLight = Color(0xFF4AA6A6);
  static const _dark = Color(0xFF0F3D3D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSession = ref.watch(adminSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      body: asyncSession.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (session) {
          final name = session['name'] ?? 'Admin';
          final email = session['email'] ?? '';
          final role = (session['role'] ?? 'admin').toUpperCase();
          final userId = session['id'] ?? '—';
          final initials = name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE8F8F5).withOpacity(0.9),
                          const Color(0xFFEFFAF7).withOpacity(0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFAADCC4).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF083531).withOpacity(0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: _tealLight.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: _tealLight,
                              size: 20,
                            ),
                          ),
                        ),
                        const Text(
                          'Admin Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'View and manage your admin account information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _tealLight, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _teal.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: _teal,
                            child: Text(
                              initials.isNotEmpty ? initials : 'A',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F7F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Info',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Divider(height: 24),
                        _AdminInfoRow(label: 'Email', value: email),
                        const SizedBox(height: 14),
                        _AdminInfoRow(label: 'Name', value: name),
                        const SizedBox(height: 14),
                        _AdminInfoRow(label: 'User ID', value: userId),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Admin Tools',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  _AdminMenuTile(
                    icon: Icons.logout,
                    iconColor: Colors.red.shade400,
                    title: 'Sign Out',
                    subtitle: 'Securely sign out from admin account',
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Sign Out'),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true && context.mounted) {
                        await ref
                            .read(userSessionServiceProvider)
                            .deleteSession();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  const _AdminInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? const Color(0xFF4AA6A6);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EFEF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF4AA6A6).withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
