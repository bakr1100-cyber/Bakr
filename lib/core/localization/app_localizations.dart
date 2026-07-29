import 'package:flutter/material.dart';

/// Supported UI languages. Darija has the highest priority per product spec;
/// it is offered in Arabic script since that reads naturally for the
/// diaspora audience. The AI assistant itself (see [NluService])
/// additionally understands Darija typed in Latin letters
/// ("Bghit arkhass vol...") regardless of UI language.
enum AppLanguage { ary, de, fr, en }

extension AppLanguageCode on AppLanguage {
  String get code => switch (this) {
        AppLanguage.ary => 'ary',
        AppLanguage.de => 'de',
        AppLanguage.fr => 'fr',
        AppLanguage.en => 'en',
      };

  String get nativeName => switch (this) {
        AppLanguage.ary => 'الدارجة المغربية',
        AppLanguage.de => 'Deutsch',
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'English',
      };

  /// Flag shown on the language-select cards. Darija/Morocco doesn't have
  /// its own flag emoji distinct from Arabic generally, so it uses the
  /// Moroccan flag directly.
  String get flagEmoji => switch (this) {
        AppLanguage.ary => '🇲🇦',
        AppLanguage.de => '🇩🇪',
        AppLanguage.fr => '🇫🇷',
        AppLanguage.en => '🇬🇧',
      };

  bool get isRtl => this == AppLanguage.ary;

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
    // --- Brand / onboarding ---------------------------------------------
    'appName': {
      AppLanguage.ary: 'ماروك فلاي',
      AppLanguage.de: 'MarocFly AI',
      AppLanguage.fr: 'MarocFly AI',
      AppLanguage.en: 'MarocFly AI',
    },
    'tagline': {
      AppLanguage.ary: 'ماشي غير أرخص طيارة، بلاصة أذكى طريق للبلاد.',
      AppLanguage.de: 'Nicht den günstigsten Flug — den intelligentesten Weg nach Marokko.',
      AppLanguage.fr: 'Pas le vol le moins cher — le chemin le plus intelligent vers le Maroc.',
      AppLanguage.en: 'Not the cheapest flight — the smartest way to Morocco.',
    },
    'chooseLanguage': {
      AppLanguage.ary: 'ختار اللغة ديالك',
      AppLanguage.de: 'Wähle deine Sprache',
      AppLanguage.fr: 'Choisis ta langue',
      AppLanguage.en: 'Choose your language',
    },
    'recommendedForYou': {
      AppLanguage.ary: 'موصى بيها ليك',
      AppLanguage.de: 'Empfohlen für dich',
      AppLanguage.fr: 'Recommandé pour toi',
      AppLanguage.en: 'Recommended for you',
    },

    // --- Bottom navigation ------------------------------------------------
    'navSearch': {
      AppLanguage.ary: 'قلب',
      AppLanguage.de: 'Suche',
      AppLanguage.fr: 'Recherche',
      AppLanguage.en: 'Search',
    },
    'navAdvisor': {
      AppLanguage.ary: 'المستشار',
      AppLanguage.de: 'Berater',
      AppLanguage.fr: 'Conseiller',
      AppLanguage.en: 'Advisor',
    },
    'navCompanion': {
      AppLanguage.ary: 'الرفيق',
      AppLanguage.de: 'Begleiter',
      AppLanguage.fr: 'Compagnon',
      AppLanguage.en: 'Companion',
    },
    'navAlerts': {
      AppLanguage.ary: 'التنبيهات',
      AppLanguage.de: 'Alarme',
      AppLanguage.fr: 'Alertes',
      AppLanguage.en: 'Alerts',
    },
    'navMore': {
      AppLanguage.ary: 'كثر',
      AppLanguage.de: 'Mehr',
      AppLanguage.fr: 'Plus',
      AppLanguage.en: 'More',
    },

