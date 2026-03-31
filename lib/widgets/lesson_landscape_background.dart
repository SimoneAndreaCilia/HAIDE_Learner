import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A sky background for the lesson path screen.
///
/// Paints a sky gradient with clouds and a parallax effect driven by
/// [scrollOffset]. Supports light/dark mode (day/night with stars).
class LessonLandscapeBackground extends StatelessWidget {
  final double scrollOffset;
  final double totalHeight;
  final bool isDark;

  const LessonLandscapeBackground({
    super.key,
    required this.scrollOffset,
    required this.totalHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkyPainter(
        scrollOffset: scrollOffset,
        totalHeight: totalHeight,
        isDark: isDark,
      ),
      size: Size.infinite,
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double scrollOffset;
  final double totalHeight;
  final bool isDark;

  _SkyPainter({
    required this.scrollOffset,
    required this.totalHeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final scrollRatio = (totalHeight > 0)
        ? (scrollOffset / totalHeight).clamp(0.0, 1.0)
        : 0.0;

    _drawSky(canvas, w, h, scrollRatio);
    _drawClouds(canvas, w, h, scrollRatio);
    if (isDark) _drawStars(canvas, w, h, scrollRatio);
  }

  // ─── 1. SKY GRADIENT ─────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, double w, double h, double scrollRatio) {
    final topColor = isDark ? AppColors.nightSkyDeep : AppColors.skyHigh;
    final bottomColor = isDark ? AppColors.nightSkyMid : AppColors.skyPale;

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);
  }

  // ─── 2. CLOUDS ────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, double w, double h, double scrollRatio) {
    final cloudColor = isDark
        ? Colors.grey.shade800.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.7);

    // Parallax: clouds move slowly (0.15x)
    final parallaxOffset = scrollOffset * 0.15;

    final clouds = [
      Offset(w * 0.1, h * 0.05 + parallaxOffset * 0.3),
      Offset(w * 0.55, h * 0.08 + parallaxOffset * 0.2),
      Offset(w * 0.3, h * 0.18 + parallaxOffset * 0.25),
      Offset(w * 0.75, h * 0.22 + parallaxOffset * 0.15),
      Offset(w * 0.15, h * 0.32 + parallaxOffset * 0.2),
      Offset(w * 0.6, h * 0.38 + parallaxOffset * 0.18),
    ];

    for (final center in clouds) {
      _drawSingleCloud(canvas, center, cloudColor, w * 0.15);
    }
  }

  void _drawSingleCloud(
      Canvas canvas, Offset center, Color color, double baseSize) {
    final paint = Paint()..color = color;

    // A cloud is a cluster of overlapping circles
    final r = baseSize * 0.3;
    canvas.drawCircle(center, r * 1.0, paint);
    canvas.drawCircle(center + Offset(-r * 0.8, r * 0.1), r * 0.8, paint);
    canvas.drawCircle(center + Offset(r * 0.8, r * 0.15), r * 0.85, paint);
    canvas.drawCircle(center + Offset(-r * 0.3, -r * 0.5), r * 0.7, paint);
    canvas.drawCircle(center + Offset(r * 0.4, -r * 0.4), r * 0.75, paint);
  }

  // ─── 3. STARS (dark mode only) ────────────────────────────────────────────

  void _drawStars(Canvas canvas, double w, double h, double scrollRatio) {
    final rng = Random(7); // Fixed seed
    final starPaint = Paint()..color = AppColors.starWhite;

    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.55 + scrollOffset * 0.1;
      final radius = 0.5 + rng.nextDouble() * 1.5;
      final alpha = 0.4 + rng.nextDouble() * 0.6;

      starPaint.color = AppColors.starWhite.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    // A few bigger twinkling stars
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.4 + scrollOffset * 0.08;
      _drawTwinkleStar(canvas, Offset(x, y), 3.0 + rng.nextDouble() * 2.0);
    }
  }

  void _drawTwinkleStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Simple cross pattern for twinkling
    canvas.drawLine(
      center + Offset(-size, 0),
      center + Offset(size, 0),
      paint,
    );
    canvas.drawLine(
      center + Offset(0, -size),
      center + Offset(0, size),
      paint,
    );

    // Dot in center
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.isDark != isDark ||
        oldDelegate.totalHeight != totalHeight;
  }
}
