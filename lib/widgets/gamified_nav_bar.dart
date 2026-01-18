import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class GamifiedNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GamifiedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dimensioni dello schermo per adattamento
    // double width = MediaQuery.of(context).size.width; // Unused for now but kept for consistency with request if needed later
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isIt = languageProvider.currentLocale.languageCode == 'it';
    final isDarkMode = themeProvider.isDarkMode;

    return Positioned(
      bottom: 20, // Sollevata dal fondo (Effetto Fluttuante)
      left: 20, // Margine laterale
      right: 20, // Margine laterale
      child: Container(
        height: 70, // Altezza della barra
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white, // Sfondo scuro per Dark Mode
          borderRadius: BorderRadius.circular(
            35,
          ), // Bordi molto arrotondati (Pill shape)
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.blue.withValues(
                      alpha: 0.2,
                    ), // Ombra più scura in Dark Mode
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Spazia gli elementi
          children: [
            // 1. TASTO ARENE
            _buildNavItem(
              index: 1,
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: isIt ? "Arene" : "Arenas",
              color: Colors.orange, // Colore distintivo
            ),

            // 2. TASTO HOME (Centrale)
            _buildNavItem(
              index: 0,
              icon: Icons.play_arrow_outlined,
              activeIcon: Icons.play_arrow_rounded,
              label: isIt ? "Gioca" : "Play",
              color: const Color(
                0xFF5C6BC0,
              ), // Blu indaco (come il tasto Impara)
              isMain: true, // Flag per renderlo speciale
            ),

            // 3. TASTO PROFILO
            _buildNavItem(
              index: 2,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: isIt ? "Profilo" : "Profile",
              color: const Color(0xFF5C6BC0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
    bool isMain = false,
  }) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack, // Effetto rimbalzo cartoon
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          // Se selezionato, mostra uno sfondo colorato (pillola interna)
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icona animata
            Icon(
              isSelected ? activeIcon : icon,
              size: isMain ? 32 : 26, // Il tasto centrale è più grande
              color: isSelected ? color : Colors.grey[400],
            ),

            // Testo che appare solo se selezionato (Animazione width)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: isSelected
                    ? null
                    : 0, // Nasconde il testo se non selezionato
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
