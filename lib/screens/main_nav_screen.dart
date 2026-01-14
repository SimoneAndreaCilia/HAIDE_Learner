import 'package:flutter/material.dart';

import 'arena_page.dart';
import 'profile_settings.dart';
import 'home_screen.dart'; // Import HomeScreen
import '../widgets/gamified_nav_bar.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0; // Start at Home (Gioca/Arena)

  // List of pages to display
  final List<Widget> _pages = [
    const ArenaPage(), // 0: Arene
    const HomeScreen(), // 1: Gioca (Home)
    const ProfileScreen(), // 2: Profilo
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Extend body behind the floating bar
      backgroundColor: Colors.lightBlue[50], // General background (fallback)

      body: Stack(
        children: [
          // 1. PAGE CONTENT
          IndexedStack(index: _currentIndex, children: _pages),

          // 2. FLOATING NAVIGATION BAR
          GamifiedNavBar(currentIndex: _currentIndex, onTap: _onTabTapped),
        ],
      ),
    );
  }
}
