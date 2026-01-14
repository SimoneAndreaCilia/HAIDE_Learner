import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gamified_bridge_map.dart';

class ArenaWidget extends StatelessWidget {
  final String title;
  final String arenaImage;
  final Color primaryColor;
  final double progress;
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
    this.actionLabel = "IMPARA", // Default a IMPARA
    this.isLocked = false,
    this.isZooming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Sfondo (Opzionale)
        // Positioned.fill(...),

        // 2. Contenuto Principale
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- TITOLO ARENA ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                  ), // Un po' di margine dal top
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

              // --- VISUAL CENTRALE (ISOLA) ---
              Expanded(
                flex: 10, // Bilanciato per lasciare spazio
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      AnimatedScale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn,
                        scale: isZooming ? 15.0 : 1.0,
                        child: Container(
                          width: 500,
                          height: 500,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.6),
                                blurRadius: 80,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Immagine Arena
                      AnimatedScale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn,
                        scale: isZooming ? 20.0 : 1.0,
                        child: Image.asset(
                          arenaImage,
                          fit: BoxFit.contain,
                          width:
                              MediaQuery.of(context).size.width *
                              0.9, // Adatta larghezza
                        ),
                      ),
                      if (isLocked)
                        Container(
                          width: 120, // Explicitly constrain size
                          height: 120,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 60,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- PROGRESS BAR ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: GamifiedBridgeMap(
                    progress: progress,
                    trailColor: primaryColor,
                  ),
                ),
              ),

              // --- BOTTONE 3D ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isZooming ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Juicy3DButton(
                    label: actionLabel,
                    color: isLocked ? Colors.grey : primaryColor,
                    onPressed: onMainAction,
                  ),
                ),
              ),

              // --- SPAZIO PER LA NAVBAR ---
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}

// --- WIDGET BOTTONE MIGLIORATO ---
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
          width: MediaQuery.of(context).size.width * 0.65, // Larghezza bottone
          height: 80, // Altezza fissa per stabilità
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Immagine Bottone (Senza Scritta)
              Positioned.fill(
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
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        'assets/images/bottone.png',
                        fit: BoxFit.contain,
                      ),
              ),

              // 2. Testo con Bordo (Stroke) per effetto Cartoon
              // Spostato leggermente in su (padding bottom) per stare sulla "faccia" del bottone
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
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
