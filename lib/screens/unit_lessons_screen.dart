import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/lesson_top_bar.dart';
import 'quiz_screen.dart';
import '../core/models/question.dart';
import '../core/theme/quiz_theme.dart';
import '../widgets/lesson_landscape_background.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/lesson_node_button.dart';
import '../widgets/lesson_popup_bubble.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
  int? _selectedLessonIndex;

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
    final progress = Provider.of<ProgressProvider>(context);
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
          final double calculatedHeight = documents.length * itemHeight + 280;
          final double totalHeight = math.max(size.height, calculatedHeight);

          int currentActiveIndex = 0;
          for (int i = 0; i < documents.length; i++) {
            if (i == 0 ||
                progress.isLessonCompleted(
                  widget.unitId,
                  documents[i - 1].id,
                )) {
              currentActiveIndex = i;
            } else {
              break;
            }
          }

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

              // LAYER 1.5: Goat walking – fixed top-right (Survival Arena only)

              // LAYER 2: Scrollable content (path + nodes)
              SingleChildScrollView(
                controller: _scrollController,
                physics: _selectedLessonIndex != null
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                child: SizedBox(
                  height: totalHeight,
                  width: size.width,
                  child: Stack(
                    children: [
                      if (widget.unitId == 'unit_01_survival')
                        Positioned(
                          top: 400,
                          right: 0,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/goatwalking.png',
                              width: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Tent – bottom left(Survival Arena only)
                      if (widget.unitId == 'unit_01_survival')
                        Positioned(
                          bottom: 360,
                          left: 10,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/tent.png',
                              width: 170,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Goat with numbers – right side (Time Arena only)
                      if (widget.unitId == 'unit_02_numbers_time')
                        Positioned(
                          top: 400,
                          right: 0,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/goatnumber.png',
                              width: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Time decorations – top left (Time Arena only)
                      if (widget.unitId == 'unit_02_numbers_time')
                        Positioned(
                          top: 155,
                          left: 0,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/timedecorations.png',
                              width: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Family decoration – right side (Family Arena only)
                      if (widget.unitId == 'unit_03_family')
                        Positioned(
                          top: 170,
                          right: 0,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/familydec.png',
                              width: 160,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Family kid – left side (Family Arena only)
                      if (widget.unitId == 'unit_03_family')
                        Positioned(
                          top: 300,
                          left: 35,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/familykid.png',
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // DECORATION: Grandparents – right side (Family Arena only)
                      if (widget.unitId == 'unit_03_family')
                        Positioned(
                          top: 426,
                          right: 20,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/grandparentsdec.png',
                              width: 175,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      // PATH
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
                            currentActiveIndex: currentActiveIndex,
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

                        final double top = (index * itemHeight) + 200;

                        final double left =
                            (size.width / 2 - 40) +
                            (amplitude * math.sin(index * 2.5));

                        final iconData = _getLessonIconData(lessonTitle, index);
                        final heroTag = 'lesson_icon_${widget.unitId}_$index';
                        final lessonId = documents[index].id;

                        final isCompleted = progress.isLessonCompleted(
                          widget.unitId,
                          lessonId,
                        );

                        bool isUnlocked;
                        if (index == 0) {
                          isUnlocked = true;
                        } else {
                          final prevLessonId = documents[index - 1].id;
                          isUnlocked = progress.isLessonCompleted(
                            widget.unitId,
                            prevLessonId,
                          );
                        }

                        LessonNodeState nodeState;
                        if (isCompleted) {
                          nodeState = LessonNodeState.completed;
                        } else if (isUnlocked) {
                          nodeState = LessonNodeState.current;
                        } else {
                          nodeState = LessonNodeState.locked;
                        }

                        return Positioned(
                          top: top,
                          left: left,
                          child: _buildLessonNode(
                            context,
                            index,
                            lessonTitle,
                            lessonDesc,
                            widget.topicColor,
                            iconData,
                            heroTag,
                            isDark,
                            index % 2 == 0,
                            lessonId,
                            nodeState,
                            itemHeight,
                            totalHeight,
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

              // LAYER 4: Dimming overlay
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _selectedLessonIndex == null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _selectedLessonIndex == null ? 0.0 : 1.0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLessonIndex = null;
                        });
                      },
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),

              // LAYER 5: Redrawn node + Popup (with animation)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                  child:
                      (_selectedLessonIndex == null ||
                          _selectedLessonIndex! >= documents.length)
                      ? const SizedBox.shrink(key: ValueKey('empty_popup'))
                      : Builder(
                          key: ValueKey('lesson_overlay_$_selectedLessonIndex'),
                          builder: (context) {
                            final index = _selectedLessonIndex!;
                            final lessonData =
                                documents[index].data() as Map<String, dynamic>;

                            String lessonTitle =
                                lessonData['title'] ?? 'Lesson';
                            if (isEnglish && lessonData['title_en'] != null) {
                              lessonTitle = lessonData['title_en'];
                            }

                            String lessonDesc = lessonData['description'] ?? '';
                            if (isEnglish &&
                                lessonData['description_en'] != null) {
                              lessonDesc = lessonData['description_en'];
                            }

                            final double topInCanvas =
                                (index * itemHeight) + 200;
                            final double scrollOffset =
                                _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                            final double topOnScreen =
                                topInCanvas - scrollOffset;

                            final double left =
                                (size.width / 2 - 40) +
                                (amplitude * math.sin(index * 2.5));

                            final iconData = _getLessonIconData(
                              lessonTitle,
                              index,
                            );
                            final heroTag =
                                'lesson_icon_overlay_${widget.unitId}_$index';
                            final lessonId = documents[index].id;

                            final isCompleted = progress.isLessonCompleted(
                              widget.unitId,
                              lessonId,
                            );

                            bool isUnlocked;
                            if (index == 0) {
                              isUnlocked = true;
                            } else {
                              final prevLessonId = documents[index - 1].id;
                              isUnlocked = progress.isLessonCompleted(
                                widget.unitId,
                                prevLessonId,
                              );
                            }

                            LessonNodeState nodeState;
                            if (isCompleted) {
                              nodeState = LessonNodeState.completed;
                            } else if (isUnlocked) {
                              nodeState = LessonNodeState.current;
                            } else {
                              nodeState = LessonNodeState.locked;
                            }

                            final questions = List<Map<String, dynamic>>.from(
                              lessonData['questions'] ?? [],
                            ).map((q) => Question.fromMap(q)).toList();

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // 1. Redrawn Selected Node
                                Positioned(
                                  top: topOnScreen,
                                  left: left,
                                  child: _buildLessonNode(
                                    context,
                                    index,
                                    lessonTitle,
                                    lessonDesc,
                                    widget.topicColor,
                                    iconData,
                                    heroTag,
                                    isDark,
                                    index % 2 == 0,
                                    lessonId,
                                    nodeState,
                                    itemHeight,
                                    totalHeight,
                                  ),
                                ),
                                // 2. Lesson Popup
                                Positioned(
                                  top: topOnScreen + 95,
                                  left: left - 80,
                                  child: LessonPopupBubble(
                                    title: lessonTitle,
                                    description: lessonDesc,
                                    primaryColor: widget.topicColor,
                                    isDark: isDark,
                                    startText: isEnglish
                                        ? 'START LESSON'
                                        : 'INIZIA LEZIONE',
                                    onStart: () {
                                      if (questions.isNotEmpty) {
                                        final tips = lessonData['tips'] != null
                                            ? List<Map<String, dynamic>>.from(
                                                lessonData['tips'],
                                              )
                                            : null;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => QuizScreen(
                                              titoloLezione: lessonTitle,
                                              domande: questions,
                                              tips: tips,
                                              theme: QuizTheme.fromTopic(
                                                primary: widget.topicColor,
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
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(l10n.lessonEmpty),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
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
    Color color,
    IconData iconData,
    String heroTag,
    bool isDark,
    bool isLeft,
    String? lessonId,
    LessonNodeState state,
    double itemHeight,
    double totalHeight,
  ) {
    return LessonNodeButton(
      title: title,
      description: description,
      iconData: iconData,
      primaryColor: color,
      state: state,
      heroTag: heroTag,
      isDark: isDark,
      isLeft: isLeft,
      onTap: () {
        if (state != LessonNodeState.locked) {
          setState(() {
            if (_selectedLessonIndex == index) {
              _selectedLessonIndex = null;
            } else {
              _selectedLessonIndex = index;

              // UX REFINEMENT: Scroll to center
              final double top = (index * itemHeight) + 200;
              final size = MediaQuery.of(context).size;
              final double targetOffset =
                  top - (size.height / 2) + (itemHeight / 2);
              final double maxScroll = math.max(0.0, totalHeight - size.height);

              _scrollController.animateTo(
                targetOffset.clamp(0.0, maxScroll),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      },
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
  final int currentActiveIndex;

  LevelPathPainter({
    required this.itemCount,
    required this.itemHeight,
    required this.amplitude,
    required this.pathColor,
    required this.isDark,
    required this.currentActiveIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 1) return;

    final path = Path();
    List<double> nodeYPositions = [];

    final double startX = size.width / 2;
    final double startY = 200 + 40;

    path.moveTo(startX, startY);
    nodeYPositions.add(startY);

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
      nodeYPositions.add(nextY);
    }

    // Extract path metrics safely
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    final iterator = pathMetrics.iterator;
    if (!iterator.moveNext()) return;

    final ui.PathMetric metric = iterator.current;
    final double pathLength = metric.length;

    // Stone dimensions
    const double stoneWidth = 24.0;
    const double stoneHeight = 12.0;
    const double step = 32.0; // Distance between stones

    // Colors
    final Color activeStoneColor = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFFF5F5F5);
    final Color activeStoneShadow = isDark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFFBDBDBD);

    final Color inactiveStoneColor = isDark
        ? const Color(0xFF424242)
        : const Color(0xFFEEEEEE);
    final Color inactiveStoneShadow = isDark
        ? const Color(0xFF212121)
        : const Color(0xFFE0E0E0);

    for (double distance = 0.0; distance < pathLength; distance += step) {
      final ui.Tangent? tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      // Determine active status based on Y position heading to a node
      int segmentIndex = 1;
      for (int i = 1; i < nodeYPositions.length; i++) {
        if (tangent.position.dy <= nodeYPositions[i]) {
          segmentIndex = i;
          break;
        }
      }

      bool isActive = segmentIndex <= currentActiveIndex;

      Color mainColor = isActive ? activeStoneColor : inactiveStoneColor;
      Color shadowColor = isActive ? activeStoneShadow : inactiveStoneShadow;

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);

      // Draw shadow
      final shadowRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0, 4),
          width: stoneWidth,
          height: stoneHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(shadowRRect, Paint()..color = shadowColor);

      // Draw top stone
      final mainRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: stoneWidth,
          height: stoneHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(mainRRect, Paint()..color = mainColor);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.itemHeight != itemHeight ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.isDark != isDark ||
        oldDelegate.currentActiveIndex != currentActiveIndex;
  }
}
