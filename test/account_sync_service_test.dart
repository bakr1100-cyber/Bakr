import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/providers/auth_provider.dart';
import 'package:marocfly_ai/providers/preferences_provider.dart';
import 'package:marocfly_ai/providers/price_alerts_provider.dart';
import 'package:marocfly_ai/services/account_sync_service.dart';
import 'package:marocfly_ai/services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AccountSyncService] reacts to a login by kicking off an async pull
/// without the listener callback (necessarily synchronous) being able to
/// await it - tests give that a moment to actually run rather than
/// asserting immediately after the triggering call returns.
Future<void> _letAsyncWorkSettle() => Future.delayed(const Duration(milliseconds: 20));

http.Client _authClientSigningIn({required String uid}) {
  return MockClient((request) async {
    if (request.url.path.contains('signInWithPassword')) {
      return http.Response(
        jsonEncode({
          'idToken': 'id-tok',
          'refreshToken': 'refresh-tok',
          'expiresIn': '3600',
          'localId': uid,
          'email': 'diaspora@example.com',
        }),
        200,
      );
    }
    if (request.url.path.contains('lookup')) {
      return http.Response(
        jsonEncode({
          'users': [
            {'email': 'diaspora@example.com', 'emailVerified': true}
          ]
        }),
        200,
      );
    }
    throw StateError('unexpected auth request to ${request.url}');
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccountSyncService', () {
    test('logging in with no existing cloud document seeds it from local state', () async {
      final requestsToFirestore = <http.Request>[];
      final firestoreClient = MockClient((request) async {
        requestsToFirestore.add(request);
        if (request.method == 'GET') return http.Response('', 404);
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: _authClientSigningIn(uid: 'uid-1'));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();
      await preferences.update((p) => p.copyWith(usualMaxBudgetEur: 300));

      AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );

      await auth.signIn(
        email: 'diaspora@example.com',
        password: 'x',
        language: AppLanguage.en,
      );
      await _letAsyncWorkSettle();

      expect(requestsToFirestore.map((r) => r.method), containsAll(['GET', 'PATCH']));
      final patch = requestsToFirestore.firstWhere((r) => r.method == 'PATCH');
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      final prefsFields =
          ((body['fields']['preferences'] as Map)['mapValue'] as Map)['fields'] as Map;
      expect(prefsFields['usualMaxBudgetEur'], {'doubleValue': 300.0});
    });

    test('logging in with an existing cloud document overwrites local state with it', () async {
      final firestoreClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'fields': {
                'preferences': {
                  'mapValue': {
                    'fields': {
                      'usualMaxBudgetEur': {'doubleValue': 777.0},
                      'travelsWithFamily': {'booleanValue': true},
                      'favoriteAirlines': {
                        'arrayValue': {'values': []}
                      },
                    }
                  }
                },
                'priceAlerts': {
                  'arrayValue': {'values': []}
                },
              }
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: _authClientSigningIn(uid: 'uid-2'));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();

      AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );

      await auth.signIn(
        email: 'diaspora@example.com',
        password: 'x',
        language: AppLanguage.en,
      );
      await _letAsyncWorkSettle();

      expect(preferences.preferences.usualMaxBudgetEur, 777.0);
      expect(preferences.preferences.travelsWithFamily, isTrue);
    });

    test('changing preferences while logged in pushes the update to the cloud', () async {
      final requestsToFirestore = <http.Request>[];
      final firestoreClient = MockClient((request) async {
        requestsToFirestore.add(request);
        if (request.method == 'GET') return http.Response('', 404);
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: _authClientSigningIn(uid: 'uid-3'));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();

      AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );
      await auth.signIn(email: 'diaspora@example.com', password: 'x', language: AppLanguage.en);
      await _letAsyncWorkSettle();
      requestsToFirestore.clear();

      await preferences.update((p) => p.copyWith(usualMaxBudgetEur: 450));
      await _letAsyncWorkSettle();

      expect(requestsToFirestore, isNotEmpty);
      expect(requestsToFirestore.every((r) => r.method == 'PATCH'), isTrue);
    });

    test('local changes are not pushed while logged out', () async {
      final requestsToFirestore = <http.Request>[];
      final firestoreClient = MockClient((request) async {
        requestsToFirestore.add(request);
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: MockClient((_) async => http.Response('{}', 500)));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();

      AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );

      await preferences.update((p) => p.copyWith(usualMaxBudgetEur: 450));
      await _letAsyncWorkSettle();

      expect(requestsToFirestore, isEmpty);
    });

    test('setPushToken while already logged in pushes only the pushToken field', () async {
      final requestsToFirestore = <http.Request>[];
      final firestoreClient = MockClient((request) async {
        requestsToFirestore.add(request);
        if (request.method == 'GET') return http.Response('', 404);
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: _authClientSigningIn(uid: 'uid-4'));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();

      final accountSync = AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );
      await auth.signIn(email: 'diaspora@example.com', password: 'x', language: AppLanguage.en);
      await _letAsyncWorkSettle();
      requestsToFirestore.clear();

      accountSync.setPushToken('fcm-token-123');
      await _letAsyncWorkSettle();

      expect(requestsToFirestore, hasLength(1));
      final patch = requestsToFirestore.single;
      expect(patch.method, 'PATCH');
      expect(patch.url.toString(), contains('updateMask.fieldPaths=pushToken'));
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      expect((body['fields'] as Map).keys, ['pushToken']);
      expect(body['fields']['pushToken'], {'stringValue': 'fcm-token-123'});
    });

    test('setPushToken before login is deferred and pushed once the user signs in', () async {
      final requestsToFirestore = <http.Request>[];
      final firestoreClient = MockClient((request) async {
        requestsToFirestore.add(request);
        if (request.method == 'GET') return http.Response('', 404);
        return http.Response('{}', 200);
      });

      final auth = AuthProvider(client: _authClientSigningIn(uid: 'uid-5'));
      final preferences = PreferencesProvider();
      final priceAlerts = PriceAlertsProvider();
      await preferences.load();
      await priceAlerts.load();

      final accountSync = AccountSyncService(
        auth: auth,
        preferences: preferences,
        priceAlerts: priceAlerts,
        cloudSync: CloudSyncService(client: firestoreClient, projectId: 'test-project'),
      );

      // Token becomes known before the user is logged in (e.g. notification
      // permission granted at first launch, before the login screen) -
      // nothing should be pushed yet.
      accountSync.setPushToken('fcm-token-early');
      await _letAsyncWorkSettle();
      expect(requestsToFirestore, isEmpty);

      await auth.signIn(email: 'diaspora@example.com', password: 'x', language: AppLanguage.en);
      await _letAsyncWorkSettle();

      final pushTokenPatch = requestsToFirestore.where(
        (r) =>
            r.method == 'PATCH' &&
            (jsonDecode(r.body) as Map)['fields'].containsKey('pushToken'),
      );
      expect(pushTokenPatch, isNotEmpty);
      final body = jsonDecode(pushTokenPatch.first.body) as Map<String, dynamic>;
      expect(body['fields']['pushToken'], {'stringValue': 'fcm-token-early'});
    });
  });
}
