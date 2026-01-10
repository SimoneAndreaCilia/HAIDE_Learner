import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isFirebaseInitialized = false;
  bool _isAnimationCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationCompleted = true;
        _tryNavigateToHome();
      }
    });

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

      // 1. Auth Anonimo
      await _signInSilently();

      // 2. Init User su Firestore
      await _initializeUserInFirestore();

      _isFirebaseInitialized = true;
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    } finally {
      if (mounted) {
        _tryNavigateToHome();
      }
    }
  }

  Future<void> _signInSilently() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint("Login anonimo effettuato!");
      } catch (e) {
        debugPrint("Errore login: $e");
      }
    } else {
      debugPrint("Utente già loggato: ${user.uid}");
    }
  }

  Future<void> _initializeUserInFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'uid': user.uid,
          'created_at': FieldValue.serverTimestamp(),
          'is_anonymous': user.isAnonymous,
          'hearts': 5,
          'total_xp': 0,
          'last_login': FieldValue.serverTimestamp(),
        });
        debugPrint("🎉 COLLEZIONE USERS CREATA AUTOMATICAMENTE!");
      } else {
        await userRef.update({'last_login': FieldValue.serverTimestamp()});
        debugPrint("Utente già esistente, bentornato.");
      }
    }
  }

  void _tryNavigateToHome() {
    if (_isFirebaseInitialized && _isAnimationCompleted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOut;
          var curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
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
                    // Speed up 2x
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
