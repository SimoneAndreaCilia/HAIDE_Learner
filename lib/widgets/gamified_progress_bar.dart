import 'package:flutter/material.dart';

class GamifiedProgressBar extends StatefulWidget {
  final double value; // Valore da 0.0 a 1.0
  final double height;
  final Color baseColor;
  final Color progressColor;
  final bool animateStripes; // Opzione per attivare/disattivare l'animazione

  const GamifiedProgressBar({
    super.key,
    required this.value,
    this.height = 25.0,
    this.baseColor = const Color(0xFFE0E0E0),
    this.progressColor = const Color(0xFF5C6BC0),
    this.animateStripes = true,
  });

  @override
  State<GamifiedProgressBar> createState() => _GamifiedProgressBarState();
}

class _GamifiedProgressBarState extends State<GamifiedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Crea un controller che si ripete all'infinito in 1 secondo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.animateStripes) {
      _controller.repeat(); // Avvia l'animazione in loop
    }
  }

  @override
  void didUpdateWidget(covariant GamifiedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateStripes != oldWidget.animateStripes) {
      if (widget.animateStripes) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Importante: rilascia il controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcola la percentuale per il testo
    int percentage = (widget.value * 100).toInt().clamp(0, 100);

    return Column(
      children: [
        // --- ETICHETTA E PERCENTUALE ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MASTERY",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                "$percentage%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: widget.progressColor,
                  shadows: [
                    Shadow(
                      color: widget.progressColor.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- LA BARRA 3D ANIMATA ---
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, // Bordo esterno bianco
            borderRadius: BorderRadius.circular(widget.height),
            boxShadow: [
              // Ombra esterna per profondità
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3), // Spessore del bordo
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double currentWidth = maxWidth * widget.value;

              return Stack(
                clipBehavior: Clip
                    .none, // Allow star to overflow slightly if needed, though we clamp
                children: [
                  // 1. Sfondo della traccia (vuoto)
                  Container(
                    width: maxWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      borderRadius: BorderRadius.circular(widget.height),
                      boxShadow: [
                        // Ombra interna per effetto "incavato"
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),

                  // 2. Il Progresso con Gradiente e Strisce
                  if (currentWidth > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(widget.height),
                      child: Container(
                        width: currentWidth,
                        height: widget.height,
                        decoration: BoxDecoration(
                          // Gradiente verticale per effetto 3D
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.progressColor.withValues(
                                alpha: 0.9,
                              ), // Luce sopra
                              widget.progressColor, // Colore base
                              Color.lerp(
                                widget.progressColor,
                                Colors.black,
                                0.2,
                              )!, // Ombra sotto
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // --- STRISCE ANIMATE ---
                            if (widget.animateStripes)
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(currentWidth, widget.height),
                                    painter: _StripesPainter(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ), // Strisce chiare
                                      animationValue: _controller.value,
                                      stripeWidth: 10.0, // Larghezza striscia
                                      stripeSpacing: 10.0, // Spazio tra strisce
                                      tilt: widget
                                          .height, // Passing height for tilt calculation
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Effetto "Glossy" (Riflesso bianco in alto)
                  if (currentWidth > 0)
                    Container(
                      width: currentWidth,
                      height: widget.height * 0.45, // Solo la metà superiore
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(widget.height),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                  // 4. Stellina/Indicatore alla fine
                  if (widget.value >= 0.08)
                    Positioned(
                      left: (currentWidth - (widget.height * 0.8)).clamp(
                        0.0,
                        maxWidth,
                      ), // Clamp to prevent overflow issues
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.amberAccent,
                            size: widget.height * 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- PAINTER PER LE STRISCE DIAGONALI ---
class _StripesPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double stripeWidth;
  final double stripeSpacing;
  final double tilt;

  _StripesPainter({
    required this.color,
    required this.animationValue,
    this.stripeWidth = 10.0,
    this.stripeSpacing = 10.0,
    required this.tilt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final patternWidth = stripeWidth + stripeSpacing;
    // Calcola l'offset basato sull'animazione per far scorrere le strisce
    final offsetX = -animationValue * patternWidth;

    // Disegna strisce sufficienti a coprire la larghezza + l'offset
    // Usiamo un loop per disegnare trapezi (strisce diagonali)
    for (double x = offsetX; x < size.width + patternWidth; x += patternWidth) {
      final path = Path()
        ..moveTo(x, 0) // Punto in alto a sinistra
        ..lineTo(x + stripeWidth, 0) // Punto in alto a destra
        ..lineTo(
          x + stripeWidth - tilt,
          size.height,
        ) // Punto in basso a destra (inclinato)
        ..lineTo(x - tilt, size.height) // Punto in basso a sinistra (inclinato)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter oldDelegate) {
    // Ridisegna solo se il valore dell'animazione cambia
    return oldDelegate.animationValue != animationValue;
  }
}
