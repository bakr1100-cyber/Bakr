import '../models/airport.dart';
import '../models/travel_intent.dart';

/// Rule-based natural-language understanding for the travel assistant.
///
/// This is a deliberately dependency-free stand-in for a real multilingual
/// LLM. It is NOT a substitute for the "mehrsprachiges LLM mit
/// hervorragender Darija-Unterstützung" called for in the product brief -
/// there is no LLM wired into this build. What it does do is recognise the
/// concrete vocabulary from the brief (city names in German/French/
/// English/MSA/Darija - both Arabic script and Arabizi - plus budget,
/// date, family and layover phrases) so the rest of the app (chat UI,
/// clarifying questions, search) can be built and tested against something
/// real today. To go to production, replace [parse] with a call to an LLM
/// (few-shot prompted or fine-tuned for Darija) that returns the same
/// [TravelIntent] shape, ideally grounded with RAG over live fare/schedule
/// data.
class NluService {
  static final Map<String, String> _cityAliases = {
    // Fès
    'fes': 'FEZ', 'fès': 'FEZ', 'fez': 'FEZ', 'فاس': 'FEZ', 'fas': 'FEZ',
    // Casablanca
    'casablanca': 'CMN', 'casa': 'CMN', 'الدار البيضاء': 'CMN', 'كازا': 'CMN',
    'كازابلانكا': 'CMN',
    // Rabat
    'rabat': 'RBA', 'رباط': 'RBA', 'الرباط': 'RBA',
    // Tanger
    'tanger': 'TNG', 'tangier': 'TNG', 'طنجة': 'TNG',
    // Nador
    'nador': 'NDR', 'ندور': 'NDR', 'نادور': 'NDR',
    // Oujda
    'oujda': 'OUD', 'وجدة': 'OUD',
    // Marrakesch
    'marrakech': 'RAK', 'marrakesch': 'RAK', 'marrakesh': 'RAK',
    'مراكش': 'RAK',
    // European departure cities
    'düsseldorf': 'DUS', 'dusseldorf': 'DUS', 'duesseldorf': 'DUS',
    'دوسلدورف': 'DUS',
    'köln': 'CGN', 'koeln': 'CGN', 'cologne': 'CGN', 'كولونيا': 'CGN',
    'frankfurt': 'FRA', 'فرانكفورت': 'FRA',
    'dortmund': 'DTM', 'دورتموند': 'DTM',
    'eindhoven': 'EIN',
    'brüssel': 'BRU', 'bruessel': 'BRU', 'brussels': 'BRU', 'bruxelles': 'BRU',
    'amsterdam': 'AMS',
    'paris': 'CDG', 'باريس': 'CDG',
    'madrid': 'MAD', 'مدريد': 'MAD',
    'barcelona': 'BCN', 'برشلونة': 'BCN',
    'lissabon': 'LIS', 'lisbon': 'LIS', 'lisbonne': 'LIS',
    'mailand': 'MXP', 'milan': 'MXP', 'milano': 'MXP',
  };

