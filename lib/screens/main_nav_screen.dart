import 'package:flutter/material.dart';

import 'arena_page.dart';
import 'profile_settings.dart';
import 'arenas_list_screen.dart'; // Import ArenasListScreen
import '../widgets/gamified_nav_bar.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0; // Start at Home (Gioca/Arena)

  // List of pages to display
  final GlobalKey<ArenaPageState> _arenaKey = GlobalKey<ArenaPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ArenaPage(key: _arenaKey), // 0: Arene (Swipe)
      ArenasListScreen(
        onArenaSelected: (index) {
          // Switch to tab 0
          setState(() {
            _currentIndex = 0;
          });
          // Scroll to the selected arena
          // Using a post-frame callback to ensure the widget is built if we just switched tabs
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _arenaKey.currentState?.goToPage(index);
          });
        },
      ), // 1: Arene (Lista)
      const ProfileScreen(), // 2: Profilo
    ];
  }

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
