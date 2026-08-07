import 'package:flutter/material.dart';

/// Supported UI languages. Darija has the highest priority per product spec;
/// it is offered in Arabic script since that reads naturally for the
/// diaspora audience. Modern Standard Arabic (Fusha) is offered alongside it
/// for users who prefer that over Darija. The AI assistant itself (see
/// [NluService]) additionally understands Darija typed in Latin letters
/// ("Bghit arkhass vol...") regardless of UI language.
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
        AppLanguage.ary => 'الدارجة المغربية',
        AppLanguage.ar => 'العربية الفصحى',
        AppLanguage.de => 'Deutsch',
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'English',
      };

  /// Flag shown on the language-select cards. Darija/Morocco doesn't have
  /// its own flag emoji distinct from Arabic generally, so it uses the
  /// Moroccan flag directly; Modern Standard Arabic isn't tied to one
  /// country, so it uses the conventional generic choice for "Arabic".
  String get flagEmoji => switch (this) {
        AppLanguage.ary => '🇲🇦',
        AppLanguage.ar => '🇸🇦',
        AppLanguage.de => '🇩🇪',
        AppLanguage.fr => '🇫🇷',
        AppLanguage.en => '🇬🇧',
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

  /// BCP-47 locale for the on-device speech-to-text/text-to-speech engines
  /// (`speech_to_text`/`flutter_tts`), which take a real regional locale
  /// code, not our internal [code]. Without this, both plugins fall back to
  /// whatever locale they were last configured with (or the OS default),
  /// so recognizing/speaking anything other than that one language silently
  /// fails or produces garbage. Darija has no dedicated OS speech locale,
  /// so 'ar-MA' (Arabic - Morocco) is the closest standard tag; quality
  /// depends entirely on the device's installed speech language packs.
  String get speechLocale => switch (this) {
        AppLanguage.ary => 'ar-MA',
        AppLanguage.ar => 'ar-SA',
        AppLanguage.de => 'de-DE',
        AppLanguage.fr => 'fr-FR',
        AppLanguage.en => 'en-US',
      };
}

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguage.en);
  }

  static const _strings = <String, Map<AppLanguage, String>>{
    // --- Brand / onboarding ---------------------------------------------
    'appName': {
      AppLanguage.ary: 'ماروك فلاي',
      AppLanguage.ar: 'ماروك فلاي',
      AppLanguage.de: 'MarocFly AI',
      AppLanguage.fr: 'MarocFly AI',
      AppLanguage.en: 'MarocFly AI',
    },
    'tagline': {
      AppLanguage.ary: 'ماشي غير أرخص طيارة، بلاصة أذكى طريق للبلاد.',
      AppLanguage.ar: 'ليس أرخص رحلة، بل أذكى طريق إلى المغرب.',
      AppLanguage.de: 'Nicht den günstigsten Flug — den intelligentesten Weg nach Marokko.',
      AppLanguage.fr: 'Pas le vol le moins cher — le chemin le plus intelligent vers le Maroc.',
      AppLanguage.en: 'Not the cheapest flight — the smartest way to Morocco.',
    },
    'chooseLanguage': {
      AppLanguage.ary: 'ختار اللغة ديالك',
      AppLanguage.ar: 'اختر لغتك',
      AppLanguage.de: 'Wähle deine Sprache',
      AppLanguage.fr: 'Choisis ta langue',
      AppLanguage.en: 'Choose your language',
    },
    'recommendedForYou': {
      AppLanguage.ary: 'موصى بيها ليك',
      AppLanguage.ar: 'موصى به لك',
      AppLanguage.de: 'Empfohlen für dich',
      AppLanguage.fr: 'Recommandé pour toi',
      AppLanguage.en: 'Recommended for you',
    },

    // --- Bottom navigation ------------------------------------------------
    'navSearch': {
      AppLanguage.ary: 'قلب',
      AppLanguage.ar: 'بحث',
      AppLanguage.de: 'Suche',
      AppLanguage.fr: 'Recherche',
      AppLanguage.en: 'Search',
    },
    'navAdvisor': {
      AppLanguage.ary: 'المستشار',
      AppLanguage.ar: 'المستشار',
      AppLanguage.de: 'Berater',
      AppLanguage.fr: 'Conseiller',
      AppLanguage.en: 'Advisor',
    },
    'navCompanion': {
      AppLanguage.ary: 'الرفيق',
      AppLanguage.ar: 'الرفيق',
      AppLanguage.de: 'Begleiter',
      AppLanguage.fr: 'Compagnon',
      AppLanguage.en: 'Companion',
    },
    'navAlerts': {
      AppLanguage.ary: 'التنبيهات',
      AppLanguage.ar: 'التنبيهات',
      AppLanguage.de: 'Alarme',
      AppLanguage.fr: 'Alertes',
      AppLanguage.en: 'Alerts',
    },
    'navMore': {
      AppLanguage.ary: 'كثر',
      AppLanguage.ar: 'المزيد',
      AppLanguage.de: 'Mehr',
      AppLanguage.fr: 'Plus',
      AppLanguage.en: 'More',
    },

    // --- Search form -------------------------------------------------------
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
      AppLanguage.ary: 'تاريخ الذهاب',
      AppLanguage.ar: 'تاريخ الذهاب',
      AppLanguage.de: 'Datum',
      AppLanguage.fr: 'Date',
      AppLanguage.en: 'Date',
    },
    'returnDate': {
      AppLanguage.ary: 'تاريخ الرجوع',
      AppLanguage.ar: 'تاريخ العودة',
      AppLanguage.de: 'Rückflugdatum',
      AppLanguage.fr: 'Date de retour',
      AppLanguage.en: 'Return date',
    },
    'oneWay': {
      AppLanguage.ary: 'غير الذهاب',
      AppLanguage.ar: 'ذهاب فقط',
      AppLanguage.de: 'Nur Hinflug',
      AppLanguage.fr: 'Aller simple',
      AppLanguage.en: 'One-way',
    },
    'roundTrip': {
      AppLanguage.ary: 'ذهاب و رجوع',
      AppLanguage.ar: 'ذهاب وعودة',
      AppLanguage.de: 'Hin & zurück',
      AppLanguage.fr: 'Aller-retour',
      AppLanguage.en: 'Round-trip',
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
      AppLanguage.ar: 'ابحث عن رحلات',
      AppLanguage.de: 'Flüge suchen',
      AppLanguage.fr: 'Rechercher des vols',
      AppLanguage.en: 'Search flights',
    },
    'routeSectionLabel': {
      AppLanguage.ary: 'الطريق',
      AppLanguage.ar: 'المسار',
      AppLanguage.de: 'ROUTE',
      AppLanguage.fr: 'ITINÉRAIRE',
      AppLanguage.en: 'ROUTE',
    },
    'whenAndWhoSectionLabel': {
      AppLanguage.ary: 'وقتاش و شكون',
      AppLanguage.ar: 'متى ومن',
      AppLanguage.de: 'WANN & WER',
      AppLanguage.fr: 'QUAND & QUI',
      AppLanguage.en: 'WHEN & WHO',
    },
    'thisWeek': {
      AppLanguage.ary: 'هاد السيمانة',
      AppLanguage.ar: 'هذا الأسبوع',
      AppLanguage.de: 'Diese Woche',
      AppLanguage.fr: 'Cette semaine',
      AppLanguage.en: 'This week',
    },
    'nextWeek': {
      AppLanguage.ary: 'السيمانة الجاية',
      AppLanguage.ar: 'الأسبوع القادم',
      AppLanguage.de: 'Nächste Woche',
      AppLanguage.fr: 'La semaine prochaine',
      AppLanguage.en: 'Next week',
    },
    'nextMonth': {
      AppLanguage.ary: 'الشهر الجاي',
      AppLanguage.ar: 'الشهر القادم',
      AppLanguage.de: 'Nächster Monat',
      AppLanguage.fr: 'Le mois prochain',
      AppLanguage.en: 'Next month',
    },
    'talkToMe': {
      AppLanguage.ary: 'هضر معايا غير هكاك',
      AppLanguage.ar: 'تحدث معي مباشرة',
      AppLanguage.de: 'Sprich einfach mit mir',
      AppLanguage.fr: 'Parle-moi tout simplement',
      AppLanguage.en: 'Just talk to me',
    },
    'voiceExamplePrompt': {
      AppLanguage.ary: '"بغيت نمشي لفاس، رخيص، السيمانة الجاية"',
      AppLanguage.ar: '"أريد الذهاب إلى فاس، بسعر رخيص، الأسبوع القادم"',
      AppLanguage.de: '„Ich will nach Fès, günstig, nächste Woche“',
      AppLanguage.fr: '« Je veux aller à Fès, pas cher, la semaine prochaine »',
      AppLanguage.en: '"I want to go to Fès, cheap, next week"',
    },
    'talkNow': {
      AppLanguage.ary: 'هضر دابا',
      AppLanguage.ar: 'تحدث الآن',
      AppLanguage.de: 'Jetzt sprechen',
      AppLanguage.fr: 'Parler maintenant',
      AppLanguage.en: 'Talk now',
    },
    'selectAirport': {
      AppLanguage.ary: 'ختار',
      AppLanguage.ar: 'اختر',
      AppLanguage.de: 'Auswählen',
      AppLanguage.fr: 'Sélectionner',
      AppLanguage.en: 'Select',
    },
    'searchAirportHint': {
      AppLanguage.ary: 'قلب على مدينة ولا رمز المطار...',
      AppLanguage.ar: 'ابحث عن مدينة أو رمز المطار...',
      AppLanguage.de: 'Stadt oder Flughafencode suchen…',
      AppLanguage.fr: 'Rechercher une ville ou un code aéroport…',
      AppLanguage.en: 'Search city or airport code…',
    },

    // --- Search results ------------------------------------------------------
    'searchingBestRoutes': {
      AppLanguage.ary: 'كنقلب ليك على أحسن الطرق...',
      AppLanguage.ar: 'أبحث لك عن أفضل الرحلات...',
      AppLanguage.de: 'Ich suche die besten Verbindungen für dich…',
      AppLanguage.fr: 'Je recherche les meilleures correspondances pour toi…',
      AppLanguage.en: 'Searching for the best connections for you…',
    },
    'noRouteFoundTitle': {
      AppLanguage.ary: 'مالقيتش حتى طريق',
      AppLanguage.ar: 'لم يتم العثور على رحلة بعد',
      AppLanguage.de: 'Noch keine Verbindung gefunden',
      AppLanguage.fr: 'Aucune correspondance trouvée',
      AppLanguage.en: 'No connection found yet',
    },
    'noRouteFoundBody': {
      AppLanguage.ary: 'ماكاين والو ف هاد الطريق دابا. جرب تاريخ ولا وجهة أخرى — كنقلب توما على الطران و الكار.',
      AppLanguage.ar: 'لا يوجد شيء مناسب لهذا المسار الآن. جرّب تاريخًا أو وجهة أخرى — أبحث تلقائيًا أيضًا عن رحلات القطار والحافلة.',
      AppLanguage.de: 'Für diese Route ist gerade nichts dabei. Probier ein anderes Datum oder Ziel — ich suche automatisch auch Zug- und Bus-Kombinationen mit.',
      AppLanguage.fr: 'Rien ne correspond pour cet itinéraire. Essaie une autre date ou destination — je cherche aussi automatiquement des combinaisons train/bus.',
      AppLanguage.en: 'Nothing matches this route right now. Try another date or destination — I automatically search train and bus combinations too.',
    },
    'outboundFlight': {
      AppLanguage.ary: 'الذهاب',
      AppLanguage.ar: 'الذهاب',
      AppLanguage.de: 'Hinflug',
      AppLanguage.fr: 'Aller',
      AppLanguage.en: 'Outbound',
    },
    'returnFlight': {
      AppLanguage.ary: 'الرجوع',
      AppLanguage.ar: 'العودة',
      AppLanguage.de: 'Rückflug',
      AppLanguage.fr: 'Retour',
      AppLanguage.en: 'Return',
    },
    'showMoreOptions': {
      AppLanguage.ary: 'ورّيني طرق أخرى',
      AppLanguage.ar: 'إظهار خيارات أخرى',
      AppLanguage.de: 'Weitere Möglichkeiten anzeigen',
      AppLanguage.fr: "Afficher d'autres possibilités",
      AppLanguage.en: 'Show more options',
    },
    'alternativeOptionsTitle': {
      AppLanguage.ary: 'طرق أخرى ديال السفر ليك',
      AppLanguage.ar: 'طرق سفر بديلة لك',
      AppLanguage.de: 'Alternative Reisemöglichkeiten für dich',
      AppLanguage.fr: 'Autres possibilités de voyage pour toi',
      AppLanguage.en: 'Alternative travel options for you',
    },
    'savings': {
      AppLanguage.ary: 'الفرق ديال الفلوس',
      AppLanguage.ar: 'التوفير',
      AppLanguage.de: 'Ersparnis',
      AppLanguage.fr: 'Économie',
      AppLanguage.en: 'Savings',
    },
    'extraTravelTime': {
      AppLanguage.ary: 'الوقت الزايد ف الطريق',
      AppLanguage.ar: 'الوقت الإضافي للسفر',
      AppLanguage.de: 'Zusätzliche Reisezeit',
      AppLanguage.fr: 'Temps de trajet supplémentaire',
      AppLanguage.en: 'Extra travel time',
    },

    // --- Itinerary card / detail -----------------------------------------
    'bestPrice': {
      AppLanguage.ary: 'أحسن الثمن',
      AppLanguage.ar: 'أفضل سعر',
      AppLanguage.de: 'BESTER PREIS',
      AppLanguage.fr: 'MEILLEUR PRIX',
      AppLanguage.en: 'BEST PRICE',
    },
    'direct': {
      AppLanguage.ary: 'مباشر',
      AppLanguage.ar: 'مباشر',
      AppLanguage.de: 'Direkt',
      AppLanguage.fr: 'Direct',
      AppLanguage.en: 'Direct',
    },
    'stop': {
      AppLanguage.ary: 'وقفة',
      AppLanguage.ar: 'توقف',
      AppLanguage.de: 'Umstieg',
      AppLanguage.fr: 'escale',
      AppLanguage.en: 'stop',
    },
    'stopsPlural': {
      AppLanguage.ary: 'وقفات',
      AppLanguage.ar: 'توقفات',
      AppLanguage.de: 'Umstiege',
      AppLanguage.fr: 'escales',
      AppLanguage.en: 'stops',
    },
    'total': {
      AppLanguage.ary: 'المجموع',
      AppLanguage.ar: 'الإجمالي',
      AppLanguage.de: 'gesamt',
      AppLanguage.fr: 'total',
      AppLanguage.en: 'total',
    },
    'leg': {
      AppLanguage.ary: 'مرحلة',
      AppLanguage.ar: 'مرحلة',
      AppLanguage.de: 'Etappe',
      AppLanguage.fr: 'étape',
      AppLanguage.en: 'leg',
    },
    'legsPlural': {
      AppLanguage.ary: 'مراحل',
      AppLanguage.ar: 'مراحل',
      AppLanguage.de: 'Etappen',
      AppLanguage.fr: 'étapes',
      AppLanguage.en: 'legs',
    },
    'tripDetails': {
      AppLanguage.ary: 'تفاصيل السفرة',
      AppLanguage.ar: 'تفاصيل الرحلة',
      AppLanguage.de: 'Reisedetails',
      AppLanguage.fr: 'Détails du voyage',
      AppLanguage.en: 'Trip details',
    },
    'multiStopNotice': {
      AppLanguage.ary: 'سفرة بجوج مراحل: كل مرحلة كتتحجز وحدها.',
      AppLanguage.ar: 'رحلة متعددة المراحل: يتم حجز كل مرحلة على حدة.',
      AppLanguage.de: 'Mehrteilige Reise: jede Etappe wird separat gebucht.',
      AppLanguage.fr: 'Voyage en plusieurs étapes : chaque étape se réserve séparément.',
      AppLanguage.en: 'Multi-leg trip: each leg is booked separately.',
    },
    'legsSectionLabel': {
      AppLanguage.ary: 'المراحل',
      AppLanguage.ar: 'المراحل',
      AppLanguage.de: 'ETAPPEN',
      AppLanguage.fr: 'ÉTAPES',
      AppLanguage.en: 'LEGS',
    },
    'riskLow': {
      AppLanguage.ary: 'خطر قليل',
      AppLanguage.ar: 'خطر منخفض',
      AppLanguage.de: 'Geringes Risiko',
      AppLanguage.fr: 'Risque faible',
      AppLanguage.en: 'Low risk',
    },
    'riskMedium': {
      AppLanguage.ary: 'خطر متوسط (بيليات منفصلين)',
      AppLanguage.ar: 'خطر متوسط (تذاكر منفصلة)',
      AppLanguage.de: 'Mittleres Risiko (getrennte Tickets)',
      AppLanguage.fr: 'Risque moyen (billets séparés)',
      AppLanguage.en: 'Medium risk (separate tickets)',
    },
    'riskHigh': {
      AppLanguage.ary: 'خطر كبير (وقت قصير باش تبدل الطيارة)',
      AppLanguage.ar: 'خطر مرتفع (وقت تحويل قصير)',
      AppLanguage.de: 'Hohes Risiko (kurze Umsteigezeit)',
      AppLanguage.fr: 'Risque élevé (correspondance courte)',
      AppLanguage.en: 'High risk (short layover)',
    },
    'activateCompanion': {
      AppLanguage.ary: 'شغل الرفيق ديال السفر',
      AppLanguage.ar: 'تفعيل رفيق السفر',
      AppLanguage.de: 'Reisebegleiter aktivieren',
      AppLanguage.fr: 'Activer le compagnon de voyage',
      AppLanguage.en: 'Activate travel companion',
    },
    'watchPrice': {
      AppLanguage.ary: 'تبع الثمن',
      AppLanguage.ar: 'مراقبة السعر',
      AppLanguage.de: 'Preis beobachten',
      AppLanguage.fr: 'Surveiller le prix',
      AppLanguage.en: 'Watch price',
    },
    'priceAlertActivated': {
      AppLanguage.ary: 'تنبيه الثمن تشغل.',
      AppLanguage.ar: 'تم تفعيل تنبيه السعر.',
      AppLanguage.de: 'Preisalarm aktiviert.',
      AppLanguage.fr: 'Alerte de prix activée.',
      AppLanguage.en: 'Price alert activated.',
    },
    'bookFlight': {
      AppLanguage.ary: 'حجز الطيارة',
      AppLanguage.ar: 'حجز الرحلة',
      AppLanguage.de: 'Flug buchen',
      AppLanguage.fr: 'Réserver le vol',
      AppLanguage.en: 'Book flight',
    },
    'bookTrainTicket': {
      AppLanguage.ary: 'حجز تذكرة الطران',
      AppLanguage.ar: 'حجز تذكرة القطار',
      AppLanguage.de: 'Zugticket buchen',
      AppLanguage.fr: 'Réserver le billet de train',
      AppLanguage.en: 'Book train ticket',
    },
    'bookingLinkFailed': {
      AppLanguage.ary: 'مقدرتش نحل الرابط ديال الحجز.',
      AppLanguage.ar: 'تعذر فتح رابط الحجز.',
      AppLanguage.de: 'Der Buchungslink konnte nicht geöffnet werden.',
      AppLanguage.fr: "Le lien de réservation n'a pas pu être ouvert.",
      AppLanguage.en: 'The booking link could not be opened.',
    },

    // --- AI chat ------------------------------------------------------------
    'askAi': {
      AppLanguage.ary: 'هضر مع المستشار ديالك',
      AppLanguage.ar: 'تحدث مع مستشارك',
      AppLanguage.de: 'Mit deinem Reiseberater sprechen',
      AppLanguage.fr: 'Parler à votre conseiller',
      AppLanguage.en: 'Talk to your travel advisor',
    },
    'aiChatTitle': {
      AppLanguage.ary: 'المستشار الذكي',
      AppLanguage.ar: 'المستشار الذكي',
      AppLanguage.de: 'KI-Reiseberater',
      AppLanguage.fr: 'Conseiller IA',
      AppLanguage.en: 'AI travel advisor',
    },
    'aiChatSubtitle': {
      AppLanguage.ary: 'كيعرف الطيران المباشر، الطران و الكار، و كيهضر بالدارجة',
      AppLanguage.ar: 'يعرف الرحلات المباشرة، ومجموعات القطار والحافلة، ويتحدث الدارجة',
      AppLanguage.de: 'Kennt Direktflüge, Zug- & Bus-Kombinationen und spricht Darija',
      AppLanguage.fr: 'Connaît les vols directs, les combinaisons train/bus, et parle darija',
      AppLanguage.en: 'Knows direct flights, train & bus combos, and speaks Darija',
    },
    'aiChatGreeting': {
      AppLanguage.ary: 'مرحبا! فين بغيتي تسافر؟ تقدر تكتب ليا ولا تهضر معايا - بالدارجة، العربية، الألمانية، الفرنسية ولا الإنجليزية.',
      AppLanguage.ar: 'مرحباً! إلى أين تريد السفر؟ يمكنك الكتابة لي أو التحدث معي - بالدارجة أو العربية الفصحى أو الألمانية أو الفرنسية أو الإنجليزية.',
      AppLanguage.de: 'Marhba! Wohin möchtest du reisen? Du kannst mir schreiben oder sprechen - auf Darija, Arabisch, Deutsch, Französisch oder Englisch.',
      AppLanguage.fr: 'Marhba ! Où veux-tu voyager ? Tu peux m\'écrire ou me parler - en darija, arabe, allemand, français ou anglais.',
      AppLanguage.en: 'Marhba! Where would you like to travel? You can write to me or speak - in Darija, Arabic, German, French or English.',
    },
    // Quick-suggestion chips on the AI chat's empty state. Each translation
    // is checked to still contain the exact NLU keyword/city-alias
    // substring it needs to (see NluService._cityAliases/_cheapestKeywords/
    // _familyKeywords) so tapping one is guaranteed to parse correctly.
    'suggestionCasablanca': {
      AppLanguage.ary: 'إلى الدار البيضاء',
      AppLanguage.ar: 'إلى الدار البيضاء',
      AppLanguage.de: 'Nach Casablanca',
      AppLanguage.fr: 'Vers Casablanca',
      AppLanguage.en: 'To Casablanca',
    },
    'suggestionFes': {
      AppLanguage.ary: 'إلى فاس',
      AppLanguage.ar: 'إلى فاس',
      AppLanguage.de: 'Nach Fès',
      AppLanguage.fr: 'Vers Fès',
      AppLanguage.en: 'To Fez',
    },
    'suggestionCheapest': {
      AppLanguage.ary: 'أرخص خيار',
      AppLanguage.ar: 'أرخص خيار',
      AppLanguage.de: 'Günstigste Option',
      AppLanguage.fr: 'Le moins cher',
      AppLanguage.en: 'Cheapest option',
    },
    'suggestionFamily': {
      AppLanguage.ary: 'كنسافر مع العائلة',
      AppLanguage.ar: 'أسافر مع العائلة',
      AppLanguage.de: 'Ich reise mit meiner Familie',
      AppLanguage.fr: 'Je voyage en famille',
      AppLanguage.en: 'Traveling with family',
    },
    'genericErrorRetry': {
      AppLanguage.ary: 'سمح ليا، كاين شي مشكل. جرب مرة أخرى؟',
      AppLanguage.ar: 'عذراً، حدث خطأ ما. هل يمكنك المحاولة مرة أخرى؟',
      AppLanguage.de: 'Entschuldigung, da ist etwas schiefgelaufen. Kannst du es nochmal versuchen?',
      AppLanguage.fr: "Désolé, quelque chose s'est mal passé. Peux-tu réessayer ?",
      AppLanguage.en: 'Sorry, something went wrong. Can you try again?',
    },
    'chatInputHint': {
      AppLanguage.ary: 'بغيت رخاص ديال الطيارة... / كتب لي...',
      AppLanguage.ar: 'Bghit arkhass vol… / اكتب لي…',
      AppLanguage.de: 'Bghit arkhass vol… / Schreib mir…',
      AppLanguage.fr: 'Bghit arkhass vol… / Écris-moi…',
      AppLanguage.en: 'Bghit arkhass vol… / Write to me…',
    },
    'thinking': {
      AppLanguage.ary: 'كيفكر...',
      AppLanguage.ar: 'يفكر...',
      AppLanguage.de: 'denkt nach…',
      AppLanguage.fr: 'réfléchit…',
      AppLanguage.en: 'thinking…',
    },

    // --- Price alerts -------------------------------------------------------
    'priceAlerts': {
      AppLanguage.ary: 'تنبيهات الثمن',
      AppLanguage.ar: 'تنبيهات السعر',
      AppLanguage.de: 'Preisalarme',
      AppLanguage.fr: 'Alertes prix',
      AppLanguage.en: 'Price alerts',
    },
    'checkForPriceDrops': {
      AppLanguage.ary: 'تحقق من تبديل الثمن',
      AppLanguage.ar: 'التحقق من تغيرات السعر',
      AppLanguage.de: 'Auf Preisänderungen prüfen',
      AppLanguage.fr: 'Vérifier les changements de prix',
      AppLanguage.en: 'Check for price changes',
    },
    'noAlertsYetTitle': {
      AppLanguage.ary: 'مازال ماكاين تنبيهات',
      AppLanguage.ar: 'لا توجد تنبيهات أسعار بعد',
      AppLanguage.de: 'Noch keine Preisalarme',
      AppLanguage.fr: 'Aucune alerte de prix pour le moment',
      AppLanguage.en: 'No price alerts yet',
    },
    'noAlertsYetBody': {
      AppLanguage.ary: 'شغل "تبع الثمن" ف أي سفرة، و غادي نعلمك ملي يولي رخيص.',
      AppLanguage.ar: 'فعّل "مراقبة السعر" في إحدى الرحلات، وسأخبرك بمجرد أن يصبح أرخص.',
      AppLanguage.de: 'Aktiviere bei einer Reise "Preis beobachten", und ich melde mich, sobald sie günstiger wird.',
      AppLanguage.fr: 'Active "Surveiller le prix" sur un voyage, et je te préviens dès qu\'il devient moins cher.',
      AppLanguage.en: 'Turn on "Watch price" on a trip, and I\'ll let you know as soon as it gets cheaper.',
    },
    'watchedFrom': {
      AppLanguage.ary: 'كنتبعو من',
      AppLanguage.ar: 'مراقب منذ',
      AppLanguage.de: 'Beobachtet ab',
      AppLanguage.fr: 'Surveillé depuis',
      AppLanguage.en: 'Watched from',
    },
    'nowCheaper': {
      AppLanguage.ary: 'دابا',
      AppLanguage.ar: 'الآن',
      AppLanguage.de: 'Jetzt',
      AppLanguage.fr: 'Maintenant',
      AppLanguage.en: 'Now',
    },
    'cheaper': {
      AppLanguage.ary: 'رخص',
      AppLanguage.ar: 'أرخص',
      AppLanguage.de: 'günstiger',
      AppLanguage.fr: 'moins cher',
      AppLanguage.en: 'cheaper',
    },

    // --- Settings ------------------------------------------------------------
    'settings': {
      AppLanguage.ary: 'الإعدادات',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.de: 'Einstellungen',
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
    },
    'yourTravelPreferences': {
      AppLanguage.ary: 'التفضيلات ديالك ف السفر',
      AppLanguage.ar: 'تفضيلات سفرك',
      AppLanguage.de: 'Deine Reisevorlieben',
      AppLanguage.fr: 'Tes préférences de voyage',
      AppLanguage.en: 'Your travel preferences',
    },
    'languageSectionLabel': {
      AppLanguage.ary: 'اللغة',
      AppLanguage.ar: 'اللغة',
      AppLanguage.de: 'SPRACHE',
      AppLanguage.fr: 'LANGUE',
      AppLanguage.en: 'LANGUAGE',
    },
    'appearanceSectionLabel': {
      AppLanguage.ary: 'المظهر',
      AppLanguage.ar: 'المظهر',
      AppLanguage.de: 'ERSCHEINUNGSBILD',
      AppLanguage.fr: 'APPARENCE',
      AppLanguage.en: 'APPEARANCE',
    },
    'systemDefault': {
      AppLanguage.ary: 'إعدادات الجهاز',
      AppLanguage.ar: 'إعدادات النظام',
      AppLanguage.de: 'Systemeinstellung',
      AppLanguage.fr: 'Système',
      AppLanguage.en: 'System default',
    },
    'lightMode': {
      AppLanguage.ary: 'فاتح',
      AppLanguage.ar: 'فاتح',
      AppLanguage.de: 'Hell',
      AppLanguage.fr: 'Clair',
      AppLanguage.en: 'Light',
    },
    'darkMode': {
      AppLanguage.ary: 'مظلم',
      AppLanguage.ar: 'داكن',
      AppLanguage.de: 'Dunkel',
      AppLanguage.fr: 'Sombre',
      AppLanguage.en: 'Dark',
    },
    'aiVoiceSectionLabel': {
      AppLanguage.ary: 'صوت المساعد الذكي',
      AppLanguage.ar: 'صوت المساعد الذكي',
      AppLanguage.de: 'STIMME DES KI-ASSISTENTEN',
      AppLanguage.fr: "VOIX DE L'ASSISTANT IA",
      AppLanguage.en: 'AI ASSISTANT VOICE',
    },
    'femaleVoice': {
      AppLanguage.ary: 'مرا',
      AppLanguage.ar: 'أنثى',
      AppLanguage.de: 'Weiblich',
      AppLanguage.fr: 'Féminine',
      AppLanguage.en: 'Female',
    },
    'maleVoice': {
      AppLanguage.ary: 'راجل',
      AppLanguage.ar: 'ذكر',
      AppLanguage.de: 'Männlich',
      AppLanguage.fr: 'Masculine',
      AppLanguage.en: 'Male',
    },

    // --- Profile --------------------------------------------------------------
    'favoriteDepartureAirport': {
      AppLanguage.ary: 'المطار المفضل ديال الذهاب',
      AppLanguage.ar: 'مطار المغادرة المفضل',
      AppLanguage.de: 'Lieblingsflughafen (Abflug)',
      AppLanguage.fr: 'Aéroport de départ préféré',
      AppLanguage.en: 'Favorite departure airport',
    },
    'favoriteDestination': {
      AppLanguage.ary: 'الوجهة المفضلة',
      AppLanguage.ar: 'الوجهة المفضلة',
      AppLanguage.de: 'Lieblingsziel',
      AppLanguage.fr: 'Destination préférée',
      AppLanguage.en: 'Favorite destination',
    },
    'favoriteAirlines': {
      AppLanguage.ary: 'شركات الطيران المفضلة',
      AppLanguage.ar: 'شركات الطيران المفضلة',
      AppLanguage.de: 'Lieblingsairlines',
      AppLanguage.fr: 'Compagnies aériennes préférées',
      AppLanguage.en: 'Favorite airlines',
    },
    'notKnownYet': {
      AppLanguage.ary: 'مازال ماعرفتش',
      AppLanguage.ar: 'غير معروف بعد',
      AppLanguage.de: 'Noch nicht bekannt',
      AppLanguage.fr: 'Pas encore connu',
      AppLanguage.en: 'Not known yet',
    },
    'usualBudget': {
      AppLanguage.ary: 'الميزانية المعتادة',
      AppLanguage.ar: 'الميزانية المعتادة',
      AppLanguage.de: 'Übliches Budget',
      AppLanguage.fr: 'Budget habituel',
      AppLanguage.en: 'Usual budget',
    },
    'travelStyle': {
      AppLanguage.ary: 'أسلوب السفر',
      AppLanguage.ar: 'أسلوب السفر',
      AppLanguage.de: 'Reisestil',
      AppLanguage.fr: 'Style de voyage',
      AppLanguage.en: 'Travel style',
    },
    'travelingWithFamily': {
      AppLanguage.ary: 'مع العائلة',
      AppLanguage.ar: 'مع العائلة',
      AppLanguage.de: 'Mit Familie',
      AppLanguage.fr: 'Avec la famille',
      AppLanguage.en: 'With family',
    },
    'travelingSolo': {
      AppLanguage.ary: 'وحدي',
      AppLanguage.ar: 'سفر منفرد',
      AppLanguage.de: 'Alleinreisend',
      AppLanguage.fr: 'Voyage en solo',
      AppLanguage.en: 'Traveling solo',
    },

    // --- Travel companion ------------------------------------------------------
    'travelCompanion': {
      AppLanguage.ary: 'الرفيق ديال السفر',
      AppLanguage.ar: 'رفيق السفر',
      AppLanguage.de: 'Reisebegleiter',
      AppLanguage.fr: 'Compagnon de voyage',
      AppLanguage.en: 'Travel companion',
    },
    'stageBeforeTrip': {
      AppLanguage.ary: 'قبل السفرة',
      AppLanguage.ar: 'قبل الرحلة',
      AppLanguage.de: 'Vor der Reise',
      AppLanguage.fr: 'Avant le voyage',
      AppLanguage.en: 'Before the trip',
    },
    'stageAtAirport': {
      AppLanguage.ary: 'ف المطار',
      AppLanguage.ar: 'في المطار',
      AppLanguage.de: 'Am Flughafen',
      AppLanguage.fr: "À l'aéroport",
      AppLanguage.en: 'At the airport',
    },
    'stageDuringFlight': {
      AppLanguage.ary: 'فالطيارة',
      AppLanguage.ar: 'أثناء الرحلة',
      AppLanguage.de: 'Während des Fluges',
      AppLanguage.fr: 'Pendant le vol',
      AppLanguage.en: 'During the flight',
    },
    'stageAfterLanding': {
      AppLanguage.ary: 'من بعد النزول',
      AppLanguage.ar: 'بعد الهبوط',
      AppLanguage.de: 'Nach der Landung',
      AppLanguage.fr: "Après l'atterrissage",
      AppLanguage.en: 'After landing',
    },
    'noActiveTripTitle': {
      AppLanguage.ary: 'مازال ماكاين سفرة',
      AppLanguage.ar: 'لا توجد رحلة نشطة',
      AppLanguage.de: 'Noch keine aktive Reise',
      AppLanguage.fr: 'Aucun voyage actif',
      AppLanguage.en: 'No active trip yet',
    },
    'noActiveTripBody': {
      AppLanguage.ary: 'ملي غادي تحجز سفرة، غادي نمشي معاك من الطلعة حتى الوصول — تشيك إن، تبديل البوابة، الركوب، و نصائح على الوجهة ديالك.',
      AppLanguage.ar: 'بمجرد أن تحجز رحلة، سأرافقك من المغادرة إلى الوصول — تسجيل الدخول، تغييرات البوابة، الصعود إلى الطائرة، ونصائح لوجهتك.',
      AppLanguage.de: 'Sobald du eine Reise buchst, begleite ich dich von der Anreise bis zur Ankunft — Check-in, Gate-Änderungen, Boarding, und Tipps für dein Ziel.',
      AppLanguage.fr: "Dès que tu réserves un voyage, je t'accompagne du départ à l'arrivée — enregistrement, changements de porte, embarquement, et conseils pour ta destination.",
      AppLanguage.en: 'As soon as you book a trip, I accompany you from departure to arrival — check-in, gate changes, boarding, and tips for your destination.',
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
