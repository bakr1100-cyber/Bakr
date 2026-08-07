import '../core/localization/app_localizations.dart';
import '../models/companion_event.dart';
import '../models/itinerary.dart';

/// Generates the "Reisebegleiter" timeline for a booked itinerary: before
/// the trip, at the airport, during the flight (offline-capable content),
/// and after landing. In production this stage would subscribe to a real
/// flight-status feed (e.g. AeroDataBox/FlightAware) for gate/boarding/delay
/// events and to ONCF's timetable for the post-landing train connection;
/// here it synthesizes a plausible timeline from the booked itinerary so
/// the companion UI has real, itinerary-specific content to show.
class TravelCompanionService {
  List<CompanionEvent> buildTimeline(Itinerary itinerary, {required AppLanguage language}) {
    final departure = itinerary.departureTime;
    final arrival = itinerary.arrivalTime;
    final destinationCity = itinerary.legs.last.to.city;
    final carrier = itinerary.legs.first.carrier ?? _yourAirline(language);

    return [
      CompanionEvent(
        id: 'checkin',
        stage: CompanionStage.beforeTrip,
        title: _title(language, 'checkin'),
        message: _checkinMessage(language),
        timestamp: departure.subtract(const Duration(hours: 24)),
      ),
      CompanionEvent(
        id: 'baggage',
        stage: CompanionStage.beforeTrip,
        title: _title(language, 'baggage'),
        message: _baggageMessage(language, carrier),
        timestamp: departure.subtract(const Duration(hours: 20)),
      ),
      CompanionEvent(
        id: 'weather',
        stage: CompanionStage.beforeTrip,
        title: _title(language, 'weather'),
        message: _weatherMessage(language, destinationCity),
        timestamp: departure.subtract(const Duration(hours: 12)),
      ),
      CompanionEvent(
        id: 'gate',
        stage: CompanionStage.atAirport,
        title: _title(language, 'gate'),
        message: _gateMessage(language),
        timestamp: departure.subtract(const Duration(hours: 1)),
        isUrgent: true,
      ),
      CompanionEvent(
        id: 'boarding',
        stage: CompanionStage.atAirport,
        title: _title(language, 'boarding'),
        message: _boardingMessage(language),
        timestamp: departure.subtract(const Duration(minutes: 40)),
        isUrgent: true,
      ),
      CompanionEvent(
        id: 'inflight',
        stage: CompanionStage.duringFlight,
        title: _title(language, 'inflight'),
        message: _inflightMessage(language, destinationCity),
        timestamp: departure.add(itinerary.legs.first.duration ~/ 2),
      ),
      CompanionEvent(
        id: 'landing',
        stage: CompanionStage.afterLanding,
        title: _welcomeTitle(language, destinationCity),
        message: itinerary.isMultimodal
            ? _landingMultimodalMessage(language)
            : _landingMessage(language),
        timestamp: arrival,
      ),
    ];
  }

  String _yourAirline(AppLanguage language) => switch (language) {
        AppLanguage.de => 'Deine Airline',
        AppLanguage.fr => 'Ta compagnie aérienne',
        AppLanguage.en => 'Your airline',
        AppLanguage.ar => 'شركة طيرانك',
        AppLanguage.ary => 'شركة الطيران ديالك',
      };

