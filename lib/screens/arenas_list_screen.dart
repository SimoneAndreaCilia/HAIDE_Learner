import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart'; // Import LanguageProvider
import '../providers/progress_provider.dart';
import '../widgets/animated_sky_background.dart';

class ArenaData {
  final String id;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String imagePath;
  final Color color;

  /// Total lessons in this arena (cached from Firestore content).
  final int totalLessons;

  ArenaData({
    required this.id,
    required this.titles,
    required this.descriptions,
    required this.imagePath,
    required this.color,
    required this.totalLessons,
  });

  String getTitle(String lang) => titles[lang] ?? titles['en'] ?? '';
  String getDescription(String lang) =>
      descriptions[lang] ?? descriptions['en'] ?? '';
}

class ArenasListScreen extends StatefulWidget {
  final Function(int) onArenaSelected;
  const ArenasListScreen({super.key, required this.onArenaSelected});

  @override
  State<ArenasListScreen> createState() => _ArenasListScreenState();
}

class _ArenasListScreenState extends State<ArenasListScreen>
    with AutomaticKeepAliveClientMixin {
  // Define base data with translations
  final List<Map<String, dynamic>> _arenasBase = [
    {
      'id': 'alphabet',
      'titles': {'en': 'Alphabet Arena', 'it': 'Arena Alfabeto'},
      'descriptions': {
        'en': 'Master the Cyrillic alphabet and pronunciation.',
        'it': 'Padroneggia l\'alfabeto cirillico e la pronuncia.',
      },
      'image': 'assets/images/arena_alphabet.png',
      'color': Colors.indigo,
    },
    {
      'id': 'unit_01_survival',
      'titles': {'en': 'Survival Arena', 'it': 'Arena Sopravvivenza'},
      'descriptions': {
        'en': 'Essential phrases for everyday survival.',
        'it': 'Frasi essenziali per la sopravvivenza quotidiana.',
      },
      'image': 'assets/images/arena_survival.png',
      'color': const Color(0xFF00966E), // Green Bulgaria
    },
    {
      'id': 'unit_02_numbers_time',
      'titles': {'en': 'Time Arena', 'it': 'Arena Tempo'},
      'descriptions': {
        'en': 'Learn numbers, dates, and telling time.',
        'it': 'Impara numeri, date e l\'ora.',
      },
      'image': 'assets/images/arena_numberandtime.png',
      'color': Colors.blue,
    },
    {
      'id': 'unit_03_family',
      'titles': {'en': 'Family & People', 'it': 'Famiglia e Persone'},
      'descriptions': {
        'en': 'Talk about family members and people.',
        'it': 'Parla di familiari e persone.',
      },
      'image': 'assets/images/arena_familyandwork.png',
      'color': const Color(0xFFEC407A), // Rose Damascena
    },
    {
      'id': 'unit_04_food',
      'titles': {'en': 'Food & Restaurant', 'it': 'Cibo e Ristorante'},
      'descriptions': {
        'en': 'Order food and navigate restaurants.',
        'it': 'Ordina cibo e orientati nei ristoranti.',
      },
      'image': 'assets/images/arena_foodrestaurant.png',
      'color': Colors.orangeAccent,
    },
  ];

  late Future<List<ArenaData>> _arenasFuture;

  @override
  void initState() {
    super.initState();
    _arenasFuture = _loadArenas();
  }

  /// Loads arena structure + total lesson counts (cached once).
  /// Progress is NOT baked in — it's computed live in build().
  Future<List<ArenaData>> _loadArenas() async {
    List<ArenaData> loadedArenas = [];

    for (int i = 0; i < _arenasBase.length; i++) {
      final data = _arenasBase[i];
      final id = data['id'] as String;

      // Fetch total lessons count from Firestore content
      final total = await _fetchTotalLessons(id);

      loadedArenas.add(
        ArenaData(
          id: id,
          titles: data['titles'],
          descriptions: data['descriptions'],
          imagePath: data['image'],
          color: data['color'],
          totalLessons: total,
        ),
      );
    }
    return loadedArenas;
  }

  /// Fetches the total number of lessons for a given arena from Firestore.
  Future<int> _fetchTotalLessons(String unitId) async {
    try {
      if (unitId == 'alphabet') {
        final snap = await FirebaseFirestore.instance
            .collection('alphabet_lessons')
            .count()
            .get();
        return snap.count ?? 0;
      } else {
        final snap = await FirebaseFirestore.instance
            .collection('courses')
            .doc(unitId)
            .collection('lessons')
            .count()
            .get();
        return snap.count ?? 0;
      }
    } catch (e) {
      return 0;
    }
  }

  void _navigateToArena(ArenaData arena, int index) {
    // Navigate to the ArenaPage tab and scroll to this arena
    widget.onArenaSelected(index);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isIt = languageProvider.currentLocale.languageCode == 'it';

    return Scaffold(
      body: Stack(
        children: [
          // Background
          const Positioned.fill(child: AnimatedSkyBackground()),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    isIt ? "Arene" : "Arenas",
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<ArenaData>>(
                    future: _arenasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading arenas',
                            style: GoogleFonts.nunito(color: Colors.white),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No arenas found',
                            style: GoogleFonts.nunito(color: Colors.white),
                          ),
                        );
                      }

                      final arenas = snapshot.data!;

                      // Wrap in Consumer so progress updates trigger rebuild
                      return Consumer<ProgressProvider>(
                        builder: (context, progressProvider, _) {
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: arenas.length,
                            itemBuilder: (context, index) {
                              final arena = arenas[index];
                              final completed = progressProvider
                                  .getCompletedLessonsCount(arena.id);
                              final progress = arena.totalLessons > 0
                                  ? (completed / arena.totalLessons).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0.0;

                              // Lock if previous arena isn't 100% complete
                              bool isLocked = false;
                              if (index > 0) {
                                final prev = arenas[index - 1];
                                final prevCompleted = progressProvider
                                    .getCompletedLessonsCount(prev.id);
                                final prevProgress = prev.totalLessons > 0
                                    ? prevCompleted / prev.totalLessons
                                    : 0.0;
                                isLocked = prevProgress < 1.0;
                              }

                              return ArenaListCard(
                                arena: arena,
                                progress: progress,
                                isLocked: isLocked,
                                onTap: () => _navigateToArena(arena, index),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArenaListCard extends StatelessWidget {
  final ArenaData arena;
  final double progress;
  final bool isLocked;
  final VoidCallback onTap;

  const ArenaListCard({
    super.key,
    required this.arena,
    required this.progress,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final lang = languageProvider.currentLocale.languageCode;

    final Color themeColor = isLocked ? Colors.grey : arena.color;

    return GestureDetector(
      onTap: isLocked
          ? null
          : onTap, // Se bloccata non fa nulla (o mostra un dialog)
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // Spazio tra le card
        height: 100,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.blue.withValues(alpha: 0.1), // Ombra color cielo
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- 1. IMMAGINE (Sinistra) ---
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1), // Sfondo leggero
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: isLocked
                  ? Icon(Icons.lock, color: Colors.grey[400], size: 40)
                  : Image.asset(arena.imagePath, fit: BoxFit.contain),
            ),

            // --- 2. TESTO E DESCRIZIONE (Centro) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      arena.getTitle(lang).toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isLocked
                            ? (isDarkMode ? Colors.grey[600] : Colors.grey[600])
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arena.getDescription(lang),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // --- 3. PROGRESSO (Destra) ---
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLocked)
                    Text(
                      lang == 'it' ? "BLOCCATO" : "LOCKED",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    )
                  else ...[
                    // Circular Progress Indicator personalizzato
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: themeColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          strokeWidth: 5,
                        ),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
