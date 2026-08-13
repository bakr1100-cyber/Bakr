import 'dart:convert';

import 'package:http/http.dart' as http;

import '../firebase_options.dart';

/// Reads/writes a single per-user document in Cloud Firestore
/// (`/users/{uid}`) via Firestore's plain REST API
/// (https://firebase.google.com/docs/firestore/reference/rest), the same
/// "no Firebase JS SDK, just `http` + a Bearer token" approach [AuthProvider]
/// uses for Firebase Auth - for the same reason: no iframe/popup machinery
/// to break on iOS WebKit, and no new package to add.
///
/// Firestore's REST API represents field values as typed wrapper objects
/// (`{"stringValue": "x"}`, `{"doubleValue": 1.5}`, ...) instead of plain
/// JSON - [_encodeValue]/[_decodeValue] convert to/from that shape so every
/// other part of the app can keep working with plain `Map<String, dynamic>`.
///
/// Firestore Security Rules (set in the Firebase console) must restrict
/// `/users/{uid}` to `request.auth.uid == uid` - the Bearer token passed
/// here is a real Firebase Auth ID token, so `request.auth` is populated
/// the same way it would be via the JS SDK.
class CloudSyncService {
  CloudSyncService({http.Client? client, String? projectId})
      : _client = client ?? http.Client(),
        _projectId = projectId ?? DefaultFirebaseOptions.web.projectId;

  final http.Client _client;
  final String _projectId;

  String _documentUrl(String uid) =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$uid';

  /// Returns `null` if the user has no stored document yet (first sync).
  Future<Map<String, dynamic>?> fetchUserDocument({
    required String uid,
    required String idToken,
  }) async {
    final response = await _client.get(
      Uri.parse(_documentUrl(uid)),
      headers: {'Authorization': 'Bearer $idToken'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw CloudSyncException('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = decoded['fields'] as Map<String, dynamic>? ?? {};
    return fields.map((key, value) => MapEntry(key, _decodeValue(value as Map<String, dynamic>)));
  }

  /// Updates only the top-level fields present in [data], leaving any other
  /// fields on the document untouched - e.g. calling this with just
  /// `{'pushToken': ...}` must not wipe out `preferences`/`priceAlerts`
  /// written by a previous call. Firestore's PATCH replaces the *whole*
  /// document unless an `updateMask` is given, so every call here passes
  /// one `updateMask.fieldPaths` per key in [data]; this also creates the
  /// document (with just those fields) if it doesn't exist yet.
  Future<void> saveUserDocument({
    required String uid,
    required String idToken,
    required Map<String, dynamic> data,
  }) async {
    final fields = data.map((key, value) => MapEntry(key, _encodeValue(value)));
    final maskQuery =
        data.keys.map((key) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(key)}').join('&');
    final response = await _client
        .patch(
          Uri.parse('${_documentUrl(uid)}?$maskQuery'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fields': fields}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw CloudSyncException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()}
      };
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields':
              value.map((key, val) => MapEntry(key as String, _encodeValue(val))),
        }
      };
    }
    throw ArgumentError('Unsupported Firestore value type: ${value.runtimeType}');
  }

  static dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('doubleValue')) return (value['doubleValue'] as num).toDouble();
    if (value.containsKey('stringValue')) return value['stringValue'] as String;
    if (value.containsKey('arrayValue')) {
      final values =
          (value['arrayValue'] as Map<String, dynamic>?)?['values'] as List? ?? [];
      return values.map((v) => _decodeValue(v as Map<String, dynamic>)).toList();
    }
    if (value.containsKey('mapValue')) {
      final fields =
          (value['mapValue'] as Map<String, dynamic>?)?['fields'] as Map<String, dynamic>? ?? {};
      return fields.map((key, val) => MapEntry(key, _decodeValue(val as Map<String, dynamic>)));
    }
    return null;
  }
}

class CloudSyncException implements Exception {
  CloudSyncException(this.message);
  final String message;

  @override
  String toString() => 'CloudSyncException: $message';
}
