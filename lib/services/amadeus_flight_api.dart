import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for Amadeus for Developers
/// (https://developers.amadeus.com) - self-serve signup, free sandbox
/// (test environment) with real (though limited/cached, not fully live)
/// flight data, unlike Duffel's fictional test-airline sandbox. Handles
/// the OAuth2 client-credentials token dance and the Flight Offers Search
/// endpoint. Amadeus has no rail/bus data, so this is only ever used for
/// individual flight legs.
class AmadeusFlightApi {
  AmadeusFlightApi({
    required this.clientId,
    required this.clientSecret,
    http.Client? client,
    this.baseUrl = 'https://test.api.amadeus.com',
  }) : _client = client ?? http.Client();

  final String clientId;
  final String clientSecret;
  final String baseUrl;
  final http.Client _client;

  String? _accessToken;
  DateTime? _tokenExpiresAt;

  Future<String> _accessTokenOrFetch() async {
    final cached = _accessToken;
    final expiry = _tokenExpiresAt;
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
      return cached;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/v1/security/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode >= 400) {
      throw AmadeusApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['access_token'] as String;
    final expiresInSeconds = body['expires_in'] as int;

    _accessToken = token;
    // Refresh a little early so we never call the API with a token that
    // expired mid-flight.
    _tokenExpiresAt =
        DateTime.now().add(Duration(seconds: expiresInSeconds - 30));
    return token;
  }

  /// Searches one-way flight offers, cheapest first. Returns an empty list
  /// (never throws) when Amadeus simply has no offers for the route/date;
  /// network/auth errors throw [AmadeusApiException].
  Future<List<AmadeusOffer>> searchFlightOffers({
    required String originIata,
    required String destinationIata,
    required DateTime departureDate,
    int adults = 1,
    int max = 5,
  }) async {
    final token = await _accessTokenOrFetch();

    final uri = Uri.parse('$baseUrl/v2/shopping/flight-offers').replace(
      queryParameters: {
        'originLocationCode': originIata,
        'destinationLocationCode': destinationIata,
        'departureDate': _dateOnly(departureDate),
        'adults': adults.toString(),
        'max': max.toString(),
        'currencyCode': 'EUR',
      },
    );

    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode >= 400) {
      throw AmadeusApiException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (decoded['data'] as List?) ?? const [];
    final carrierNames =
        (decoded['dictionaries'] as Map<String, dynamic>?)?['carriers']
                as Map<String, dynamic>? ??
            const {};

    final offers = data
        .map((o) => AmadeusOffer.fromJson(o as Map<String, dynamic>, carrierNames))
        .toList()
      ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    return offers;
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void close() => _client.close();
}

class AmadeusApiException implements Exception {
  AmadeusApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Amadeus API error $statusCode: $body';
}

class AmadeusOffer {
  const AmadeusOffer({
    required this.id,
    required this.totalPrice,
    required this.currency,
    required this.departure,
    required this.arrival,
    required this.carrierName,
  });

  final String id;
  final double totalPrice;
  final String currency;
  final DateTime departure;
  final DateTime arrival;
  final String carrierName;

  factory AmadeusOffer.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> carrierNames,
  ) {
    final itineraries = json['itineraries'] as List;
    final segments = (itineraries.first as Map<String, dynamic>)['segments'] as List;
    final firstSegment = segments.first as Map<String, dynamic>;
    final lastSegment = segments.last as Map<String, dynamic>;
    final price = json['price'] as Map<String, dynamic>;
    final carrierCode = firstSegment['carrierCode'] as String?;

    return AmadeusOffer(
      id: json['id'] as String,
      totalPrice: double.parse(price['total'] as String),
      currency: price['currency'] as String,
      departure: DateTime.parse(
        (firstSegment['departure'] as Map<String, dynamic>)['at'] as String,
      ),
      arrival: DateTime.parse(
        (lastSegment['arrival'] as Map<String, dynamic>)['at'] as String,
      ),
      carrierName: carrierNames[carrierCode] as String? ?? carrierCode ?? 'Unbekannte Airline',
    );
  }
}
