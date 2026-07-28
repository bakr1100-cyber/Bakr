import 'package:flutter_test/flutter_test.dart';
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
}
