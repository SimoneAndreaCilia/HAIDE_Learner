// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'quiz_screen.dart';
import 'alphabet_list_screen.dart';
import 'unit_lessons_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SCHERMATA 1: LA LISTA DELLE LEZIONI (HOME) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- 1. COLORS BULGARIA MODERN ---
  static const Color greenBulgaria = Color(0xFF00966E);
  static const Color redBulgaria = Color(0xFFD62612);
  static const Color roseDamascena = Color(0xFFEC407A); // Pinkish red
  static const Color goldAntique = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Dati statici updated with "Bulgaria Modern" colors
    final List<Map<String, dynamic>> staticCards = [
      {
        'type': 'alphabet',
        'unitId': 'alphabet', // Added ID for tracking
        'color': Colors.indigo,
        'icon': null, // Custom text icon
        'title': l10n.learningPath == "Learning Path"
            ? "Bulgarian Alphabet"
            : "Alfabeto Bulgaro",
        'subtitle': l10n.learningPath == "Learning Path"
            ? "Learn the 30 letters"
            : "Impara le 30 lettere",
        'destination': const AlphabetListScreen(),
        'topicColor': Colors.indigo,
      },
      {
        'type': 'unit',
        'unitId': 'unit_01_survival',
        'color': greenBulgaria,
        'icon': Icons.explore,

        'title': isEnglish ? "Survival Guide" : "Kit di Sopravvivenza",
        'subtitle': isEnglish
            ? "Essential phrases for beginners"
            : "Frasi essenziali per principianti",
        'topicColor': greenBulgaria,
        'description': isEnglish ? 'Essential phrases' : 'Frasi essenziali',
      },
      {
        'type': 'unit',
        'unitId': 'unit_02_numbers_time',
        'color': Colors.blue,
        'icon': Icons.access_time,
        'title': isEnglish ? "Numbers and Time" : "Numeri e tempo",
        'subtitle': isEnglish
            ? "Learn to count and tell time"
            : "Impara a contare e dire l'ora",
        'topicColor': Colors.blue,
        'description': isEnglish
            ? 'Numbers, days, months'
            : 'Numeri, giorni, mesi',
      },
      {
        'type': 'unit',
        'unitId': 'unit_03_family',
        'color': roseDamascena,
        'icon': Icons.family_restroom,
        'title': isEnglish ? "Family and People" : "Famiglia e Persone",
        'subtitle': isEnglish
            ? "Family members, friends, jobs"
            : "Membri della famiglia, amici, lavoro",
        'topicColor': roseDamascena,
        'description': isEnglish ? 'Family members' : 'Membri della famiglia',
      },
      {
        'type': 'unit',
        'unitId': 'unit_04_food',
        'color': Colors.orangeAccent,
        'icon': Icons.restaurant_menu,
        'title': isEnglish ? "Food & Restaurant" : "Cibo e Ristorante",
        'subtitle': isEnglish
            ? "Ordering food and dining out"
            : "Ordinare cibo e mangiare fuori",
        'topicColor': Colors.orangeAccent,
        'description': isEnglish ? 'Food vocabulary' : 'Vocabolario del cibo',
      },
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. SLIVER APP BAR (Juicy header)
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            scrolledUnderElevation: 4,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                onPressed: () => themeProvider.toggleTheme(!isDark),
              ),
              PopupMenuButton<Locale>(
                icon: const Icon(Icons.language_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onSelected: (Locale locale) =>
                    languageProvider.changeLanguage(locale),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  const PopupMenuItem<Locale>(
                    value: Locale('it'),
                    child: Row(children: [Text('🇮🇹 Italiano')]),
                  ),
                  const PopupMenuItem<Locale>(
                    value: Locale('en'),
                    child: Row(children: [Text('🇬🇧 English')]),
                  ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9E9E9E), greenBulgaria, redBulgaria],
                      stops: [0.2, 0.5, 0.8],
                    ).createShader(bounds),
                    child: Text(
                      "Zdraveĭ",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            // Outline for visibility on white background
                            offset: Offset(0, 0),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text("👋", style: GoogleFonts.nunito(fontSize: 28)),
                ],
              ),
            ),
          ),

          // 2. LISTA MIXATA (Static + Firebase)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lezioni')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              // Preparazione lista totale
              final totalItems =
                  staticCards.length +
                  (snapshot.hasData ? snapshot.data!.docs.length : 0);

              return AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // BUILDER
                    if (index < staticCards.length) {
                      // CARTE STATICHE
                      final data = staticCards[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _ProgressWrapper(
                              unitId: data['unitId'],
                              builder: (context, progress) {
                                return _buildJuicyCard(
                                  context,
                                  isDark: isDark,
                                  color: data['color'],
                                  icon: data['icon'],
                                  title: data['title'],
                                  subtitle: data['subtitle'],
                                  progress: progress,
                                  onTap: () {
                                    if (data['type'] == 'alphabet') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => data['destination'],
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UnitLessonsScreen(
                                            unitId: data['unitId'],
                                            title: data['title'],
                                            description: data['description'],
                                            topicColor: data['topicColor'],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  isAlphabet: data['type'] == 'alphabet',
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    } else {
                      // CARTE FIREBASE
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink(); // Loading gestito altrove o invisibile
                      }

                      final docIndex = index - staticCards.length;
                      final doc = snapshot.data!.docs[docIndex];
                      final lezione = doc.data() as Map<String, dynamic>;

                      String titolo = lezione['titolo'] ?? 'Lezione';
                      if (isEnglish && lezione['titolo_en'] != null) {
                        titolo = lezione['titolo_en'];
                      }
                      final listaDomande = List<Map<String, dynamic>>.from(
                        lezione['domande'] ?? [],
                      );

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildJuicyCard(
                              context,
                              isDark: isDark,
                              color: Colors.indigo, // Default per lezioni extra
                              icon: Icons.star_rounded,
                              title: titolo,
                              subtitle: l10n.questionsCount(
                                listaDomande.length,
                              ),
                              onTap: () {
                                if (listaDomande.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizScreen(
                                        titoloLezione: titolo,
                                        domande: listaDomande,
                                        topicColor: Colors.indigo,
                                        lessonIcon: Icons.star_rounded,
                                        heroTag:
                                            'quiz_hero_$docIndex', // Semplice tag
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.lessonEmpty)),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  }, childCount: totalItems),
                ),
              );
            },
          ),

          // Spazio extra in fondo per non coprire l'ultima card
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildJuicyCard(
    BuildContext context, {
    required bool isDark,
    required Color color,
    IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAlphabet = false,
    double progress = 0.0,
  }) {
    // Colori calcolati per l'effetto "Juicy"
    final Color cardBackground = isDark
        ? const Color(0xFF2C2C2C)
        : Colors.white;
    final Color shadowColor = color.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(30), // Squircle-ish super round
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8), // Ombra morbida verso il basso
                spreadRadius: -2,
              ),
              if (!isDark) // Leggero bordo/highlight solo in light mode per definizione
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // ICONA SQUIRCLE
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        18,
                      ), // Squircle perfetto
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isAlphabet
                          ? Text(
                              "АБ",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            )
                          : Icon(icon, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // TESTI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800, // Black/Bold
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // --- 3. FLAG GRADIENT PROGRESS BAR ---
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress > 0
                                  ? progress
                                  : 0.0, // Dynamic progress
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      greenBulgaria.withValues(alpha: 0.8),
                                      redBulgaria.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FRECCIA
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressWrapper extends StatefulWidget {
  final String? unitId;
  final Widget Function(BuildContext context, double progress) builder;

  const _ProgressWrapper({this.unitId, required this.builder});

  @override
  State<_ProgressWrapper> createState() => _ProgressWrapperState();
}

class _ProgressWrapperState extends State<_ProgressWrapper> {
  Future<int>? _totalLessonsFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (widget.unitId != null && user != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unitId == null) {
      return widget.builder(context, 0.0);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return widget.builder(context, 0.0);
    }

    final unitId = widget.unitId!;

    return FutureBuilder<int>(
      future: _totalLessonsFuture,
      builder: (context, snapshot) {
        final totalLessons = snapshot.data ?? 1; // Avoid division by zero

        // STREAM BUILDER: Ascolta i cambiamenti Real-Time su Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('learning_progress')
              .doc(unitId)
              .snapshots(),
          builder: (context, snapshot) {
            int completedCount = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              completedCount = data['completed_lessons'] ?? 0;
            }

            final double progress = (totalLessons > 0)
                ? (completedCount / totalLessons).clamp(0.0, 1.0)
                : 0.0;

            return widget.builder(context, progress);
          },
        );
      },
    );
  }
}
