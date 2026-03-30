import 'package:flutter/material.dart';
import 'dart:ui';

enum LessonNodeState { locked, current, completed }

/// A 3D pushable button for lesson path nodes.
class LessonNodeButton extends StatefulWidget {
  final String title;
  final String description;
  final IconData iconData;
  final Color primaryColor;
  final LessonNodeState state;
  final String heroTag;
  final bool isDark;
  final bool isLeft;
  final VoidCallback onTap;

  const LessonNodeButton({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.primaryColor,
    required this.state,
    required this.heroTag,
    required this.isDark,
    required this.isLeft,
    required this.onTap,
  });

  @override
  State<LessonNodeButton> createState() => _LessonNodeButtonState();
}

class _LessonNodeButtonState extends State<LessonNodeButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    if (widget.state == LessonNodeState.current) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LessonNodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == LessonNodeState.current &&
        oldWidget.state != LessonNodeState.current) {
      _glowController.repeat(reverse: true);
    } else if (widget.state != LessonNodeState.current &&
        oldWidget.state == LessonNodeState.current) {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocked = widget.state == LessonNodeState.locked;
    final bool isCompleted = widget.state == LessonNodeState.completed;
    final bool isCurrent = widget.state == LessonNodeState.current;

    // Colors mapping
    Color buttonColor;
    Color shadowColor;
    IconData displayIcon;

    if (isLocked) {
      buttonColor = widget.isDark ? Colors.grey[800]! : Colors.grey[400]!;
      shadowColor = widget.isDark ? Colors.grey[900]! : Colors.grey[500]!;
      displayIcon = Icons.lock_rounded;
    } else if (isCompleted) {
      buttonColor = Colors.amber;
      shadowColor = Colors.orange[700]!;
      displayIcon = widget.iconData;
    } else {
      // Current
      buttonColor = widget.primaryColor;
      // Darken primary for shadow
      final hsl = HSLColor.fromColor(buttonColor);
      shadowColor = hsl
          .withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0))
          .toColor();
      displayIcon = widget.iconData;
    }

    // 3D effect parameters
    final double pushDepth = 8.0;
    final double currentPush = _isPressed && !isLocked ? pushDepth : 0.0;

    return GestureDetector(
      onTapDown: isLocked ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isLocked
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
      onTapCancel: isLocked ? null : () => setState(() => _isPressed = false),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ---- LESSON BUTTON WITH 3D PUSH EFFECT ----
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Padding(
                padding: EdgeInsets.only(top: currentPush),
                child: Container(
                  width: isCurrent ? 86 : 80,
                  height: isCurrent ? 86 : 80,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Inner/Lower 3D shadow
                      BoxShadow(
                        color: shadowColor,
                        offset: Offset(
                          0,
                          pushDepth - currentPush,
                        ), // Shrinks when pressed
                        blurRadius: 0, // Sharp shadow for 3D effect
                        spreadRadius: 0,
                      ),
                      // Outer glow if current
                      if (isCurrent)
                        BoxShadow(
                          color: buttonColor.withValues(
                            alpha: 0.6 * _glowAnimation.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 4 * _glowAnimation.value,
                        ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: isCurrent ? 4 : 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  // The icon is wrapped in Hero if not locked
                  child: isLocked
                      ? Icon(
                          displayIcon,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 36,
                        )
                      : Hero(
                          tag: widget.heroTag,
                          child: Icon(
                            displayIcon,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                ),
              );
            },
          ),

          // ---- LESSON LABEL CARD WITH GLASSMORPHISM ----
          Positioned(
            // Move label slightly down when pressed to match button
            top: 20 + currentPush * 0.5,
            left: widget.isLeft ? 100 : -140,
            child: _buildLabelCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: widget.isDark ? Colors.white : Colors.black87,
                  shadows: widget.isDark
                      ? null
                      : [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 2,
                          ),
                        ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: widget.isLeft ? TextAlign.start : TextAlign.end,
              ),
              if (widget.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: widget.isLeft ? TextAlign.start : TextAlign.end,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