    // --- Search form -------------------------------------------------------
    'from': {
      AppLanguage.ary: 'مننين',
      AppLanguage.de: 'Von',
      AppLanguage.fr: 'Départ',
      AppLanguage.en: 'From',
    },
    'to': {
      AppLanguage.ary: 'لفين',
      AppLanguage.de: 'Nach',
      AppLanguage.fr: 'Destination',
      AppLanguage.en: 'To',
    },
    'date': {
      AppLanguage.ary: 'تاريخ الذهاب',
      AppLanguage.de: 'Datum',
      AppLanguage.fr: 'Date',
      AppLanguage.en: 'Date',
    },
    'returnDate': {
      AppLanguage.ary: 'تاريخ الرجوع',
      AppLanguage.de: 'Rückflugdatum',
      AppLanguage.fr: 'Date de retour',
      AppLanguage.en: 'Return date',
    },
    'oneWay': {
      AppLanguage.ary: 'غير الذهاب',
      AppLanguage.de: 'Nur Hinflug',
      AppLanguage.fr: 'Aller simple',
      AppLanguage.en: 'One-way',
    },
    'roundTrip': {
      AppLanguage.ary: 'ذهاب و رجوع',
      AppLanguage.de: 'Hin & zurück',
      AppLanguage.fr: 'Aller-retour',
      AppLanguage.en: 'Round-trip',
    },
    'passengers': {
      AppLanguage.ary: 'عدد الناس',
      AppLanguage.de: 'Personen',
      AppLanguage.fr: 'Voyageurs',
      AppLanguage.en: 'Passengers',
    },
    'searchFlights': {
      AppLanguage.ary: 'قلب على الطيارة',
      AppLanguage.de: 'Flüge suchen',
      AppLanguage.fr: 'Rechercher des vols',
      AppLanguage.en: 'Search flights',
    },
    'routeSectionLabel': {
      AppLanguage.ary: 'الطريق',
      AppLanguage.de: 'ROUTE',
      AppLanguage.fr: 'ITINÉRAIRE',
      AppLanguage.en: 'ROUTE',
    },
    'whenAndWhoSectionLabel': {
      AppLanguage.ary: 'وقتاش و شكون',
      AppLanguage.de: 'WANN & WER',
      AppLanguage.fr: 'QUAND & QUI',
      AppLanguage.en: 'WHEN & WHO',
    },
    'thisWeek': {
      AppLanguage.ary: 'هاد السيمانة',
      AppLanguage.de: 'Diese Woche',
      AppLanguage.fr: 'Cette semaine',
      AppLanguage.en: 'This week',
    },
    'nextWeek': {
      AppLanguage.ary: 'السيمانة الجاية',
      AppLanguage.de: 'Nächste Woche',
      AppLanguage.fr: 'La semaine prochaine',
      AppLanguage.en: 'Next week',
    },
    'nextMonth': {
      AppLanguage.ary: 'الشهر الجاي',
      AppLanguage.de: 'Nächster Monat',
      AppLanguage.fr: 'Le mois prochain',
      AppLanguage.en: 'Next month',
    },
    'talkToMe': {
      AppLanguage.ary: 'هضر معايا غير هكاك',
      AppLanguage.de: 'Sprich einfach mit mir',
      AppLanguage.fr: 'Parle-moi tout simplement',
      AppLanguage.en: 'Just talk to me',
    },
    'voiceExamplePrompt': {
      AppLanguage.ary: '"بغيت نمشي لفاس، رخيص، السيمانة الجاية"',
      AppLanguage.de: '„Ich will nach Fès, günstig, nächste Woche“',
      AppLanguage.fr: '« Je veux aller à Fès, pas cher, la semaine prochaine »',
      AppLanguage.en: '"I want to go to Fès, cheap, next week"',
    },
    'talkNow': {
      AppLanguage.ary: 'هضر دابا',
      AppLanguage.de: 'Jetzt sprechen',
      AppLanguage.fr: 'Parler maintenant',
      AppLanguage.en: 'Talk now',
    },
    'selectAirport': {
      AppLanguage.ary: 'ختار',
      AppLanguage.de: 'Auswählen',
      AppLanguage.fr: 'Sélectionner',
      AppLanguage.en: 'Select',
    },
    'searchAirportHint': {
      AppLanguage.ary: 'قلب على مدينة ولا رمز المطار...',
      AppLanguage.de: 'Stadt oder Flughafencode suchen…',
      AppLanguage.fr: 'Rechercher une ville ou un code aéroport…',
      AppLanguage.en: 'Search city or airport code…',
    },

