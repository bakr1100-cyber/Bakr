import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/services/cloud_sync_service.dart';

void main() {
  group('CloudSyncService', () {
    test('fetchUserDocument returns null on a 404 (no document yet)', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final service = CloudSyncService(client: client, projectId: 'test-project');

      final result = await service.fetchUserDocument(uid: 'u1', idToken: 'tok');

      expect(result, isNull);
    });

    test('fetchUserDocument decodes Firestore typed fields back to plain values', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer tok');
        expect(request.url.toString(), contains('/users/u1'));
        return http.Response(
          jsonEncode({
            'fields': {
              'preferences': {
                'mapValue': {
                  'fields': {
                    'favoriteOriginAirportCode': {'stringValue': 'DUS'},
                    'usualMaxBudgetEur': {'doubleValue': 250.0},
                    'travelsWithFamily': {'booleanValue': true},
                    'favoriteDestinationAirportCode': {'nullValue': null},
                    'favoriteAirlines': {
                      'arrayValue': {
                        'values': [
                          {'stringValue': 'RAM'},
                          {'stringValue': 'TUI'},
                        ]
                      }
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
      });
      final service = CloudSyncService(client: client, projectId: 'test-project');

      final result = await service.fetchUserDocument(uid: 'u1', idToken: 'tok');

      expect(result, isNotNull);
      final preferences = result!['preferences'] as Map;
      expect(preferences['favoriteOriginAirportCode'], 'DUS');
      expect(preferences['usualMaxBudgetEur'], 250.0);
      expect(preferences['travelsWithFamily'], true);
      expect(preferences['favoriteDestinationAirportCode'], isNull);
      expect(preferences['favoriteAirlines'], ['RAM', 'TUI']);
      expect(result['priceAlerts'], isEmpty);
    });

    test('saveUserDocument PATCHes typed fields built from plain values', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });
      final service = CloudSyncService(client: client, projectId: 'test-project');

      await service.saveUserDocument(
        uid: 'u1',
        idToken: 'tok',
        data: {
          'preferences': {'usualMaxBudgetEur': 199.5, 'travelsWithFamily': false},
          'priceAlerts': <Map<String, dynamic>>[],
        },
      );

      expect(captured.method, 'PATCH');
      expect(captured.headers['Authorization'], 'Bearer tok');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>;
      final prefsFields =
          ((fields['preferences'] as Map)['mapValue'] as Map)['fields'] as Map;
      expect(prefsFields['usualMaxBudgetEur'], {'doubleValue': 199.5});
      expect(prefsFields['travelsWithFamily'], {'booleanValue': false});
    });

    test('fetchUserDocument throws CloudSyncException on an unexpected error status', () async {
      final client = MockClient((request) async => http.Response('server error', 500));
      final service = CloudSyncService(client: client, projectId: 'test-project');

      expect(
        () => service.fetchUserDocument(uid: 'u1', idToken: 'tok'),
        throwsA(isA<CloudSyncException>()),
      );
    });
  });
}
