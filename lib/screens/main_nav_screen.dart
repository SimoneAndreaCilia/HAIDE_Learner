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
  // PageView Controller
  // Start at index 1 (Play/Gioca) which corresponds to Nav Index 0
  final PageController _pageController = PageController(initialPage: 1);

  // We need to keep track of the Nav Bar index separately to update the UI
  int _currentNavIndex = 0; // 0 = Play (Gioca)

  // List of pages to display in Visual Order (Left -> Right)
  // Page 0: Arene
  // Page 1: Gioca (Center)
  // Page 2: Profilo
  final GlobalKey<ArenaPageState> _arenaKey = GlobalKey<ArenaPageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ArenasListScreen(
        onArenaSelected: (index) {
          // Navigate to "Gioca" (Page 1)
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // Scroll to the selected arena
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _arenaKey.currentState?.goToPage(index);
          });
        },
      ), // Page 0: Arene
      ArenaPage(key: _arenaKey), // Page 1: Gioca
      const ProfileScreen(), // Page 2: Profilo
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Map Nav Bar Index (0=Play, 1=Arenas, 2=Profile) to PageView Index (0=Arenas, 1=Play, 2=Profile)
  int _navIndexToPage(int navIndex) {
    switch (navIndex) {
      case 0:
        return 1; // Play -> Center Page
      case 1:
        return 0; // Arenas -> Left Page
      case 2:
        return 2; // Profile -> Right Page
      default:
        return 1;
    }
  }

  // Map PageView Index to Nav Bar Index
  int _pageToNavIndex(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 1; // Left Page -> Arenas
      case 1:
        return 0; // Center Page -> Play
      case 2:
        return 2; // Right Page -> Profile
      default:
        return 0;
    }
  }

  void _onTabTapped(int navIndex) {
    // When Nav Bar is tapped, animate PageView to corresponding page
    final pageIndex = _navIndexToPage(navIndex);
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int pageIndex) {
    // When PageView is swiped, update Nav Bar state
    setState(() {
      _currentNavIndex = _pageToNavIndex(pageIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Extend body behind the floating bar
      backgroundColor: Colors.lightBlue[50],
      body: Stack(
        children: [
          // 1. PAGE CONTENT (Swipeable)
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(), // Nice bounce effect
            children: _pages,
          ),

          // 2. FLOATING NAVIGATION BAR
          GamifiedNavBar(currentIndex: _currentNavIndex, onTap: _onTabTapped),
        ],
      ),
    );
  }
}
