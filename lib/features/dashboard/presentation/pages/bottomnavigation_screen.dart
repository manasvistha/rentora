import 'package:flutter/material.dart';
import 'package:rentora/core/localization/app_localizations.dart';
import 'package:rentora/features/dashboard/presentation/pages/create_property_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/profile_screen.dart';
import 'explore_screen.dart';
import 'message_screen.dart';
import 'myfavorite_screen.dart';

class BottomnavigationScreen extends StatefulWidget {
  const BottomnavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BottomnavigationScreen> createState() => _BottomnavigationScreenState();
}

class _BottomnavigationScreenState extends State<BottomnavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    MyFavoriteScreen(),
    MessageScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
          ),
        ),
        child: _screens[_selectedIndex],
      ),

      // Floating Action Button for Add Property
      floatingActionButton: SizedBox(
        width: 85,
        height: 85,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
            );
          },
          backgroundColor: const Color(0xFF2F9E9A),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: const _FixedCenterDockedFabLocation(),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: context.tr('discover'),
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  label: context.tr('matches'),
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 48), // Space for the FAB
                _NavBarItem(
                  icon: Icons.message_outlined,
                  activeIcon: Icons.message,
                  label: context.tr('messages'),
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: context.tr('profile'),
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _FixedCenterDockedFabLocation();

  static const double _bottomBarHeight = 64;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final fabX = (scaffoldGeometry.scaffoldSize.width - fabWidth) / 2;

    // Keep FAB anchored to the bottom app bar position, independent of snackbars.
    final safeBottom = scaffoldGeometry.minViewPadding.bottom;
    final fabY =
        scaffoldGeometry.scaffoldSize.height -
        safeBottom -
        _bottomBarHeight -
        (fabHeight / 2);

    return Offset(fabX, fabY);
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF2F9E9A)
                  : const Color(0xFF8E8E8E),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF2F9E9A)
                    : const Color(0xFF8E8E8E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
