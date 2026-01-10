import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/progress_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // INITIALIZATION MOVED TO SPLASH SCREEN
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: const HaideApp(),
    ),
  );
}

class HaideApp extends StatelessWidget {
  const HaideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        return MaterialApp(
          title: 'HAIDE Learner',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF58CC02),
            ),
            useMaterial3: true,
            fontFamily: 'Verdana',
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF58CC02),
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF58CC02),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Verdana',
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(
                0xFF1B5E20,
              ), // Darker green for dark mode
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'), // Italiano
            Locale('en'), // English
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