    // --- Search results ------------------------------------------------------
    'searchingBestRoutes': {
      AppLanguage.ary: 'كنقلب ليك على أحسن الطرق...',
      AppLanguage.de: 'Ich suche die besten Verbindungen für dich…',
      AppLanguage.fr: 'Je recherche les meilleures correspondances pour toi…',
      AppLanguage.en: 'Searching for the best connections for you…',
    },
    'noRouteFoundTitle': {
      AppLanguage.ary: 'مالقيتش حتى طريق',
      AppLanguage.de: 'Noch keine Verbindung gefunden',
      AppLanguage.fr: 'Aucune correspondance trouvée',
      AppLanguage.en: 'No connection found yet',
    },
    'noRouteFoundBody': {
      AppLanguage.ary: 'ماكاين والو ف هاد الطريق دابا. جرب تاريخ ولا وجهة أخرى — كنقلب توما على الطران و الكار.',
      AppLanguage.de: 'Für diese Route ist gerade nichts dabei. Probier ein anderes Datum oder Ziel — ich suche automatisch auch Zug- und Bus-Kombinationen mit.',
      AppLanguage.fr: 'Rien ne correspond pour cet itinéraire. Essaie une autre date ou destination — je cherche aussi automatiquement des combinaisons train/bus.',
      AppLanguage.en: 'Nothing matches this route right now. Try another date or destination — I automatically search train and bus combinations too.',
    },
    'outboundFlight': {
      AppLanguage.ary: 'الذهاب',
      AppLanguage.de: 'Hinflug',
      AppLanguage.fr: 'Aller',
      AppLanguage.en: 'Outbound',
    },
    'returnFlight': {
      AppLanguage.ary: 'الرجوع',
      AppLanguage.de: 'Rückflug',
      AppLanguage.fr: 'Retour',
      AppLanguage.en: 'Return',
    },

    // --- Itinerary card / detail -----------------------------------------
    'bestPrice': {
      AppLanguage.ary: 'أحسن الثمن',
      AppLanguage.de: 'BESTER PREIS',
      AppLanguage.fr: 'MEILLEUR PRIX',
      AppLanguage.en: 'BEST PRICE',
    },
    'direct': {
      AppLanguage.ary: 'مباشر',
      AppLanguage.de: 'Direkt',
      AppLanguage.fr: 'Direct',
      AppLanguage.en: 'Direct',
    },
    'stop': {
      AppLanguage.ary: 'وقفة',
      AppLanguage.de: 'Umstieg',
      AppLanguage.fr: 'escale',
      AppLanguage.en: 'stop',
    },
    'stopsPlural': {
      AppLanguage.ary: 'وقفات',
      AppLanguage.de: 'Umstiege',
      AppLanguage.fr: 'escales',
      AppLanguage.en: 'stops',
    },
    'total': {
      AppLanguage.ary: 'المجموع',
      AppLanguage.de: 'gesamt',
      AppLanguage.fr: 'total',
      AppLanguage.en: 'total',
    },
    'leg': {
      AppLanguage.ary: 'مرحلة',
      AppLanguage.de: 'Etappe',
      AppLanguage.fr: 'étape',
      AppLanguage.en: 'leg',
    },
    'legsPlural': {
      AppLanguage.ary: 'مراحل',
      AppLanguage.de: 'Etappen',
      AppLanguage.fr: 'étapes',
      AppLanguage.en: 'legs',
    },
    'tripDetails': {
      AppLanguage.ary: 'تفاصيل السفرة',
      AppLanguage.de: 'Reisedetails',
      AppLanguage.fr: 'Détails du voyage',
      AppLanguage.en: 'Trip details',
    },
    'multiStopNotice': {
      AppLanguage.ary: 'سفرة بجوج مراحل: كل مرحلة كتتحجز وحدها.',
      AppLanguage.de: 'Mehrteilige Reise: jede Etappe wird separat gebucht.',
      AppLanguage.fr: 'Voyage en plusieurs étapes : chaque étape se réserve séparément.',
      AppLanguage.en: 'Multi-leg trip: each leg is booked separately.',
    },
    'legsSectionLabel': {
      AppLanguage.ary: 'المراحل',
      AppLanguage.de: 'ETAPPEN',
      AppLanguage.fr: 'ÉTAPES',
      AppLanguage.en: 'LEGS',
    },
    'activateCompanion': {
      AppLanguage.ary: 'شغل الرفيق ديال السفر',
      AppLanguage.de: 'Reisebegleiter aktivieren',
      AppLanguage.fr: 'Activer le compagnon de voyage',
      AppLanguage.en: 'Activate travel companion',
    },
    'watchPrice': {
      AppLanguage.ary: 'تبع الثمن',
      AppLanguage.de: 'Preis beobachten',
      AppLanguage.fr: 'Surveiller le prix',
      AppLanguage.en: 'Watch price',
    },
    'priceAlertActivated': {
      AppLanguage.ary: 'تنبيه الثمن تشغل.',
      AppLanguage.de: 'Preisalarm aktiviert.',
      AppLanguage.fr: 'Alerte de prix activée.',
      AppLanguage.en: 'Price alert activated.',
    },
    'bookFlight': {
      AppLanguage.ary: 'حجز الطيارة',
      AppLanguage.de: 'Flug buchen',
      AppLanguage.fr: 'Réserver le vol',
      AppLanguage.en: 'Book flight',
    },
    'bookTrainTicket': {
      AppLanguage.ary: 'حجز تذكرة الطران',
      AppLanguage.de: 'Zugticket buchen',
      AppLanguage.fr: 'Réserver le billet de train',
      AppLanguage.en: 'Book train ticket',
    },
    'bookingLinkFailed': {
      AppLanguage.ary: 'مقدرتش نحل الرابط ديال الحجز.',
      AppLanguage.de: 'Der Buchungslink konnte nicht geöffnet werden.',
      AppLanguage.fr: "Le lien de réservation n'a pas pu être ouvert.",
      AppLanguage.en: 'The booking link could not be opened.',
    },

