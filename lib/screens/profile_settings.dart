import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';

    // StreamBuilder per ascoltare i cambiamenti del nome/dati in tempo reale
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFDFDF5), // Crema simile alla Home o Dark
      body: StreamBuilder(
        stream: _dbService.getUserDataStream(),
        builder: (context, snapshot) {
          String displayName = "Learner";
          int xp = 0;
          int streak = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['username'] ?? "Learner";
            xp = data['xp'] ?? 0;
            streak = data['current_streak'] ?? 0;
          }
          String avatarId = (snapshot.hasData && snapshot.data!.exists)
              ? (snapshot.data!.data() as Map<String, dynamic>)['avatar_id'] ??
                    ''
              : '';

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- HEADER: TITOLO ---
                  Text(
                    isEnglish ? "YOUR PROFILE" : "IL TUO PROFILO",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[800],
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- AVATAR CON EDIT ICON (STACK) ---
                  Center(
                    child: Stack(
                      children: [
                        // L'immagine del profilo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.indigo,
                              width: 4,
                            ), // Bordo colorato
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            color: isDark ? Colors.grey[800] : Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: _buildCurrentAvatar(avatarId),
                          ),
                        ),
                        // Il bottoncino "Modifica"
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarSelector, // Apre selezione avatar
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- NOME UTENTE MODIFICABILE ---
                  GestureDetector(
                    onTap: () => _showEditNameDialog(displayName),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.nunito(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- STATS CARDS (XP, STREAK) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          isEnglish ? "Total XP" : "XP Totali",
                          "$xp",
                          Icons.star,
                          Colors.amber,
                          isDark,
                        ),
                        _buildStatCard(
                          isEnglish ? "Days" : "Giorni",
                          "$streak",
                          Icons.local_fire_department,
                          Colors.orange,
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- SETTINGS SECTION ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.dark_mode,
                          color: isDark ? Colors.white : Colors.black,
                          title: "Dark Mode",
                          isDark: isDark,
                          trailing: Switch(
                            value: isDark,
                            activeThumbColor: const Color(0xFF5C6BC0),
                            onChanged: (val) => themeProvider.toggleTheme(val),
                          ),
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.language,
                          color: isDark ? Colors.white : Colors.black,
                          title: isEnglish ? "Language" : "Lingua",
                          isDark: isDark,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              languageProvider.currentLocale.languageCode ==
                                      'en'
                                  ? "🇬🇧"
                                  : "🇮🇹",
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          onTap: () => _showLanguageSelector(languageProvider),
                        ),
                        if (FirebaseAuth.instance.currentUser?.isAnonymous ==
                            false) ...[
                          const Divider(),
                          _buildSettingTile(
                            icon: Icons.logout,
                            color: Colors.red,
                            title: "Logout",
                            isDark: isDark,
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              // Authentication wrapper usually handles navigation changes
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget helper per le card delle statistiche
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget helper per le righe delle impostazioni
  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Dialog animato per la lingua
  void _showLanguageSelector(LanguageProvider languageProvider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2C)
                  : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      languageProvider.currentLocale.languageCode == 'en'
                          ? "Select Language"
                          : "Scegli Lingua",
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          const Locale('it'),
                          "🇮🇹",
                          "Italiano",
                        ),
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          const Locale('en'),
                          "🇬🇧",
                          "English",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider provider,
    Locale locale,
    String flag,
    String label,
  ) {
    final isSelected =
        provider.currentLocale.languageCode == locale.languageCode;
    return GestureDetector(
      onTap: () {
        provider.changeLanguage(locale);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: Colors.orange, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog per modificare il nome
  void _showEditNameDialog(String currentName) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54, // Sfondo scuro
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // non usato direttamente qui
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Animazione elastica "Juicy"
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 10,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titolo e Icona
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.indigo,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          isEnglish ? "Change Name" : "Cambia nome",
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Input Field Stilizzato
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF3E3E3E)
                            : Colors.grey[100],
                        hintText: isEnglish
                            ? "Enter new name"
                            : "Inserisci il nuovo nome",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.indigo,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Pulsanti Azione
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: Colors.grey,
                            ),
                            child: Text(
                              isEnglish ? "Cancel" : "Annulla",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                _dbService.updateUserName(
                                  controller.text.trim(),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 8,
                              shadowColor: Colors.indigo.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEnglish ? "Save" : "Salva",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // (Simulazione) BottomSheet per scegliere l'avatar
  void _showAvatarSelector() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isEnglish = languageProvider.currentLocale.languageCode == 'en';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            children: [
              Text(
                isEnglish ? "Choose your Avatar" : "Scegli il tuo Avatar",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Qui potresti mettere una lista di immagini asset selezionabili
                    _buildAvatarOption(
                      name: "Goat",
                      assetPath: "assets/images/avatar_goat.png",
                    ),
                    _buildAvatarOption(
                      name: "Goat Female",
                      assetPath: "assets/images/avatr_goatfemale.png",
                    ),
                    _buildAvatarOption(
                      name: "Goat Erasmus",
                      assetPath: "assets/images/avatar_goaterasmus.png",
                    ),
                    _buildAvatarOption(
                      name: "Goat Punk",
                      assetPath: "assets/images/avatar_goatpunk.png",
                    ),
                    // Aggiungi opzione "Carica foto"
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentAvatar(String avatarId) {
    if (avatarId.toLowerCase() == 'goat') {
      return const CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('assets/images/avatar_goat.png'),
        backgroundColor: Colors.transparent,
      );
    }
    if (avatarId.toLowerCase() == 'goat punk') {
      return const CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('assets/images/avatar_goatpunk.png'),
        backgroundColor: Colors.transparent,
      );
    }
    if (avatarId.toLowerCase() == 'goat female') {
      return const CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('assets/images/avatr_goatfemale.png'),
        backgroundColor: Colors.transparent,
      );
    }
    if (avatarId.toLowerCase() == 'goat erasmus') {
      return const CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('assets/images/avatar_goaterasmus.png'),
        backgroundColor: Colors.transparent,
      );
    }
    // Default fallback
    return const CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Icon(Icons.person, size: 60, color: Colors.indigo),
    );
  }

  Widget _buildAvatarOption({String? name, Color? color, String? assetPath}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () {
          if (name != null) {
            _dbService.updateUserAvatar(name.toLowerCase());
            Navigator.pop(context);
          }
        },
        child: Column(
          children: [
            if (assetPath != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(assetPath),
                backgroundColor: Colors.transparent,
              )
            else
              CircleAvatar(
                radius: 40,
                backgroundColor: color ?? Colors.grey,
                child: const Icon(Icons.pets, color: Colors.white, size: 30),
              ),
            const SizedBox(height: 5),
            Text(name ?? "", style: GoogleFonts.nunito()),
          ],
        ),
      ),
    );
  }
}
