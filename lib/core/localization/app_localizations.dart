import 'package:flutter/material.dart';

/// Supported UI languages. Darija has the highest priority per product spec;
/// it is offered both in Arabic script and in Arabizi (Latin) rendering, but
/// as a *display* language the UI strings below use Arabic-script Darija
/// ('ary') since that reads naturally for the diaspora audience. The AI
/// assistant itself (see [NluService]) additionally understands Darija
/// typed in Latin letters ("Bghit arkhass vol...") regardless of UI language.
enum AppLanguage { ary, ar, de, fr, en }

extension AppLanguageCode on AppLanguage {
  String get code => switch (this) {
        AppLanguage.ary => 'ary',
        AppLanguage.ar => 'ar',
        AppLanguage.de => 'de',
        AppLanguage.fr => 'fr',
        AppLanguage.en => 'en',
      };

  String get nativeName => switch (this) {
        AppLanguage.ary => 'الدارجة',
        AppLanguage.ar => 'العربية الفصحى',
        AppLanguage.de => 'Deutsch',
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'English',
      };

  bool get isRtl => this == AppLanguage.ary || this == AppLanguage.ar;

  Locale get locale => Locale(code);

  /// The [Locale] to hand to `MaterialApp.locale`/`supportedLocales`.
  /// Flutter ships no built-in Material/Cupertino translations for the
  /// 'ary' (Darija) locale code, so passing it directly makes Flutter's
  /// *own* widgets (date pickers, default button labels, etc.) warn/throw.
  /// Our [AppLocalizationsDelegate] serves the real Darija UI strings
  /// regardless of this value (it keys off [AppLanguage], not `Locale`),
  /// so this only controls the fallback language for Flutter's built-in
  /// widget strings - Arabic is the closest Flutter actually supports.
  Locale get flutterLocale => this == AppLanguage.ary ? const Locale('ar') : locale;
}

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguage.en);
  }

  static const _strings = <String, Map<AppLanguage, String>>{
    'appName': {
      AppLanguage.ary: 'ماروك فلاي',
      AppLanguage.ar: 'ماروك فلاي',
      AppLanguage.de: 'MarocFly AI',
      AppLanguage.fr: 'MarocFly AI',
      AppLanguage.en: 'MarocFly AI',
    },
    'tagline': {
      AppLanguage.ary: 'ماشي غير أرخص طيارة، بلاصة أذكى طريق للبلاد',
      AppLanguage.ar: 'ليس أرخص رحلة فقط، بل أذكى طريق إلى الوطن',
      AppLanguage.de: 'Nicht der günstigste Flug, sondern der intelligenteste Weg nach Hause.',
      AppLanguage.fr: 'Pas le vol le moins cher, le chemin le plus intelligent vers chez vous.',
      AppLanguage.en: 'Not the cheapest flight — the smartest way home.',
    },
    'from': {
      AppLanguage.ary: 'مننين',
      AppLanguage.ar: 'من',
      AppLanguage.de: 'Von',
      AppLanguage.fr: 'Départ',
      AppLanguage.en: 'From',
    },
    'to': {
      AppLanguage.ary: 'لفين',
      AppLanguage.ar: 'إلى',
      AppLanguage.de: 'Nach',
      AppLanguage.fr: 'Destination',
      AppLanguage.en: 'To',
    },
    'date': {
      AppLanguage.ary: 'تاريخ',
      AppLanguage.ar: 'التاريخ',
      AppLanguage.de: 'Datum',
      AppLanguage.fr: 'Date',
      AppLanguage.en: 'Date',
    },
    'passengers': {
      AppLanguage.ary: 'عدد الناس',
      AppLanguage.ar: 'عدد المسافرين',
      AppLanguage.de: 'Personen',
      AppLanguage.fr: 'Voyageurs',
      AppLanguage.en: 'Passengers',
    },
    'searchFlights': {
      AppLanguage.ary: 'قلب على الطيارة',
      AppLanguage.ar: 'ابحث عن رحلة',
      AppLanguage.de: 'Flüge suchen',
      AppLanguage.fr: 'Rechercher des vols',
      AppLanguage.en: 'Search flights',
    },
    'askAi': {
      AppLanguage.ary: 'هضر مع المستشار ديالك',
      AppLanguage.ar: 'تحدث مع مستشارك',
      AppLanguage.de: 'Mit deinem Reiseberater sprechen',
      AppLanguage.fr: 'Parler à votre conseiller',
      AppLanguage.en: 'Talk to your travel advisor',
    },
    'travelCompanion': {
      AppLanguage.ary: 'الرفيق ديال السفر',
      AppLanguage.ar: 'رفيق السفر',
      AppLanguage.de: 'Reisebegleiter',
      AppLanguage.fr: 'Compagnon de voyage',
      AppLanguage.en: 'Travel companion',
    },
    'priceAlerts': {
      AppLanguage.ary: 'تنبيهات الثمن',
      AppLanguage.ar: 'تنبيهات السعر',
      AppLanguage.de: 'Preisalarm',
      AppLanguage.fr: 'Alertes prix',
      AppLanguage.en: 'Price alerts',
    },
    'settings': {
      AppLanguage.ary: 'الإعدادات',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.de: 'Einstellungen',
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
    },
  };

  String t(String key) => _strings[key]?[language] ?? key;

  TextDirection get direction =>
      language.isRtl ? TextDirection.rtl : TextDirection.ltr;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate(this.language);

  final AppLanguage language;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(language);

  @override
  bool shouldReload(AppLocalizationsDelegate old) =>
      old.language != language;
}