    // --- AI chat ------------------------------------------------------------
    'askAi': {
      AppLanguage.ary: 'هضر مع المستشار ديالك',
      AppLanguage.de: 'Mit deinem Reiseberater sprechen',
      AppLanguage.fr: 'Parler à votre conseiller',
      AppLanguage.en: 'Talk to your travel advisor',
    },
    'aiChatTitle': {
      AppLanguage.ary: 'المستشار الذكي',
      AppLanguage.de: 'KI-Reiseberater',
      AppLanguage.fr: 'Conseiller IA',
      AppLanguage.en: 'AI travel advisor',
    },
    'aiChatSubtitle': {
      AppLanguage.ary: 'كيعرف الطيران المباشر، الطران و الكار، و كيهضر بالدارجة',
      AppLanguage.de: 'Kennt Direktflüge, Zug- & Bus-Kombinationen und spricht Darija',
      AppLanguage.fr: 'Connaît les vols directs, les combinaisons train/bus, et parle darija',
      AppLanguage.en: 'Knows direct flights, train & bus combos, and speaks Darija',
    },
    'chatInputHint': {
      AppLanguage.ary: 'بغيت رخاص ديال الطيارة... / كتب لي...',
      AppLanguage.de: 'Bghit arkhass vol… / Schreib mir…',
      AppLanguage.fr: 'Bghit arkhass vol… / Écris-moi…',
      AppLanguage.en: 'Bghit arkhass vol… / Write to me…',
    },
    'thinking': {
      AppLanguage.ary: 'كيفكر...',
      AppLanguage.de: 'denkt nach…',
      AppLanguage.fr: 'réfléchit…',
      AppLanguage.en: 'thinking…',
    },

