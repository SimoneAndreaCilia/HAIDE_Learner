import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

/// Top bar with stats and title for the lesson screen.
///
/// Shows: Bulgarian flag, streak (fire), XP (star), lightning + ∞.
/// Below the stats row, a back button and the screen title.
class LessonTopBar extends StatelessWidget {
  final String title;
  final bool isDark;

  const LessonTopBar({super.key, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final dbService = DatabaseService();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ROW 1: Stats ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: dbService.getUserDataStream(),
                  builder: (context, snapshot) {
                    int streak = 0;
                    int xp = 0;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        streak = data['current_streak'] ?? 0;
                        xp = data['xp'] ?? 0;
                      }
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bulgarian flag
                        _buildStatItem(
                          icon: _buildBulgarianFlag(),
                          label: null,
                        ),

                        // Streak (fire)
                        _buildStatItem(
                          icon: const Text(
                            '🔥',
                            style: TextStyle(fontSize: 24),
                          ),
                          label: '$streak',
                          color: Colors.orange,
                        ),

                        // XP (star)
                        _buildStatItem(
                          icon: const Text('⭐', style: TextStyle(fontSize: 24)),
                          label: '$xp',
                          color: Colors.amber,
                        ),

                        // Lightning + infinity
                        _buildStatItem(
                          icon: Icon(
                            Icons.bolt,
                            color: isDark
                                ? Colors.purpleAccent
                                : Colors.deepPurple,
                            size: 28,
                          ),
                          label: '∞',
                          color: isDark
                              ? Colors.purpleAccent
                              : Colors.deepPurple,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── ROW 2: Back + Title ──
              Padding(
                padding: const EdgeInsets.only(
                  left: 4.0,
                  right: 16.0,
                  bottom: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 24,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single stat item (icon + optional label).
  Widget _buildStatItem({required Widget icon, String? label, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label != null) ...[
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a tiny Bulgarian flag (white-green-red horizontal stripes).
  Widget _buildBulgarianFlag() {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.5),
        child: Column(
          children: [
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: const Color(0xFF00966E))),
            Expanded(child: Container(color: const Color(0xFFD62612))),
          ],
        ),
      ),
    );
  }
}