  static final List<RegExp> _fromToPatterns = [
    // German: "von Düsseldorf nach Fès"
    RegExp(r'von\s+([\p{L}\s]+?)\s+nach\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    // French: "de Paris à Fès" / "de Paris vers Fès"
    RegExp(r'de\s+([\p{L}\s]+?)\s+(?:à|vers)\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    // English: "from Düsseldorf to Fès"
    RegExp(r'from\s+([\p{L}\s]+?)\s+to\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    // Darija Arabizi: "mn Düsseldorf l Nador" / "mn ... l-..."
    RegExp(r'\bmn\s+([\p{L}\s]+?)\s+l-?\s*([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    // Darija/MSA Arabic script: "من X ل Y" / "من X إلى Y"
    RegExp(r'من\s+([\p{L}\s]+?)\s+(?:ل|إلى|لـ)\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
  ];

  static final List<RegExp> _toOnlyPatterns = [
    RegExp(r'nach\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'(?:à|vers)\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'\bto\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'\bl-?\s*([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'(?:إلى|لـ|ل)\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
  ];

  /// Recognizes a bare "from X" (no accompanying "to Y") - needed for
  /// exactly the case a fresh clarifying question produces: the user
  /// answers "منين بغيتي تطير؟" ("where do you want to fly from?") with
  /// just "بغيت نطير من فاس" ("I want to fly from Fès"). Without this, that
  /// answer matched no pattern at all and fell through to the ambiguous
  /// single-city fallback scan below, which - having no way to tell origin
  /// from destination on its own - assigned it as the *destination*,
  /// silently overwriting the one already established and leaving origin
  /// stuck missing forever (observed live: the same clarifying question
  /// repeating no matter what was said). French "de" is deliberately not
  /// included here - unlike "von"/"from"/"من"/"mn", it's used constantly in
  /// French for reasons that have nothing to do with an origin city, which
  /// would create far more false positives than it would fix.
  static final List<RegExp> _originOnlyPatterns = [
    RegExp(r'\bvon\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'\bfrom\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'\bmn\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
    RegExp(r'من\s+([\p{L}\s]+?)(?:[.,!?]|$)', unicode: true),
  ];

  static final RegExp _budgetPattern = RegExp(
    r'(\d+)\s*(?:€|eur|euro|أورو|يورو)',
    caseSensitive: false,
  );

  static final RegExp _passengerCountPattern = RegExp(
    r'(\d+)\s*(?:personen|person|passagers|pax|persons|أشخاص|ناس)',
    caseSensitive: false,
  );

  static const _familyKeywords = [
    'familie', 'famille', 'family', 'العائلة', 'عائلتي', 'mama', 'baba',
  ];

  static const _cheapestKeywords = [
    'arkhass', 'أرخص', 'günstig', 'billig', 'cheap', 'moins cher', 'pas cher',
  ];

  static const _avoidLayoverKeywords = [
    'kein langen zwischenstopp', 'keinen langen zwischenstopp',
    'no long layover', 'pas de longue escale', 'بلا توقف طويل',
    'من غير توقف',
  ];

  /// [conversationState], when given, is the intent already built up from
  /// earlier turns - used only to disambiguate the single-city fallback
  /// scan below (is a lone city mention the still-missing origin, or a new
  /// destination?), never to override anything this call itself resolves
  /// with real confidence.
  TravelIntent parse(String rawText, {TravelIntent? conversationState}) {
    final text = rawText.trim();
    final lower = text.toLowerCase();
    _lastResolveWasLowConfidence = false;

    Airport? origin;
    Airport? destination;

    for (final pattern in _fromToPatterns) {
      final match = pattern.firstMatch(lower) ?? pattern.firstMatch(text);
      if (match != null && match.groupCount >= 2) {
        origin ??= _resolveCity(match.group(1));
        destination ??= _resolveCity(match.group(2));
        if (origin != null && destination != null) break;
      }
    }

    if (destination == null) {
      for (final pattern in _toOnlyPatterns) {
        final match = pattern.firstMatch(lower) ?? pattern.firstMatch(text);
        if (match != null) {
          destination = _resolveCity(match.group(1));
          if (destination != null) break;
        }
      }
    }

    if (origin == null) {
      for (final pattern in _originOnlyPatterns) {
        final match = pattern.firstMatch(lower) ?? pattern.firstMatch(text);
        if (match != null) {
          origin = _resolveCity(match.group(1));
          if (origin != null) break;
        }
      }
    }

    // Fallback: scan the whole message for any known city alias. With no
    // explicit "from"/"to" wording at all (just a bare city name), there's
    // no way to tell origin from destination from this message alone - so
    // when exactly one *new* city is mentioned and the conversation so far
    // already has a destination but is still missing the origin (the exact
    // shape of a reply to "where from?"), treat it as the origin instead
    // of blindly defaulting to "destination first" and overwriting the one
    // already known.
    if (origin == null || destination == null) {
      final found = _scanAllCities(lower);
      found.removeWhere((a) => a == destination || a == origin);
      if (conversationState != null) {
        found.removeWhere(
          (a) => a == conversationState.origin || a == conversationState.destination,
        );
      }

      final destinationAlreadyKnown = destination != null || conversationState?.destination != null;
      final originAlreadyKnown = origin != null || conversationState?.origin != null;

      if (found.length == 1 && destinationAlreadyKnown && !originAlreadyKnown) {
        origin = found.first;
      } else {
        if (destination == null && found.isNotEmpty) {
          destination = found.removeAt(0);
        }
        if (origin == null && found.isNotEmpty) {
          origin = found.removeAt(0);
        }
      }
    }

    double? budget;
    final budgetMatch = _budgetPattern.firstMatch(lower);
    if (budgetMatch != null) {
      budget = double.tryParse(budgetMatch.group(1)!);
    }

    int? passengers;
    final paxMatch = _passengerCountPattern.firstMatch(lower);
    if (paxMatch != null) {
      passengers = int.tryParse(paxMatch.group(1)!);
    }

    final travelingWithFamily =
        _familyKeywords.any((k) => lower.contains(k)) || text.contains('العائلة');
    if (travelingWithFamily && passengers == null) {
      passengers = 4;
    }

    final avoidLongLayover = _avoidLayoverKeywords.any((k) => lower.contains(k));

    final date = _resolveDate(lower);

    return TravelIntent(
      origin: origin,
      destination: destination,
      departureDate: date,
      passengerCount: passengers,
      maxBudgetEur: budget,
      avoidLongLayover: avoidLongLayover,
      travelingWithFamily: travelingWithFamily,
      detectedLanguage: _detectLanguage(text),
      isLowConfidence: _lastResolveWasLowConfidence,
    );
  }

  bool wantsCheapest(String rawText) {
    final lower = rawText.toLowerCase();
    return _cheapestKeywords.any((k) => lower.contains(k));
  }

  bool _lastResolveWasLowConfidence = false;

  Airport? _resolveCity(String? phrase) {
    if (phrase == null) return null;
    final cleaned = phrase.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    if (_cityAliases.containsKey(cleaned)) {
      return _findByCode(_cityAliases[cleaned]!);
    }
    // Try longest-alias-contained-in-phrase match (handles trailing words).
    String? bestAlias;
    for (final alias in _cityAliases.keys) {
      if (cleaned.contains(alias) && (bestAlias == null || alias.length > bestAlias.length)) {
        bestAlias = alias;
      }
    }
    if (bestAlias != null) return _findByCode(_cityAliases[bestAlias]!);
    // Nothing matched by known alias/substring: fall back to a loose
    // lookup and flag the result as low-confidence so the assistant
    // confirms before searching.
    final loose = findAirportByCity(cleaned);
    if (loose != null) _lastResolveWasLowConfidence = true;
    return loose;
  }

  List<Airport> _scanAllCities(String lower) {
    final matches = <Airport>[];
    _cityAliases.forEach((alias, code) {
      if (lower.contains(alias)) {
        final airport = _findByCode(code);
        if (airport != null && !matches.contains(airport)) {
          matches.add(airport);
        }
      }
    });
    return matches;
  }

  Airport? _findByCode(String code) {
    for (final a in [...europeanAirports, ...moroccanAirports]) {
      if (a.code == code) return a;
    }
    return null;
  }

  DateTime? _resolveDate(String lower) {
    final now = DateTime.now();
    if (lower.contains('heute') || lower.contains('aujourd') ||
        lower.contains('today') || lower.contains('اليوم')) {
      return now;
    }
    if (lower.contains('morgen') || lower.contains('demain') ||
        lower.contains('tomorrow') || lower.contains('غدا') || lower.contains('غدة')) {
      return now.add(const Duration(days: 1));
    }
    if (lower.contains('nächste woche') || lower.contains('naechste woche') ||
        lower.contains('semaine prochaine') || lower.contains('next week') ||
        lower.contains('الأسبوع الجاي') || lower.contains('الأسبوع المقبل')) {
      return now.add(const Duration(days: 7));
    }
    return null;
  }

  String _detectLanguage(String text) {
    final hasArabicScript = RegExp(r'[؀-ۿ]').hasMatch(text);
    if (hasArabicScript) {
      // Heuristic: Darija-specific function words vs. MSA.
      const darijaMarkers = ['بغيت', 'ديال', 'واخا', 'زوين', 'مزيان'];
      if (darijaMarkers.any(text.contains)) return 'ary';
      return 'ar';
    }
    final lower = text.toLowerCase();
    const darijaLatinMarkers = ['bghit', 'wach', 'chno', 'fin', 'arkhass', 'bzaf'];
    if (darijaLatinMarkers.any(lower.contains)) return 'ary-latin';
    if (RegExp(r'\b(ich|möchte|und|nach|flug)\b').hasMatch(lower)) return 'de';
    if (RegExp(r"\b(je|veux|vol|vers|d')\b").hasMatch(lower)) return 'fr';
    return 'en';
  }
}