    // --- Price alerts -------------------------------------------------------
    'priceAlerts': {
      AppLanguage.ary: 'تنبيهات الثمن',
      AppLanguage.de: 'Preisalarme',
      AppLanguage.fr: 'Alertes prix',
      AppLanguage.en: 'Price alerts',
    },
    'checkForPriceDrops': {
      AppLanguage.ary: 'تحقق من تبديل الثمن',
      AppLanguage.de: 'Auf Preisänderungen prüfen',
      AppLanguage.fr: 'Vérifier les changements de prix',
      AppLanguage.en: 'Check for price changes',
    },
    'noAlertsYetTitle': {
      AppLanguage.ary: 'مازال ماكاين تنبيهات',
      AppLanguage.de: 'Noch keine Preisalarme',
      AppLanguage.fr: 'Aucune alerte de prix pour le moment',
      AppLanguage.en: 'No price alerts yet',
    },
    'noAlertsYetBody': {
      AppLanguage.ary: 'شغل "تبع الثمن" ف أي سفرة، و غادي نعلمك ملي يولي رخيص.',
      AppLanguage.de: 'Aktiviere bei einer Reise "Preis beobachten", und ich melde mich, sobald sie günstiger wird.',
      AppLanguage.fr: 'Active "Surveiller le prix" sur un voyage, et je te préviens dès qu\'il devient moins cher.',
      AppLanguage.en: 'Turn on "Watch price" on a trip, and I\'ll let you know as soon as it gets cheaper.',
    },
    'watchedFrom': {
      AppLanguage.ary: 'كنتبعو من',
      AppLanguage.de: 'Beobachtet ab',
      AppLanguage.fr: 'Surveillé depuis',
      AppLanguage.en: 'Watched from',
    },
    'nowCheaper': {
      AppLanguage.ary: 'دابا',
      AppLanguage.de: 'Jetzt',
      AppLanguage.fr: 'Maintenant',
      AppLanguage.en: 'Now',
    },
    'cheaper': {
      AppLanguage.ary: 'رخص',
      AppLanguage.de: 'günstiger',
      AppLanguage.fr: 'moins cher',
      AppLanguage.en: 'cheaper',
    },

    // --- Settings ------------------------------------------------------------
    'settings': {
      AppLanguage.ary: 'الإعدادات',
      AppLanguage.de: 'Einstellungen',
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
    },
    'yourTravelPreferences': {
      AppLanguage.ary: 'التفضيلات ديالك ف السفر',
      AppLanguage.de: 'Deine Reisevorlieben',
      AppLanguage.fr: 'Tes préférences de voyage',
      AppLanguage.en: 'Your travel preferences',
    },
    'languageSectionLabel': {
      AppLanguage.ary: 'اللغة',
      AppLanguage.de: 'SPRACHE',
      AppLanguage.fr: 'LANGUE',
      AppLanguage.en: 'LANGUAGE',
    },
    'appearanceSectionLabel': {
      AppLanguage.ary: 'المظهر',
      AppLanguage.de: 'ERSCHEINUNGSBILD',
      AppLanguage.fr: 'APPARENCE',
      AppLanguage.en: 'APPEARANCE',
    },
    'systemDefault': {
      AppLanguage.ary: 'إعدادات الجهاز',
      AppLanguage.de: 'Systemeinstellung',
      AppLanguage.fr: 'Système',
      AppLanguage.en: 'System default',
    },
    'lightMode': {
      AppLanguage.ary: 'فاتح',
      AppLanguage.de: 'Hell',
      AppLanguage.fr: 'Clair',
      AppLanguage.en: 'Light',
    },
    'darkMode': {
      AppLanguage.ary: 'مظلم',
      AppLanguage.de: 'Dunkel',
      AppLanguage.fr: 'Sombre',
      AppLanguage.en: 'Dark',
    },
    'aiVoiceSectionLabel': {
      AppLanguage.ary: 'صوت المساعد الذكي',
      AppLanguage.de: 'STIMME DES KI-ASSISTENTEN',
      AppLanguage.fr: "VOIX DE L'ASSISTANT IA",
      AppLanguage.en: 'AI ASSISTANT VOICE',
    },
    'femaleVoice': {
      AppLanguage.ary: 'مرا',
      AppLanguage.de: 'Weiblich',
      AppLanguage.fr: 'Féminine',
      AppLanguage.en: 'Female',
    },
    'maleVoice': {
      AppLanguage.ary: 'راجل',
      AppLanguage.de: 'Männlich',
      AppLanguage.fr: 'Masculine',
      AppLanguage.en: 'Male',
    },

