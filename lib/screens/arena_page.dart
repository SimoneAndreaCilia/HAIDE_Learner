import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/arena_widget.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'alphabet_list_screen.dart';
import 'unit_lessons_screen.dart';
import '../widgets/animated_sky_background.dart';

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  // Define Arenas Data
  final List<Map<String, dynamic>> _arenas = [
    {
      'id': 'alphabet',
      'title': 'Alphabet Arena',
      'image': 'assets/images/arena_alphabet.png',
      'color': Colors.indigo,
      'nextId': 'unit_01_survival',
    },
    {
      'id': 'unit_01_survival',
      'title': 'Survival Arena',
      'image': 'assets/images/arena_survival.png',
      'color': Color(0xFF00966E), // Green Bulgaria
      'nextId': 'unit_02_numbers_time',
    },
    {
      'id': 'unit_02_numbers_time',
      'title': 'Time Arena',
      'image': 'assets/images/arena_numberandtime.png',
      'color': Colors.blue,
      'nextId': 'unit_03_family',
    },
    {
      'id': 'unit_03_family',
      'title': 'Family & People',
      'image': 'assets/images/arena_familyandwork.png',
      'color': Color(0xFFEC407A), // Rose Damascena
      'nextId': 'unit_04_food',
    },
    {
      'id': 'unit_04_food',
      'title': 'Food & Restaurant',
      'image': 'assets/images/arena_foodrestaurant.png',
      'color': Colors.orangeAccent,
      'nextId': null, // Last for now
    },
    // Add more arenas as needed
  ];

  // Zoom state
  bool _isZooming = false;
  int _zoomingIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveArena();
    });
  }

  void _scrollToActiveArena() async {
    // Logic to find first incomplete arena
    for (int i = 0; i < _arenas.length; i++) {
      final progress = await _fetchProgressFull(_arenas[i]['id']);
      if (progress < 1.0) {
        _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
        );
        break;
      }
    }
  }

  Future<double> _fetchProgressFull(String unitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    try {
      int total = 0;
      if (unitId == 'alphabet') {
        final snap = await FirebaseFirestore.instance
            .collection('alphabet_lessons')
            .count()
            .get();
        total = snap.count ?? 0;
      } else {
        final snap = await FirebaseFirestore.instance
            .collection('courses')
            .doc(unitId)
            .collection('lessons')
            .count()
            .get();
        total = snap.count ?? 0;
      }

      if (total == 0) return 0.0;

      final progSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('learning_progress')
          .doc(unitId)
          .get();

      if (!progSnap.exists) return 0.0;
      final completed = progSnap.data()?['completed_lessons'] ?? 0;
      return (completed / total).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Alive Animated Background
          const Positioned.fill(child: AnimatedSkyBackground()),

          // Arena Content
          PageView.builder(
            controller: _pageController,
            itemCount: _arenas.length,
            scrollDirection: Axis.vertical,
            physics: _isZooming
                ? const NeverScrollableScrollPhysics() // Disable scroll while zooming
                : const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final arena = _arenas[index];
              return _buildArenaPage(context, arena, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArenaPage(
    BuildContext context,
    Map<String, dynamic> arena,
    int index,
  ) {
    return _ArenaProgressLoader(
      unitId: arena['id'],
      builder: (context, progress, isLocked) {
        return FutureBuilder<bool>(
          future: _isArenaLocked(index),
          initialData: index > 0,
          builder: (context, snapshot) {
            final locked = snapshot.data ?? (index > 0);

            // Determine if this specific arena page is zooming
            final isThisPageZooming = _isZooming && _zoomingIndex == index;

            return ArenaWidget(
              title: arena['title'],
              arenaImage: arena['image'],
              primaryColor: arena['color'],
              progress: progress,
              isLocked: locked,
              isZooming: isThisPageZooming, // Pass the zooming state
              actionLabel: locked
                  ? (Provider.of<LanguageProvider>(
                              context,
                            ).currentLocale.languageCode ==
                            'it'
                        ? "BLOCCATO"
                        : "LOCKED")
                  : (Provider.of<LanguageProvider>(
                              context,
                            ).currentLocale.languageCode ==
                            'it'
                        ? "Impara"
                        : "Learn"),
              onMainAction: () {
                if (!locked) {
                  _startZoomAndNavigate(context, arena, index);
                } else {
                  _showLockedDialog(context, arena);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _isArenaLocked(int index) async {
    if (index == 0) return false;
    final prevArenaId = _arenas[index - 1]['id'];
    final prevProgress = await _fetchProgressFull(prevArenaId);
    return prevProgress < 1.0;
  }

  void _startZoomAndNavigate(
    BuildContext context,
    Map<String, dynamic> arena,
    int index,
  ) async {
    setState(() {
      _isZooming = true;
      _zoomingIndex = index;
    });

    // Wait for the scale animation to complete (approx match the duration in ArenaWidget)
    await Future.delayed(const Duration(milliseconds: 700));

    if (!context.mounted) return;

    // Navigate with a Fade transition to feel like we are "inside"
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: arena['id'] == 'alphabet'
                ? const AlphabetListScreen()
                : UnitLessonsScreen(
                    unitId: arena['id'],
                    title: arena['title'],
                    description: "Master this topic to advance!",
                    topicColor: arena['color'],
                  ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    // Reset state when coming back
    if (mounted) {
      setState(() {
        _isZooming = false;
        _zoomingIndex = -1;
      });
    }
  }

  // Old navigate method replaced by _startZoomAndNavigate, keeping this if needed for other calls but unused now for main action
  // Old navigate method replaced by _startZoomAndNavigate, keeping this if needed for other calls but unused now for main action
  void _navigateToUnit(BuildContext context, Map<String, dynamic> arena) {
    final index = _arenas.indexWhere((element) => element['id'] == arena['id']);
    if (index != -1) {
      _startZoomAndNavigate(context, arena, index);
    }
  }

  void _showLockedDialog(BuildContext context, Map<String, dynamic> arena) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (dialogContext, anim1, anim2) {
        final isIt =
            Provider.of<LanguageProvider>(
              dialogContext,
              listen: false,
            ).currentLocale.languageCode ==
            'it';
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isIt ? "BLOCCATO!" : "LOCKED!",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIt
                          ? "Completa l'arena precedente per sbloccare questa!"
                          : "Complete the previous arena to unlock this one!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          "OK",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Use the outer 'context' (ArenaPage context) here, NOT dialogContext
                        _navigateToUnit(context, arena);
                      },
                      child: Text(
                        isIt ? "Pff, non mi interessa!" : "Pff, I don't care!",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}

class _ArenaProgressLoader extends StatefulWidget {
  final String unitId;
  final Widget Function(BuildContext, double, bool) builder;

  const _ArenaProgressLoader({required this.unitId, required this.builder});

  @override
  State<_ArenaProgressLoader> createState() => _ArenaProgressLoaderState();
}

class _ArenaProgressLoaderState extends State<_ArenaProgressLoader> {
  Future<int>? _totalLessonsFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  void _initFuture() {
    if (widget.unitId == 'alphabet') {
      _totalLessonsFuture = FirebaseFirestore.instance
          .collection('alphabet_lessons')
          .count()
          .get()
          .then((snapshot) => snapshot.count ?? 0);
    } else {
      _totalLessonsFuture = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.unitId)
          .collection('lessons')
          .count()
          .get()
          .then((snapshot) => snapshot.count ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return widget.builder(context, 0.0, true);
    }

    return FutureBuilder<int>(
      future: _totalLessonsFuture,
      builder: (context, snapshotTotal) {
        final total = snapshotTotal.data ?? 1;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('learning_progress')
              .doc(widget.unitId)
              .snapshots(),
          builder: (context, snapshot) {
            int completed = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              completed = data['completed_lessons'] ?? 0;
            }

            double progress = (total > 0)
                ? (completed / total).clamp(0.0, 1.0)
                : 0.0;
            return widget.builder(context, progress, false);
          },
        );
      },
    );
  }
}
