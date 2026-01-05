// File: lib/widgets/animazione_scossa.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Serve per sin()

class AnimazioneScossa extends StatefulWidget {
  final Widget child;
  const AnimazioneScossa({super.key, required this.child});

  @override
  AnimazioneScossaState createState() => AnimazioneScossaState();
}

class AnimazioneScossaState extends State<AnimazioneScossa>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scuoti() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // CORREZIONE QUI SOTTO: uso sin(...) invece di .sin()
        final double offset =
            10.0 *
            (0.5 - (0.5 - _controller.value).abs()) *
            sin(3 * 3.14159 * _controller.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }
}
