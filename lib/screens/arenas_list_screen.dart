import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart'; // Import LanguageProvider
import '../widgets/animated_sky_background.dart';

class ArenaData {
  final String id;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String imagePath;
  final Color color;
  final bool isLocked;
  final double progress;

  ArenaData({
    required this.id,
    required this.titles,
    required this.descriptions,
    required this.imagePath,
    required this.color,
    required this.isLocked,
    required this.progress,
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

  Future<List<ArenaData>> _loadArenas() async {
    List<ArenaData> loadedArenas = [];
    // bool previousLocked = false; // Removed unused

    for (int i = 0; i < _arenasBase.length; i++) {
      final data = _arenasBase[i];
      final id = data['id'] as String;

      // Calculate lock state based on PREVIOUS arena's progress
      // If it's the first arena, it's unlocked.
      // If it's 2nd+, it's locked if prev arena is not complete.
      bool isLocked = false;
      if (i > 0) {
        // Check previous arena
        final prevId = _arenasBase[i - 1]['id'] as String;
        final prevProgress = await _fetchProgressFull(prevId);
        if (prevProgress < 1.0) {
          isLocked = true;
        }
      }

      // Fetch current progress
      final progress = await _fetchProgressFull(id);

      loadedArenas.add(
        ArenaData(
          id: id,
          titles: data['titles'],
          descriptions: data['descriptions'],
          imagePath: data['image'],
          color: data['color'],
          isLocked: isLocked,
          progress: progress,
        ),
      );
    }
    return loadedArenas;
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
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          100,
                        ), // Bottom padding for nav bar
                        itemCount: arenas.length,
                        itemBuilder: (context, index) {
                          return ArenaListCard(
                            arena: arenas[index],
                            onTap: () => _navigateToArena(arenas[index], index),
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
  final VoidCallback onTap;

  const ArenaListCard({super.key, required this.arena, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.currentLocale.languageCode;

    // Se è bloccata, usiamo toni di grigio
    final bool isLocked = arena.isLocked;
    final Color themeColor = isLocked ? Colors.grey : arena.color;

    return GestureDetector(
      onTap: isLocked
          ? null
          : onTap, // Se bloccata non fa nulla (o mostra un dialog)
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // Spazio tra le card
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1), // Ombra color cielo
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
                        color: isLocked ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arena.getDescription(lang),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                          value: arena.progress,
                          backgroundColor: themeColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          strokeWidth: 5,
                        ),
                        Text(
                          "${(arena.progress * 100).toInt()}%",
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
