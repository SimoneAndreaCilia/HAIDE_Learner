import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/lesson_top_bar.dart';
import 'quiz_screen.dart';
import '../core/models/question.dart';
import '../core/theme/quiz_theme.dart';
import '../widgets/lesson_landscape_background.dart';
import 'dart:math' as math;
import 'dart:ui';

class UnitLessonsScreen extends StatefulWidget {
  final String unitId;
  final String title;
  final String description;
  final Color topicColor;

  const UnitLessonsScreen({
    super.key,
    required this.unitId,
    required this.title,
    required this.description,
    required this.topicColor,
  });

  @override
  State<UnitLessonsScreen> createState() => _UnitLessonsScreenState();
}

class _UnitLessonsScreenState extends State<UnitLessonsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // Trigger repaint of the landscape background
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.unitId)
            .collection('lessons')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lessonEmpty,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          const double itemHeight = 140.0;
          const double amplitude = 70.0;
          final double totalHeight = documents.length * itemHeight + 280;

          return Stack(
            children: [
              // LAYER 1: Landscape background with parallax
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, _) {
                    return LessonLandscapeBackground(
                      scrollOffset: _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0,
                      totalHeight: totalHeight,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              // LAYER 2: Scrollable content (path + nodes)
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: totalHeight,
                  width: size.width,
                  child: Stack(
                    children: [
                      // PERCORSO
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LevelPathPainter(
                            itemCount: documents.length,
                            itemHeight: itemHeight,
                            amplitude: amplitude,
                            pathColor: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.35),
                            isDark: isDark,
                          ),
                        ),
                      ),

                      // NODI
                      ...List.generate(documents.length, (index) {
                        final lessonData =
                            documents[index].data() as Map<String, dynamic>;

                        String lessonTitle = lessonData['title'] ?? 'Lesson';
                        if (isEnglish && lessonData['title_en'] != null) {
                          lessonTitle = lessonData['title_en'];
                        }

                        String lessonDesc = lessonData['description'] ?? '';
                        if (isEnglish && lessonData['description_en'] != null) {
                          lessonDesc = lessonData['description_en'];
                        }

                        final questions = List<Map<String, dynamic>>.from(
                          lessonData['questions'] ?? [],
                        ).map((q) => Question.fromMap(q)).toList();

                        final double top = (index * itemHeight) + 200;

                        final double left =
                            (size.width / 2 - 40) +
                            (amplitude * math.sin(index * 2.5));

                        final iconData = _getLessonIconData(lessonTitle, index);
                        final heroTag = 'lesson_icon_${widget.unitId}_$index';

                        return Positioned(
                          top: top,
                          left: left,
                          child: _buildLessonNode(
                            context,
                            index,
                            lessonTitle,
                            lessonDesc,
                            questions,
                            widget.topicColor,
                            iconData,
                            lessonData,
                            l10n,
                            heroTag,
                            isDark,
                            index % 2 == 0,
                            documents[index].id,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // LAYER 3: Fixed top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LessonTopBar(title: widget.title, isDark: isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLessonNode(
    BuildContext context,
    int index,
    String title,
    String description,
    List<Question> questions,
    Color color,
    IconData iconData,
    Map<String, dynamic> lessonData,
    AppLocalizations l10n,
    String heroTag,
    bool isDark,
    bool isLeft,
    String? lessonId,
  ) {
    return GestureDetector(
      onTap: () {
        if (questions.isNotEmpty) {
          final tips = lessonData['tips'] != null
              ? List<Map<String, dynamic>>.from(lessonData['tips'])
              : null;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                titoloLezione: title,
                domande: questions,
                tips: tips,
                theme: QuizTheme.fromTopic(
                  primary: color,
                  icon: iconData,
                  heroTag: heroTag,
                ),
                unitId: widget.unitId,
                lessonId: lessonId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.lessonEmpty)));
        }
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Lesson circle node with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 1.0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 4,
                  ),
                ),
                child: Hero(
                  tag: heroTag,
                  child: Icon(iconData, color: Colors.white, size: 36),
                ),
              ),

              // Lesson label card with glassmorphism
              Positioned(
                top: 20,
                left: isLeft ? 90 : -140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                              shadows: isDark
                                  ? null
                                  : [
                                      Shadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 2,
                                      ),
                                    ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isLeft ? TextAlign.start : TextAlign.end,
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: isLeft
                                  ? TextAlign.start
                                  : TextAlign.end,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getLessonIconData(String title, int index) {
    bool contains(String keyword) =>
        title.toLowerCase().contains(keyword.toLowerCase());

    if (contains('Saluti') || contains('Greetings')) {
      return Icons.waving_hand;
    }
    if (contains('Cortesia') || contains('Cortesy') || contains('Courtesy')) {
      return Icons.handshake;
    }
    if (contains('Barriere') || contains('Barriers')) {
      return Icons.translate;
    }
    if (contains('Bisogni') || contains('Needs')) {
      return Icons.local_dining;
    }
    if (contains('Emergenze') || contains('Emergencies')) {
      return Icons.emergency;
    }
    if (contains('Presentazioni') || contains('Introductions')) {
      return Icons.people;
    }
    if (contains('Numeri') || contains('Numbers')) {
      return Icons.filter_1;
    }
    if (contains('Giorni') ||
        contains('Days') ||
        contains('Settimana') ||
        contains('Week')) {
      return Icons.calendar_month;
    }
    if (contains('Momenti') || contains('Times')) {
      return Icons.access_time;
    }
    if (contains('Nucleo') ||
        contains('Immediate Family') ||
        contains('Famiglia') ||
        contains('Family')) {
      return Icons.family_restroom;
    }
    if (contains('Amici') || contains('Friends')) {
      return Icons.group;
    }
    if (contains('Aggettivi') || contains('Adjectives')) {
      return Icons.auto_awesome;
    }
    if (contains('Professioni') || contains('Professions')) {
      return Icons.work;
    }
    if (contains('Bevande') || contains('Drinks')) {
      return Icons.local_cafe;
    }
    if (contains('Frutta') || contains('Fruit') || contains('Verdura')) {
      return Icons.eco;
    }
    if (contains('Ristorante') || contains('Restaurant')) {
      return Icons.restaurant;
    }
    if (contains('Cibi') || contains('Food')) {
      return Icons.dinner_dining;
    }

    return Icons.star;
  }
}

class LevelPathPainter extends CustomPainter {
  final int itemCount;
  final double itemHeight;
  final double amplitude;
  final Color pathColor;
  final bool isDark;

  LevelPathPainter({
    required this.itemCount,
    required this.itemHeight,
    required this.amplitude,
    required this.pathColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 0) return;

    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final double startX = size.width / 2;
    final double startY = 200 + 40;

    path.moveTo(startX, startY);

    for (int i = 0; i < itemCount - 1; i++) {
      double nextY = ((i + 1) * itemHeight) + 200 + 40;
      double nextXOffset = amplitude * math.sin((i + 1) * 2.5);
      double nextX = (size.width / 2) + nextXOffset;

      double currentY = ((i) * itemHeight) + 200 + 40;
      double currentX = (size.width / 2) + (amplitude * math.sin(i * 2.5));

      double cp1x = currentX;
      double cp1y = currentY + (itemHeight / 2);

      double cp2x = nextX;
      double cp2y = nextY - (itemHeight / 2);

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, nextX, nextY);
    }

    canvas.drawPath(path, paint);

    // Subtle glow border for the path
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