  String _title(AppLanguage language, String eventId) => switch ((eventId, language)) {
        ('checkin', AppLanguage.de) => 'Online Check-in',
        ('checkin', AppLanguage.fr) => 'Enregistrement en ligne',
        ('checkin', AppLanguage.en) => 'Online check-in',
        ('checkin', AppLanguage.ar) => 'تسجيل الوصول عبر الإنترنت',
        ('checkin', AppLanguage.ary) => 'تسجيل الوصول أونلاين',
        ('baggage', AppLanguage.de) => 'Gepäckregeln',
        ('baggage', AppLanguage.fr) => 'Règles de bagages',
        ('baggage', AppLanguage.en) => 'Baggage rules',
        ('baggage', AppLanguage.ar) => 'قواعد الأمتعة',
        ('baggage', AppLanguage.ary) => 'قوانين الشنط',
        ('weather', AppLanguage.de) => 'Wetter am Ziel',
        ('weather', AppLanguage.fr) => 'Météo à destination',
        ('weather', AppLanguage.en) => 'Weather at destination',
        ('weather', AppLanguage.ar) => 'الطقس في الوجهة',
        ('weather', AppLanguage.ary) => 'الجو ف الوجهة',
        ('gate', AppLanguage.de) => 'Gate-Information',
        ('gate', AppLanguage.fr) => 'Informations sur la porte',
        ('gate', AppLanguage.en) => 'Gate information',
        ('gate', AppLanguage.ar) => 'معلومات البوابة',
        ('gate', AppLanguage.ary) => 'معلومات البوابة',
        ('boarding', AppLanguage.de) => 'Boarding',
        ('boarding', AppLanguage.fr) => 'Embarquement',
        ('boarding', AppLanguage.en) => 'Boarding',
        ('boarding', AppLanguage.ar) => 'الصعود إلى الطائرة',
        ('boarding', AppLanguage.ary) => 'الركوب للطيارة',
        ('inflight', AppLanguage.de) => 'Offline-Reiseinfos',
        ('inflight', AppLanguage.fr) => 'Infos de voyage hors ligne',
        ('inflight', AppLanguage.en) => 'Offline travel info',
        ('inflight', AppLanguage.ar) => 'معلومات السفر بدون إنترنت',
        ('inflight', AppLanguage.ary) => 'معلومات السفر بلا نترنت',
        (_, _) => eventId,
      };

  String _checkinMessage(AppLanguage language) => switch (language) {
        AppLanguage.de =>
          'Der Online-Check-in öffnet 24 Stunden vor deinem Flug. Ich erinnere dich rechtzeitig.',
        AppLanguage.fr =>
          "L'enregistrement en ligne ouvre 24 heures avant ton vol. Je te le rappellerai à temps.",
        AppLanguage.en =>
          "Online check-in opens 24 hours before your flight. I'll remind you in time.",
        AppLanguage.ar =>
          'يفتح تسجيل الوصول عبر الإنترنت قبل 24 ساعة من رحلتك. سأذكرك في الوقت المناسب.',
        AppLanguage.ary => 'تسجيل الوصول أونلاين كيبدا 24 ساعة قبل الطيران ديالك. غادي نفكرك ف الوقت.',
      };

  String _baggageMessage(AppLanguage language, String carrier) => switch (language) {
        AppLanguage.de =>
          '$carrier erlaubt 1 Handgepäckstück (max. 10 kg) und ein Aufgabegepäckstück je nach Tarif.',
        AppLanguage.fr =>
          '$carrier autorise 1 bagage à main (max. 10 kg) et un bagage en soute selon le tarif.',
        AppLanguage.en =>
          '$carrier allows 1 carry-on (max. 10 kg) and one checked bag depending on the fare.',
        AppLanguage.ar =>
          'تسمح $carrier بحقيبة يد واحدة (10 كجم كحد أقصى) وحقيبة مسجلة واحدة حسب التعرفة.',
        AppLanguage.ary => '$carrier كتسمح ب1 شنطة يد (10 كيلو الأقصى) وشنطة مسجلة وحدة حسب التعريفة.',
      };

  String _weatherMessage(AppLanguage language, String destinationCity) => switch (language) {
        AppLanguage.de =>
          'In $destinationCity werden zur Ankunft angenehme Temperaturen erwartet. Denk an leichte Kleidung.',
        AppLanguage.fr =>
          'À $destinationCity, des températures agréables sont prévues à ton arrivée. Pense à des vêtements légers.',
        AppLanguage.en =>
          'Pleasant temperatures are expected in $destinationCity when you arrive. Pack light clothing.',
        AppLanguage.ar =>
          'من المتوقع أن تكون درجات الحرارة لطيفة في $destinationCity عند وصولك. فكر في ملابس خفيفة.',
        AppLanguage.ary => 'ف $destinationCity غادي يكون الجو مزيان منين توصل. جيب حوايج خفاف.',
      };

  String _gateMessage(AppLanguage language) => switch (language) {
        AppLanguage.de => 'Dein Gate wurde auf B24 geändert. Plane etwa 15 Minuten bis zum Gate ein.',
        AppLanguage.fr =>
          "Ta porte d'embarquement a été changée pour B24. Prévois environ 15 minutes pour t'y rendre.",
        AppLanguage.en => 'Your gate has been changed to B24. Allow about 15 minutes to get there.',
        AppLanguage.ar => 'تم تغيير بوابتك إلى B24. خصص حوالي 15 دقيقة للوصول إليها.',
        AppLanguage.ary => 'البوابة ديالك تبدلات ل B24. خصص شي 15 دقيقة باش توصل.',
      };

