import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/trip_leg.dart';
import 'package:marocfly_ai/services/affiliate_service.dart';

void main() {
  const dus = Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland');
  const fez = Airport(code: 'FEZ', city: 'Fès', country: 'Marokko');
  final departure = DateTime(2026, 8, 15, 10, 30);

  final flightLeg = TripLeg(
    mode: LegMode.flight,
    from: dus,
    to: fez,
    departure: departure,
    arrival: departure.add(const Duration(hours: 4)),
    priceEur: 250,
    carrier: 'Royal Air Maroc',
  );

  test('isConfigured is false without a marker', () {
    const service = AffiliateService();
    expect(service.isConfigured, isFalse);
  });

  test('isConfigured is true once a marker is set', () {
    const service = AffiliateService(marker: '123456');
    expect(service.isConfigured, isTrue);
  });

  test('affiliate link embeds airports, date, and marker', () {
    const service = AffiliateService(marker: '654321');
    final url = service.affiliateBookingUrl(flightLeg);

    expect(url.toString(), contains('DUS'));
    expect(url.toString(), contains('FEZ'));
    expect(url.toString(), contains('150826')); // ddMMyy for 2026-08-15
    expect(url.queryParameters['marker'], '654321');
  });

  test('affiliate link still resolves without a configured marker', () {
    const service = AffiliateService();
    final url = service.affiliateBookingUrl(flightLeg);

    expect(url.queryParameters['marker'], 'unconfigured');
  });

  test('official ONCF link is used for ONCF train legs', () {
    const service = AffiliateService();
    final oncfLeg = TripLeg(
      mode: LegMode.train,
      from: const Airport(code: 'RBA', city: 'Rabat', country: 'Marokko'),
      to: fez,
      departure: departure,
      arrival: departure.add(const Duration(hours: 3)),
      priceEur: 18,
      carrier: 'ONCF',
    );

    final url = service.officialBookingUrl(oncfLeg);
    expect(url.host, contains('oncf'));
  });

  test('official ICE link is used for ICE train legs', () {
    const service = AffiliateService();
    final iceLeg = TripLeg(
      mode: LegMode.train,
      from: dus,
      to: const Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland'),
      departure: departure,
      arrival: departure.add(const Duration(hours: 1)),
      priceEur: 35,
      carrier: 'ICE',
    );

    final url = service.officialBookingUrl(iceLeg);
    expect(url.host, contains('bahn.de'));
  });
}