    // --- Profile --------------------------------------------------------------
    'favoriteDepartureAirport': {
      AppLanguage.ary: 'المطار المفضل ديال الذهاب',
      AppLanguage.de: 'Lieblingsflughafen (Abflug)',
      AppLanguage.fr: 'Aéroport de départ préféré',
      AppLanguage.en: 'Favorite departure airport',
    },
    'favoriteDestination': {
      AppLanguage.ary: 'الوجهة المفضلة',
      AppLanguage.de: 'Lieblingsziel',
      AppLanguage.fr: 'Destination préférée',
      AppLanguage.en: 'Favorite destination',
    },
    'favoriteAirlines': {
      AppLanguage.ary: 'شركات الطيران المفضلة',
      AppLanguage.de: 'Lieblingsairlines',
      AppLanguage.fr: 'Compagnies aériennes préférées',
      AppLanguage.en: 'Favorite airlines',
    },
    'notKnownYet': {
      AppLanguage.ary: 'مازال ماعرفتش',
      AppLanguage.de: 'Noch nicht bekannt',
      AppLanguage.fr: 'Pas encore connu',
      AppLanguage.en: 'Not known yet',
    },
    'usualBudget': {
      AppLanguage.ary: 'الميزانية المعتادة',
      AppLanguage.de: 'Übliches Budget',
      AppLanguage.fr: 'Budget habituel',
      AppLanguage.en: 'Usual budget',
    },
    'travelStyle': {
      AppLanguage.ary: 'أسلوب السفر',
      AppLanguage.de: 'Reisestil',
      AppLanguage.fr: 'Style de voyage',
      AppLanguage.en: 'Travel style',
    },
    'travelingWithFamily': {
      AppLanguage.ary: 'مع العائلة',
      AppLanguage.de: 'Mit Familie',
      AppLanguage.fr: 'Avec la famille',
      AppLanguage.en: 'With family',
    },
    'travelingSolo': {
      AppLanguage.ary: 'وحدي',
      AppLanguage.de: 'Alleinreisend',
      AppLanguage.fr: 'Voyage en solo',
      AppLanguage.en: 'Traveling solo',
    },

    // --- Travel companion ------------------------------------------------------
    'travelCompanion': {
      AppLanguage.ary: 'الرفيق ديال السفر',
      AppLanguage.de: 'Reisebegleiter',
      AppLanguage.fr: 'Compagnon de voyage',
      AppLanguage.en: 'Travel companion',
    },
    'stageBeforeTrip': {
      AppLanguage.ary: 'قبل السفرة',
      AppLanguage.de: 'Vor der Reise',
      AppLanguage.fr: 'Avant le voyage',
      AppLanguage.en: 'Before the trip',
    },
    'stageAtAirport': {
      AppLanguage.ary: 'ف المطار',
      AppLanguage.de: 'Am Flughafen',
      AppLanguage.fr: "À l'aéroport",
      AppLanguage.en: 'At the airport',
    },
    'stageDuringFlight': {
      AppLanguage.ary: 'فالطيارة',
      AppLanguage.de: 'Während des Fluges',
      AppLanguage.fr: 'Pendant le vol',
      AppLanguage.en: 'During the flight',
    },
    'stageAfterLanding': {
      AppLanguage.ary: 'من بعد النزول',
      AppLanguage.de: 'Nach der Landung',
      AppLanguage.fr: "Après l'atterrissage",
      AppLanguage.en: 'After landing',
    },
    'noActiveTripTitle': {
      AppLanguage.ary: 'مازال ماكاين سفرة',
      AppLanguage.de: 'Noch keine aktive Reise',
      AppLanguage.fr: 'Aucun voyage actif',
      AppLanguage.en: 'No active trip yet',
    },
    'noActiveTripBody': {
      AppLanguage.ary: 'ملي غادي تحجز سفرة، غادي نمشي معاك من الطلعة حتى الوصول — تشيك إن، تبديل البوابة، الركوب، و نصائح على الوجهة ديالك.',
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
