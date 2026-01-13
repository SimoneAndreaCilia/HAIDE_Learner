import 'package:flutter/material.dart';
import 'dart:ui'; // Per PathMetrics
import 'package:google_fonts/google_fonts.dart';

class GamifiedBridgeMap extends StatefulWidget {
  final double progress; // Valore da 0.0 a 1.0 (es. 0.2 per 20%)
  final Color trailColor; // Colore della scia

  const GamifiedBridgeMap({
    super.key,
    required this.progress,
    this.trailColor = Colors.cyanAccent,
  });

  @override
  State<GamifiedBridgeMap> createState() => _GamifiedBridgeMapState();
}

class _GamifiedBridgeMapState extends State<GamifiedBridgeMap>
    with SingleTickerProviderStateMixin {
  // Controller per animare la capra quando il progresso cambia
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(GamifiedBridgeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: 0.0,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder serve per adattare il percorso alle dimensioni dello schermo
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Altezza stimata in base all'aspect ratio del tuo disegno (es. 16:9 o simile)
        final height =
            width *
            0.4; // Ridotto un po' da 0.6 per non occupare troppo spazio, ma da verificare con l'immagine reale

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none, // Permette alla capra di uscire dai bordi
            children: [
              // 1. L'IMMAGINE DI SFONDO (Il ponte vuoto)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bulgarianprogressbar.png',
                  fit: BoxFit.contain,
                ),
              ),

              // 2. LA SCIA LUMINOSA E LA CAPRA
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PathPainter(
                            progress: _animation.value,
                            debugMode: false,
                            color: widget.trailColor,
                          ),
                        ),
                      ),
                      _buildGoatPositioned(width, height, _animation.value),
                    ],
                  );
                },
              ),

              // 3. I CARTIGLI (Mastery e %)
              Positioned(top: -10, left: 10, child: _buildScrollLabel("ПЪТ")),
              Positioned(
                top: -10,
                right: 10,
                child: _buildScrollLabel("${(widget.progress * 100).toInt()}%"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Funzione che calcola dove mettere la capra
  Widget _buildGoatPositioned(
    double width,
    double height,
    double currentProgress,
  ) {
    if (width <= 0 || height <= 0) return const SizedBox();

    final Path path = getBridgePath(Size(width, height));

    // Calcoliamo la posizione lungo il percorso
    final List<PathMetric> metrics = path.computeMetrics().toList();
    // Safety check se il path è vuoto o invalido
    if (metrics.isEmpty) return const SizedBox();

    final PathMetric pathMetric = metrics.first;
    final Tangent? tangent = pathMetric.getTangentForOffset(
      pathMetric.length * currentProgress,
    );

    if (tangent == null) return const SizedBox();

    final Offset pos = tangent.position;

    return Positioned(
      left: pos.dx - 30, // -30 per centrare l'immagine della capra (larga 60)
      top: pos.dy - 50, // -50 per appoggiarla sopra il punto
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Effetto particellare o scia (opzionale)
          //const Icon(Icons.star, color: Colors.yellow, size: 20),
          // La Capra
          Image.asset(
            'assets/images/avatarprogressbar.png',
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/pergamena.png',
          ), // Immagine pergamena
          fit: BoxFit.fill,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w900,
          color: Colors.brown,
          fontSize: 14,
        ),
      ),
    );
  }
}

// Funzione centralizzata per il percorso
Path getBridgePath(Size size) {
  Path path = Path();

  // --- 1. PUNTO DI PARTENZA (Sinistra) ---
  path.moveTo(size.width * 0.2, size.height * 0.5);

  // --- 2. PRIMA METÀ: La "Valle" (Discesa) ---
  // Disegniamo una curva che va dall'inizio fino al CENTRO del ponte
  path.cubicTo(
    size.width * 0.26,
    size.height * 0.67, // Controllo 1: Tira forte verso il basso
    size.width * 0.38,
    size.height * 0.38, // Controllo 2: Accompagna verso il centro
    size.width * 0.50,
    size.height * 0.3, // PUNTO DI ARRIVO INTERMEDIO (Esattamente a metà ponte)
  );

  // --- 3. SECONDA METÀ: La "Montagna" (Salita) ---
  // Ripartiamo automaticamente dal punto medio e andiamo alla fine
  path.cubicTo(
    size.width * 0.50,
    size.height * 0.3, // Controllo 1: Tira forte verso l'alto (Picco)
    size.width * 0.75,
    size.height * 0.60, // Controllo 2: Mantiene la curva alta
    size.width * 0.77,
    size.height * 0.53, // PUNTO FINALE (Corona a destra)
  );

  return path;
}

// Painter opzionale per disegnare la linea blu del progresso SOTTO la capra
class _PathPainter extends CustomPainter {
  final double progress;
  // final Function(Size) pathBuilder; // Non lo usiamo qui, lo riscriviamo per debug
  final bool debugMode;
  final Color color;

  _PathPainter({
    required this.progress,
    // required this.pathBuilder,
    this.debugMode = false,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = getBridgePath(size);

    // DEBUG MODE: Disegna la linea rossa per vedere il path
    if (debugMode) {
      Paint debugPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, debugPaint);
    }

    // Disegniamo la scia luminosa con il colore del topic
    Paint paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          10 // Ridotto leggermente
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5); // Effetto glow

    // Estraiamo solo la parte di percorso completata
    PathMetrics metrics = path.computeMetrics();
    for (PathMetric metric in metrics) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}
