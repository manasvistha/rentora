import 'package:flutter/material.dart';
import 'package:rentora/features/dashboard/presentation/pages/profile_screen.dart';
import 'explore_screen.dart';
import 'search_screen.dart';
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
    SearchScreen(),
    MessageScreen(),
    MyFavoriteScreen(),
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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2F9E9A),
        unselectedItemColor: const Color(0xFF8E8E8E),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'My Favorite',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
