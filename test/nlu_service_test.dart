import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/nlu_service.dart';

void main() {
  final nlu = NluService();

  test('parses German "von X nach Y"', () {
    final intent = nlu.parse('Ich möchte von Düsseldorf nach Fès fliegen.');
    expect(intent.origin?.code, 'DUS');
    expect(intent.destination?.code, 'FEZ');
  });

  test('parses Darija Arabizi "mn X l Y"', () {
    final intent = nlu.parse('Bghit arkhass vol mn Düsseldorf l Nador.');
    expect(intent.origin?.code, 'DUS');
    expect(intent.destination?.code, 'NDR');
  });

  test('parses Arabic script "من X ل Y"', () {
    final intent = nlu.parse('بغيت أرخص طيارة من الدار البيضاء ل فاس.');
    expect(intent.origin?.code, 'CMN');
    expect(intent.destination?.code, 'FEZ');
  });

  test('parses destination-only phrase "nächste Woche nach Fès"', () {
    final intent = nlu.parse('Ich möchte nächste Woche nach Fès.');
    expect(intent.destination?.code, 'FEZ');
    expect(intent.origin, isNull);
    expect(intent.departureDate, isNotNull);
  });

  test('parses arabic destination-only phrase "بغيت أرخص طيارة لفاس"', () {
    final intent = nlu.parse('بغيت أرخص طيارة لفاس.');
    expect(intent.destination?.code, 'FEZ');
  });

  test('extracts budget in euros', () {
    final intent = nlu.parse('Mein Budget liegt bei 200 €.');
    expect(intent.maxBudgetEur, 200);
  });

  test('detects family travel and defaults passenger count', () {
    final intent = nlu.parse('Ich reise mit meiner Familie.');
    expect(intent.travelingWithFamily, isTrue);
    expect(intent.passengerCount, 4);
  });

  test('detects explicit passenger count over family default', () {
    final intent = nlu.parse('Wir sind 3 Personen und reisen mit der Familie.');
    expect(intent.passengerCount, 3);
  });

  test('detects avoid-long-layover preference', () {
    final intent = nlu.parse('Ich möchte keinen langen Zwischenstopp.');
    expect(intent.avoidLongLayover, isTrue);
  });

  test('nextMissingField reports destination first', () {
    const intent = TravelIntent();
    expect(intent.nextMissingField, 'destination');
  });

  group('origin-only phrasing (regression: infinite "where from?" loop)', () {
    // Bug reproduced live: after the destination was established, replying
    // to "منين بغيتي تطير؟" ("where do you want to fly from?") with "بغيت
    // نطير من فاس" ("I want to fly from Fès") matched no pattern at all -
    // it fell through to the single-city fallback scan, which had no way
    // to tell origin from destination and always guessed destination,
    // silently overwriting the one already known and leaving origin
    // missing forever.
    test('parses Arabic "من X" alone (no accompanying "to Y") as the origin', () {
      final intent = nlu.parse('بغيت نطير من فاس');
      expect(intent.origin?.code, 'FEZ');
      expect(intent.destination, isNull);
    });

    test('parses German "von X" alone as the origin', () {
      final intent = nlu.parse('Ich will von Düsseldorf fliegen.');
      expect(intent.origin?.code, 'DUS');
      expect(intent.destination, isNull);
    });

    test('parses English "from X" alone as the origin', () {
      // Deliberately avoids "to fly"/"want to" here - "to" alone already
      // (pre-existing, unrelated to this fix) matches _toOnlyPatterns as a
      // destination preposition, which would confuse this specific test.
      final intent = nlu.parse('Flying from Frankfurt would be perfect.');
      expect(intent.origin?.code, 'FRA');
      expect(intent.destination, isNull);
    });

    test('a bare city name (no "from"/"to" wording) fills the still-missing '
        'origin when the conversation already has a destination', () {
      const conversationState = TravelIntent(
        destination: Airport(code: 'CMN', city: 'Casablanca', country: 'Marokko'),
      );

      final intent = nlu.parse('فاس', conversationState: conversationState);

      expect(intent.origin?.code, 'FEZ');
      expect(intent.destination, isNull, reason: 'must not re-guess/overwrite the known destination');
    });

    test('without conversation context, a single bare city name still defaults to destination '
        '(existing first-turn behavior, unchanged)', () {
      final intent = nlu.parse('فاس');
      expect(intent.destination?.code, 'FEZ');
      expect(intent.origin, isNull);
    });
  });
}
