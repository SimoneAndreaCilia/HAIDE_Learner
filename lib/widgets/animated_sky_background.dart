import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedSkyBackground extends StatefulWidget {
  const AnimatedSkyBackground({super.key});

  @override
  State<AnimatedSkyBackground> createState() => _AnimatedSkyBackgroundState();
}

class _AnimatedSkyBackgroundState extends State<AnimatedSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CloudObject> _clouds = [];
  final Random _random = Random();
  late _CloudObject _airplane;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 60,
      ), // Long duration for continuous loop
    )..repeat();

    // Initialize Clouds
    for (int i = 0; i < 8; i++) {
      _clouds.add(_generateRandomCloud(startRandom: true));
    }

    // Initialize Airplane
    _airplane = _CloudObject(
      asset: 'assets/images/airplane.png',
      x: -0.2, // Start off-screen left
      y: 0.1,
      scale: 0.8,
      speed: 1.5, // Faster than clouds
    );
  }

  _CloudObject _generateRandomCloud({bool startRandom = false}) {
    final isBig = _random.nextBool();
    return _CloudObject(
      asset: isBig
          ? 'assets/images/big_cloud.png'
          : 'assets/images/little_cloud.png',
      x: startRandom
          ? _random.nextDouble() * 1.5
          : 1.2, // 1.2 is off-screen right
      y: _random.nextDouble() * 0.6 - 0.1, // Top half of screen mostly
      scale: 0.5 + _random.nextDouble() * 0.5, // 0.5 to 1.0
      speed: 0.1 + _random.nextDouble() * 0.2, // Random slow speed
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Gradient Sky
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4FC3F7), // Light Blue 300
                Color(0xFFE1F5FE), // Light Blue 50
              ],
            ),
          ),
        ),

        // 2. Animated Builder for moving elements
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                List<Widget> children = [];

                // Update and build clouds
                for (var cloud in _clouds) {
                  // Move cloud left
                  cloud.x -= cloud.speed * 0.002; // Small increment per frame

                  // Loop check
                  if (cloud.x < -0.4) {
                    // Reset to right side with new random properties
                    final newCloud = _generateRandomCloud();
                    cloud.x = newCloud.x;
                    cloud.y = newCloud.y;
                    cloud.speed = newCloud.speed;
                    cloud.scale = newCloud.scale;
                    cloud.asset = newCloud.asset;
                  }

                  children.add(
                    Positioned(
                      left: cloud.x * width,
                      top: cloud.y * height,
                      child: Opacity(
                        opacity: 0.8,
                        child: Image.asset(
                          cloud.asset,
                          width: 200 * cloud.scale,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }

                // Update and build airplane
                // Airplane moves Left to Right
                _airplane.x += _airplane.speed * 0.001;

                if (_airplane.x > 1.2) {
                  // Reset infrequent appearance
                  if (_random.nextDouble() < 0.01) {
                    _airplane.x = -0.5; // Start Left again
                    _airplane.y = 0.1 + _random.nextDouble() * 0.3;
                  }
                }

                if (_airplane.x > -0.5 && _airplane.x < 1.5) {
                  children.add(
                    Positioned(
                      left: _airplane.x * width,
                      top: _airplane.y * height,
                      child: Image.asset(
                        _airplane.asset,
                        width: 150 * _airplane.scale,
                      ),
                    ),
                  );
                }

                return Stack(children: children);
              },
            );
          },
        ),
      ],
    );
  }
}

class _CloudObject {
  String asset;
  double x; // 0.0 to 1.0 (relative width)
  double y; // 0.0 to 1.0 (relative height)
  double scale;
  double speed;

  _CloudObject({
    required this.asset,
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
  });
}
