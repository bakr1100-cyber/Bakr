import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for the Duffel flight search API
/// (https://duffel.com/docs/api/overview/welcome).
///
/// Duffel has no rail/bus data - it only covers flights - so this is only
/// ever used for individual flight legs; ONCF/ICE train legs stay
/// synthetic (see `TravelCompanionService`/`FlightSearchService`). A test
/// API key (self-serve at https://app.duffel.com) talks to Duffel's
/// sandbox, which returns realistic but fictional test-airline offers, not
/// live real-world schedules - going live requires Duffel's onboarding
/// review, same as any flight-booking API.
///
/// Can talk to Duffel directly (pass [apiKey], fine for local/native
/// builds that never ship the key publicly) or through the
/// `cloudflare-worker/` proxy in this repo (pass [baseUrl] pointing at the
/// deployed Worker and leave [apiKey] null - the proxy holds the real key
/// server-side, so a public web build never embeds it).
class DuffelFlightApi {
  DuffelFlightApi({
    this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? apiKey;
  final String baseUrl;
  final http.Client _client;

  static const _defaultBaseUrl = 'https://api.duffel.com';
  static const _apiVersion = 'v2';

  /// Creates an offer request for a single one-way slice and returns the
  /// offers Duffel priced for it, cheapest first. Returns an empty list
  /// (never throws for "no offers") so callers can fall back gracefully;
  /// network/auth errors throw [DuffelApiException].
  Future<List<DuffelOffer>> searchOneWayOffers({
    required String originIata,
    required String destinationIata,
    required DateTime departureDate,
    int passengerCount = 1,
    String cabinClass = 'economy',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/air/offer_requests?return_offers=true'),
      headers: _headers,
      body: jsonEncode({
        'data': {
          'slices': [
            {
              'origin': originIata,
              'destination': destinationIata,
              'departure_date': _dateOnly(departureDate),
            },
          ],
          'passengers': List.generate(
            passengerCount.clamp(1, 9),
            (_) => {'type': 'adult'},
          ),
          'cabin_class': cabinClass,
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw DuffelApiException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final offers = (data?['offers'] as List?) ?? const [];

    final parsed = offers
        .map((o) => DuffelOffer.fromJson(o as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
    return parsed;
  }

  Map<String, String> get _headers => {
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        'Duffel-Version': _apiVersion,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void close() => _client.close();
}

class DuffelApiException implements Exception {
  DuffelApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Duffel API error $statusCode: $body';
}

class DuffelOffer {
  const DuffelOffer({
    required this.id,
    required this.totalAmount,
    required this.totalCurrency,
    required this.segments,
    required this.isLiveMode,
  });

  final String id;
  final double totalAmount;
  final String totalCurrency;
  final List<DuffelSegment> segments;

  /// Duffel's own `live_mode` flag: false means this offer came from the
  /// test environment and its price is simulated, however real the rest of
  /// the response looks. Defaults to false when absent - the safe
  /// assumption is "not real money", never the other way around.
  final bool isLiveMode;

  factory DuffelOffer.fromJson(Map<String, dynamic> json) {
    final slices = (json['slices'] as List?) ?? const [];
    final segments = <DuffelSegment>[
      for (final slice in slices)
        for (final segment in (slice as Map<String, dynamic>)['segments'] as List)
          DuffelSegment.fromJson(segment as Map<String, dynamic>),
    ];

    return DuffelOffer(
      id: json['id'] as String,
      totalAmount: double.parse(json['total_amount'] as String),
      totalCurrency: json['total_currency'] as String,
      segments: segments,
      isLiveMode: json['live_mode'] as bool? ?? false,
    );
  }
}

class DuffelSegment {
  const DuffelSegment({
    required this.originIata,
    required this.destinationIata,
    required this.departingAt,
    required this.arrivingAt,
    required this.carrierName,
  });

  final String originIata;
  final String destinationIata;
  final DateTime departingAt;
  final DateTime arrivingAt;
  final String carrierName;

  factory DuffelSegment.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as Map<String, dynamic>;
    final destination = json['destination'] as Map<String, dynamic>;
    final carrier = json['marketing_carrier'] as Map<String, dynamic>?;

    return DuffelSegment(
      originIata: origin['iata_code'] as String,
      destinationIata: destination['iata_code'] as String,
      departingAt: DateTime.parse(json['departing_at'] as String),
      arrivingAt: DateTime.parse(json['arriving_at'] as String),
      carrierName: carrier?['name'] as String? ?? 'Unbekannte Airline',
    );
  }
}
