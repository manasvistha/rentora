import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import 'package:rentora/features/dashboard/presentation/pages/profile_screen.dart';
import '../../domain/entities/admin_overview_entity.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_customize, color: Colors.white),
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
          _adminNavBar(context, ref),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statPill(
                'Total Users',
                o.usersCount.toString(),
                const Color(0xFF4F46E5),
                Icons.group,
              ),
              _statPill(
                'Properties',
                o.propertiesCount.toString(),
                const Color(0xFF10B981),
                Icons.home_work,
              ),
              _statPill(
                'Bookings',
                o.bookingsCount.toString(),
                const Color(0xFFF59E0B),
                Icons.event_note,
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
            title: 'Manage Bookings',
            subtitle: 'Review booking activity and statuses',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookings screen coming soon')),
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
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 17),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: active ? const Color(0xFF4F46E5) : Colors.white,
              foregroundColor: active ? Colors.white : const Color(0xFF64748B),
              side: BorderSide(
                color: active
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
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
