import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In it, this message translates to:
  /// **'Ciao Mondo!'**
  String get helloWorld;

  /// No description provided for @startQuiz.
  ///
  /// In it, this message translates to:
  /// **'Inizia Quiz'**
  String get startQuiz;

  /// No description provided for @quizTitle.
  ///
  /// In it, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @question.
  ///
  /// In it, this message translates to:
  /// **'Domanda'**
  String get question;

  /// No description provided for @score.
  ///
  /// In it, this message translates to:
  /// **'Punteggio'**
  String get score;

  /// No description provided for @correct.
  ///
  /// In it, this message translates to:
  /// **'Corretto!'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In it, this message translates to:
  /// **'Sbagliato!'**
  String get wrong;

  /// No description provided for @nextQuestion.
  ///
  /// In it, this message translates to:
  /// **'Prossima Domanda'**
  String get nextQuestion;

  /// No description provided for @finishQuiz.
  ///
  /// In it, this message translates to:
  /// **'Termina Quiz'**
  String get finishQuiz;

  /// No description provided for @resultTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo'**
  String get resultTime;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @learningPath.
  ///
  /// In it, this message translates to:
  /// **'Percorso di Apprendimento'**
  String get learningPath;

  /// No description provided for @lessonEmpty.
  ///
  /// In it, this message translates to:
  /// **'Questa lezione è vuota!'**
  String get lessonEmpty;

  /// No description provided for @questionsCount.
  ///
  /// In it, this message translates to:
  /// **'{count} domande'**
  String questionsCount(int count);

  /// No description provided for @whatIsThis.
  ///
  /// In it, this message translates to:
  /// **'Cos\'è questo?'**
  String get whatIsThis;

  /// No description provided for @howToSay.
  ///
  /// In it, this message translates to:
  /// **'Come si dice...'**
  String get howToSay;

  /// No description provided for @bravo.
  ///
  /// In it, this message translates to:
  /// **'BRAVO! 🎉'**
  String get bravo;

  /// No description provided for @wrongMessage.
  ///
  /// In it, this message translates to:
  /// **'SBAGLIATO! 😢 Era: {correct}'**
  String wrongMessage(String correct);

  /// No description provided for @gameOver.
  ///
  /// In it, this message translates to:
  /// **'GAME OVER'**
  String get gameOver;

  /// No description provided for @noLives.
  ///
  /// In it, this message translates to:
  /// **'Hai finito le vite! Devi ricominciare la lezione.'**
  String get noLives;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @lessonCompleted.
  ///
  /// In it, this message translates to:
  /// **'Lezione Completata! 🏆'**
  String get lessonCompleted;

  /// No description provided for @continueBtn.
  ///
  /// In it, this message translates to:
  /// **'CONTINUA'**
  String get continueBtn;

  /// No description provided for @livesLeft.
  ///
  /// In it, this message translates to:
  /// **'Vite rimaste: {count} ❤️'**
  String livesLeft(int count);

  /// No description provided for @imageError.
  ///
  /// In it, this message translates to:
  /// **'Errore immagine'**
  String get imageError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
