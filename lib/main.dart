import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart'; // Importiamo solo la Home

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HaideApp());
}

class HaideApp extends StatelessWidget {
  const HaideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAIDE Learner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF58CC02)),
        useMaterial3: true,
        fontFamily: 'Verdana',
      ),
      home: const HomeScreen(), // Il main lancia solo la HomeScreen
    );
  }
}
