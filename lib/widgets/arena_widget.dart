import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gamified_bridge_map.dart';

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
                flex: 12, // More weight to the image
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind
                      AnimatedScale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn,
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
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn,
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
                    horizontal: 30, // As suggested
                    vertical: 8, // Reduced vertical padding
                  ),
                  child: GamifiedBridgeMap(
                    progress: progress,
                    trailColor: primaryColor,
                  ),
                ),
              ),

              const Spacer(
                flex: 1,
              ), // Keep this spacer for balance but reduced weight relative to arena
              // 3D ACTION BUTTON
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 5,
                  ), // Reduced from 24 to 5
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
    // We use the color to determine if it's locked (grey) or active.
    // If it's grey, we might want to show the image in greyscale or darker.
    final bool isLocked = widget.color == Colors.grey;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          // Use nearly full screen width
          width: MediaQuery.of(context).size.width * 0.60,
          // Remove fixed height, let the image aspect ratio dictate height
          // (assuming the image is the sizing anchor in the stack)
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The Button Image
              ColorFiltered(
                colorFilter: isLocked
                    ? const ColorFilter.mode(
                        Colors.grey,
                        BlendMode
                            .modulate, // Use modulate or just matrix. Let's use matrix for true grayscale if saturation was the goal.
                      )
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: isLocked
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: Image.asset(
                          'assets/images/bottone.png',
                          fit: BoxFit.fitWidth,
                          width: MediaQuery.of(context).size.width * 0.60,
                        ),
                      )
                    : Image.asset(
                        'assets/images/bottone.png',
                        fit: BoxFit.fitWidth,
                        width: MediaQuery.of(context).size.width * 0.60,
                      ),
              ),

              // Text Label
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 10.0,
                ), // Adjust for 3D depth of image if needed
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize:
                          30, // Even larger base size, but FittedBox will scale it down if needed
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
