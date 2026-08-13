import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/services/duffel_flight_api.dart';
import 'package:marocfly_ai/services/duffel_flight_price_source.dart';
import 'package:marocfly_ai/services/flight_price_source.dart';
import 'package:marocfly_ai/services/mock_flight_price_source.dart';

/// One Duffel offer in the exact shape the real API returns (trimmed to the
/// fields this app reads), so these tests exercise the same parsing path a
/// live response would.
Map<String, dynamic> _offer({
  required String amount,
  required String currency,
  required bool liveMode,
}) =>
    {
      'id': 'off_$amount$currency',
      'total_amount': amount,
      'total_currency': currency,
      'live_mode': liveMode,
      'slices': [
        {
          'segments': [
            {
              'origin': {'iata_code': 'CDG'},
              'destination': {'iata_code': 'CMN'},
              'departing_at': '2026-09-12T08:30:00',
              'arriving_at': '2026-09-12T09:39:00',
              'marketing_carrier': {'name': 'Royal Air Maroc'},
            },
          ],
        },
      ],
    };

http.Client _clientReturning(List<Map<String, dynamic>> offers) => MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': {'offers': offers},
        }),
        201,
      ),
    );

DuffelFlightPriceSource _sourceReturning(List<Map<String, dynamic>> offers) =>
    DuffelFlightPriceSource(
      fallback: MockFlightPriceSource(),
      api: DuffelFlightApi(apiKey: 'test', client: _clientReturning(offers)),
    );

final _cdg = findAirportByCode('CDG')!;
final _cmn = findAirportByCode('CMN')!;

Future<FlightQuote?> _quote(DuffelFlightPriceSource source) => source.quoteDirect(
      origin: _cdg,
      destination: _cmn,
      date: DateTime(2026, 9, 12),
    );

void main() {
  group('Duffel test-vs-live data detection', () {
    test('reports sandbox when Duffel says live_mode is false', () async {
      // This is exactly what the deployed app was getting: a complete,
      // realistic-looking response whose prices are simulated.
      final source = _sourceReturning([
        _offer(amount: '95.45', currency: 'EUR', liveMode: false),
      ]);

      final quote = await _quote(source);

      expect(quote?.priceEur, 95.45);
      expect(source.lastDataMode, FlightDataMode.sandbox);
    });

    test('reports live when Duffel says live_mode is true', () async {
      final source = _sourceReturning([
        _offer(amount: '210.00', currency: 'EUR', liveMode: true),
      ]);

      final quote = await _quote(source);

      expect(quote?.priceEur, 210.00);
      expect(source.lastDataMode, FlightDataMode.live);
    });

    test('reports mock - not sandbox or live - when it falls back to mock data', () async {
      final source = _sourceReturning([]);

      final quote = await _quote(source);

      // Still answers (graceful degradation), but is honest that the number
      // came from the app's own synthetic pricing.
      expect(quote, isNotNull);
      expect(source.lastDataMode, FlightDataMode.mock);
    });

    test('reports mock when the request itself fails', () async {
      final source = DuffelFlightPriceSource(
        fallback: MockFlightPriceSource(),
        api: DuffelFlightApi(
          apiKey: 'test',
          client: MockClient((request) async => http.Response('{"errors":[]}', 401)),
        ),
      );

      expect(await _quote(source), isNotNull);
      expect(source.lastDataMode, FlightDataMode.mock);
    });

    test('lastDataMode is null before anything has been quoted', () {
      expect(_sourceReturning([]).lastDataMode, isNull);
    });
  });

  group('currency handling (a foreign amount must never be shown as euros)', () {
    test('picks the cheapest EUR offer, not a numerically cheaper foreign one', () async {
      final source = _sourceReturning([
        _offer(amount: '90.00', currency: 'GBP', liveMode: true),
        _offer(amount: '95.45', currency: 'EUR', liveMode: true),
      ]);

      final quote = await _quote(source);

      // 90 GBP is the smaller number but is worth more than 95.45 EUR -
      // labelling it "€90" would be a wrong price shown as fact.
      expect(quote?.priceEur, 95.45);
    });

    test('falls back to mock rather than relabelling a non-EUR price as euros', () async {
      final source = _sourceReturning([
        _offer(amount: '90.00', currency: 'GBP', liveMode: true),
      ]);

      final quote = await _quote(source);

      expect(quote, isNotNull);
      expect(quote!.priceEur, isNot(90.00));
      expect(source.lastDataMode, FlightDataMode.mock);
    });
  });
}