  String _boardingMessage(AppLanguage language) => switch (language) {
        AppLanguage.de => 'Das Boarding beginnt in 20 Minuten.',
        AppLanguage.fr => "L'embarquement commence dans 20 minutes.",
        AppLanguage.en => 'Boarding starts in 20 minutes.',
        AppLanguage.ar => 'يبدأ الصعود إلى الطائرة خلال 20 دقيقة.',
        AppLanguage.ary => 'الركوب غادي يبدا من بعد 20 دقيقة.',
      };

  String _inflightMessage(AppLanguage language, String destinationCity) => switch (language) {
        AppLanguage.de =>
          'Frag mich unterwegs nach Sehenswürdigkeiten, Restaurants, Hotels, Mietwagen oder '
              'ONCF-Zugverbindungen in $destinationCity - ich funktioniere auch ohne '
              'Internetverbindung.',
        AppLanguage.fr =>
          'En route, demande-moi les sites à voir, restaurants, hôtels, locations de voiture ou '
              'correspondances ONCF à $destinationCity - je fonctionne aussi sans connexion '
              'internet.',
        AppLanguage.en =>
          'On the way, ask me about sights, restaurants, hotels, car rentals or ONCF train '
              'connections in $destinationCity - I also work without an internet connection.',
        AppLanguage.ar =>
          'في الطريق، اسألني عن المعالم والمطاعم والفنادق وتأجير السيارات أو قطارات ONCF في '
              '$destinationCity - أعمل أيضًا بدون اتصال بالإنترنت.',
        AppLanguage.ary =>
          'ف الطريق، سولني على الأماكن، المطاعم، الأوطيلات، كراء الطوموبيلات أو التران ديال ONCF ف '
              '$destinationCity - خدام حتى بلا نترنت.',
      };

  String _welcomeTitle(AppLanguage language, String destinationCity) => switch (language) {
        AppLanguage.de => 'Willkommen in $destinationCity',
        AppLanguage.fr => 'Bienvenue à $destinationCity',
        AppLanguage.en => 'Welcome to $destinationCity',
        AppLanguage.ar => 'مرحبًا بك في $destinationCity',
        AppLanguage.ary => 'مرحبا بيك ف $destinationCity',
      };

  String _landingMultimodalMessage(AppLanguage language) => switch (language) {
        AppLanguage.de =>
          'Dein Anschluss ist bereits gebucht - ich navigiere dich zum nächsten Bahnsteig/Gate.',
        AppLanguage.fr =>
          "Ta correspondance est déjà réservée - je te guide jusqu'au prochain quai/porte.",
        AppLanguage.en =>
          "Your onward connection is already booked - I'll guide you to the next platform/gate.",
        AppLanguage.ar => 'تم حجز ارتباطك بالفعل - سأرشدك إلى الرصيف/البوابة التالية.',
        AppLanguage.ary => 'الكورسبوندونس ديالك محجوزة من قبل - غادي نوريك للرصيف/البوابة لي جاية.',
      };

  String _landingMessage(AppLanguage language) => switch (language) {
        AppLanguage.de =>
          'Der nächste ONCF-Zug und Taxis findest du direkt am Ausgang. Soll ich dir eine '
              'Verbindung weiter zu deinem Ziel suchen?',
        AppLanguage.fr =>
          'Le prochain train ONCF et des taxis se trouvent directement à la sortie. Veux-tu que '
              "je te cherche une correspondance jusqu'à ta destination ?",
        AppLanguage.en =>
          'The next ONCF train and taxis are right at the exit. Should I look up a connection '
              'onward to your destination?',
        AppLanguage.ar =>
          'ستجد أقرب قطار ONCF وسيارات الأجرة عند المخرج مباشرة. هل تريد أن أبحث لك عن ارتباط إلى '
              'وجهتك؟',
        AppLanguage.ary =>
          'التران ديال ONCF لي جاي والطاكسيات كاينين مباشرة فالباب. بغيتيني نقلب ليك على '
              'كورسبوندونس لحتى للوجهة ديالك؟',
      };
}
