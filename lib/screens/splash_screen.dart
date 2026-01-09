import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firebase_options.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _initializeFirebase();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    } finally {
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide Home Screen from Bottom (Offset 0, 1) to Up (Offset 0, 0)
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          // Optional: Slide Splash Screen Up as well?
          // To strictly follow "pushed by", we can just slide the new page in.
          // This gives the visual effect of the new page pushing the view.

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation
                Lottie.asset(
                  'assets/animations/splash_screen.json',
                  controller: _controller,
                  onLoaded: (composition) {
                    // Speed up 1.5x
                    // New Duration = Original / 1.5
                    _controller
                      ..duration = composition.duration * (1 / 2)
                      ..forward();
                  },
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // "HAIDE" text at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 50, // Adequate spacing from bottom
            child: Column(
              children: [
                Text(
                  "HAIDE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 40,
                    fontWeight: FontWeight.w900, // "Cicciotto" (Chubby)
                    color: const Color(0xFF58CC02), // Duolingo Green
                  ),
                ),
                // Decorative bottom element (border/gradient hint)
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.redAccent, // Flag color hint
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
