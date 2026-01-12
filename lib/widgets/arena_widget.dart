import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArenaWidget extends StatelessWidget {
  final String title;
  final String arenaImage; // Path to asset
  final Color
  primaryColor; // Defines the theme of the arena (e.g. Green for Survival)
  final double progress; // 0.0 to 1.0
  final bool isLocked;
  final VoidCallback onMainAction;
  final String actionLabel;
  final bool isZooming;

  const ArenaWidget({
    super.key,
    required this.title,
    required this.arenaImage,
    required this.primaryColor,
    required this.progress,
    required this.onMainAction,
    this.actionLabel = "LEARN",
    this.isLocked = false,
    this.isZooming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Tiled Background Pattern
        // 1. Tiled Background Pattern (DISABLED)
        // Positioned.fill(
        //   child: Image.asset(
        //     'assets/images/shevitsa_pattern.png',
        //     repeat: ImageRepeat.repeat,
        //     color: Colors.black.withValues(
        //       alpha: 0.05,
        //     ), // Subtle overlay to blend
        //     colorBlendMode: BlendMode.darken,
        //   ),
        // ),

        // 2. Main Content
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Arena Title (Floating Header)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // CENTRAL ARENA VISUAL
              Expanded(
                flex: 6,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind
                      AnimatedScale(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInExpo,
                        scale: isZooming ? 15.0 : 1.0,
                        child: Container(
                          width: 500, // SUPER Maximized size
                          height: 500,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.6),
                                blurRadius: 80, // Larger blur
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The Arena Image
                      AnimatedScale(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInExpo,
                        scale: isZooming ? 20.0 : 1.0,
                        child: Image.asset(
                          arenaImage,
                          fit: BoxFit.contain,
                          width: 650,
                        ),
                      ), // SUPER Maximized width
                      if (isLocked)
                        Container(
                          color: Colors.black45,
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 80,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // PROGRESS BAR (Juicy)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "MASTERY",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // 3D ACTION BUTTON
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _Juicy3DButton(
                    label: actionLabel,
                    color: isLocked ? Colors.grey : primaryColor,
                    onPressed: onMainAction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Juicy3DButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _Juicy3DButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  State<_Juicy3DButton> createState() => _Juicy3DButtonState();
}

class _Juicy3DButtonState extends State<_Juicy3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final baseColor = widget.color;
    final shadowColor = HSLColor.fromColor(
      baseColor,
    ).withLightness(0.3).toColor();

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 70, // Fixed juicy height
        width: 240,
        margin: EdgeInsets.only(top: _isPressed ? 6 : 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 10),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top highlight/shine
            Positioned(
              top: 4,
              left: 10,
              right: 10,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Text Label
            Text(
              widget.label.toUpperCase(),
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
