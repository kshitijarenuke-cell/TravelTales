import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/models/guide_model.dart';
import 'package:travel_tales/services/api_service.dart';
import 'package:travel_tales/services/hive_storage_service.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('traveltales_api_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveStorageService.tripsBoxName);
    await Hive.openBox(HiveStorageService.activitiesBoxName);
    await Hive.openBox(HiveStorageService.expensesBoxName);
    await Hive.openBox(HiveStorageService.guidesBoxName);
    await Hive.openBox(HiveStorageService.settingsBoxName);
    await Hive.openBox(HiveStorageService.offlineMapsBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Phase 4: ApiService Unit Tests with MockClient', () {
    test('1. checkHealth() successfully parses health check response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/health');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'TravelTales API is running',
            'firebase': 'connected',
            'firestore': 'connected',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final health = await api.checkHealth();
      expect(health['success'], true);
      expect(health['message'], 'TravelTales API is running');
      expect(health['firebase'], 'connected');
      expect(health['firestore'], 'connected');
    });

    test('2. getTrips() sends GET /api/trips and returns list of TripModels', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/trips');
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'data': [
              {
                'id': 'trip-test-1',
                'title': 'Tokyo Lights',
                'destination': 'Tokyo, Japan',
                'startDate': '2026-10-01T00:00:00.000Z',
                'endDate': '2026-10-07T00:00:00.000Z',
                'budget': 70000.0,
                'isOfflineReady': true,
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final trips = await api.getTrips();
      expect(trips.length, 1);
      expect(trips.first.id, 'trip-test-1');
      expect(trips.first.title, 'Tokyo Lights');
      expect(trips.first.destination, 'Tokyo, Japan');
      expect(trips.first.budget, 70000.0);
    });

    test('3. createTrip() sends POST /api/trips with payload and returns created TripModel', () async {
      final tripInput = TripModel(
        id: 'trip-input-1',
        title: 'Swiss Alps',
        destination: 'Zermatt, Switzerland',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 10),
        budget: 90000.0,
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/trips');
        expect(request.method, 'POST');
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['title'], 'Swiss Alps');
        expect(decoded['destination'], 'Zermatt, Switzerland');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'trip-input-1',
              'title': 'Swiss Alps',
              'destination': 'Zermatt, Switzerland',
              'startDate': '2026-12-01T00:00:00.000Z',
              'endDate': '2026-12-10T00:00:00.000Z',
              'budget': 90000.0,
              'isOfflineReady': false,
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final created = await api.createTrip(tripInput);
      expect(created.id, 'trip-input-1');
      expect(created.title, 'Swiss Alps');
    });

    test('4. deleteTrip() sends DELETE /api/trips/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/trips/trip-to-del');
        expect(request.method, 'DELETE');
        return http.Response(
          jsonEncode({'success': true, 'data': {'id': 'trip-to-del', 'deleted': true}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final deleted = await api.deleteTrip('trip-to-del');
      expect(deleted, true);
    });

    test('5. Activities CRUD methods interact with correct endpoints', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/trips/trip-1/activities') {
          return http.Response(
            jsonEncode({
              'success': true,
              'count': 1,
              'data': [
                {
                  'id': 'act-1',
                  'tripId': 'trip-1',
                  'dayNumber': 1,
                  'date': '2026-06-01T00:00:00.000Z',
                  'timeString': '10:00 AM',
                  'title': 'Museum Visit',
                  'location': 'Central Museum',
                  'category': 'Sightseeing',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path == '/api/trips/trip-1/activities') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'act-created',
                'tripId': 'trip-1',
                'dayNumber': 1,
                'date': '2026-06-01T00:00:00.000Z',
                'timeString': '11:00 AM',
                'title': 'Boat Ride',
                'location': 'Harbor',
                'category': 'Adventure',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'DELETE' && request.url.path == '/api/activities/act-1') {
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'act-1', 'deleted': true}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final acts = await api.getActivities('trip-1');
      expect(acts.length, 1);
      expect(acts.first.title, 'Museum Visit');

      final created = await api.createActivity(
        'trip-1',
        ActivityModel(
          id: 'act-created',
          tripId: 'trip-1',
          dayNumber: 1,
          date: DateTime(2026, 6, 1),
          timeString: '11:00 AM',
          title: 'Boat Ride',
          location: 'Harbor',
          category: 'Adventure',
        ),
      );
      expect(created.id, 'act-created');

      final deleted = await api.deleteActivity('act-1');
      expect(deleted, true);
    });

    test('6. Expenses CRUD methods interact with correct endpoints', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/trips/trip-1/expenses') {
          return http.Response(
            jsonEncode({
              'success': true,
              'count': 1,
              'data': [
                {
                  'id': 'exp-1',
                  'tripId': 'trip-1',
                  'title': 'Dinner',
                  'amount': 1500.0,
                  'category': 'Food',
                  'date': '2026-06-01T20:00:00.000Z',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path == '/api/trips/trip-1/expenses') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'exp-created',
                'tripId': 'trip-1',
                'title': 'Taxi',
                'amount': 400.0,
                'category': 'Transport',
                'date': '2026-06-01T21:00:00.000Z',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'DELETE' && request.url.path == '/api/expenses/exp-1') {
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'exp-1', 'deleted': true}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final expenses = await api.getExpenses('trip-1');
      expect(expenses.length, 1);
      expect(expenses.first.title, 'Dinner');

      final created = await api.createExpense(
        'trip-1',
        ExpenseModel(
          id: 'exp-created',
          tripId: 'trip-1',
          title: 'Taxi',
          amount: 400.0,
          category: 'Transport',
          date: DateTime(2026, 6, 1, 21),
        ),
      );
      expect(created.amount, 400.0);

      final deleted = await api.deleteExpense('exp-1');
      expect(deleted, true);
    });

    test('7. getGuides() supports category and search filtering', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/guides');
        expect(request.url.queryParameters['category'], 'Food');
        expect(request.url.queryParameters['search'], 'Bali');

        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'data': [
              {
                'id': 'guide-test',
                'name': 'Test Guide',
                'tourTitle': 'Bali Food Safari',
                'location': 'Ubud, Bali',
                'category': 'Food',
                'rating': 4.9,
                'reviewsCount': 450,
                'pricePerPerson': 1200.0,
                'description': 'Delicious culinary journey.',
                'languages': ['English', 'Indonesian'],
                'isFavorite': false,
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final guides = await api.getGuides(category: 'Food', search: 'Bali');
      expect(guides.length, 1);
      expect(guides.first.name, 'Test Guide');
      expect(guides.first.tourTitle, 'Bali Food Safari');
    });

    test('8. ApiService handles HTTP error status codes gracefully with ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Validation failed: title is required'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      expect(
        () async => await api.createTrip(TripModel(
          id: 'bad',
          title: '',
          destination: 'Somewhere',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
        )),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('Phase 4: Provider Hive ↔ Backend Sync Tests', () {
    test('9. TripProvider merges remote trips into Hive without duplicates', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 2,
            'data': [
              {
                'id': 'trip-sync-1',
                'title': 'Remote Trip 1',
                'destination': 'Paris',
                'startDate': '2026-07-01T00:00:00.000Z',
                'endDate': '2026-07-07T00:00:00.000Z',
                'budget': 50000.0,
                'isOfflineReady': false,
              },
              {
                'id': 'trip-sync-2',
                'title': 'Remote Trip 2',
                'destination': 'Rome',
                'startDate': '2026-08-01T00:00:00.000Z',
                'endDate': '2026-08-07T00:00:00.000Z',
                'budget': 55000.0,
                'isOfflineReady': false,
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final tripProvider = TripProvider(apiService: api);

      await tripProvider.syncTripsFromApi();
      expect(tripProvider.trips.any((t) => t.id == 'trip-sync-1'), true);
      expect(tripProvider.trips.any((t) => t.id == 'trip-sync-2'), true);

      // Verify Hive also has the synced trips
      final cachedTrips = HiveStorageService.getTrips();
      expect(cachedTrips.any((t) => t.id == 'trip-sync-1'), true);
      expect(cachedTrips.any((t) => t.id == 'trip-sync-2'), true);

      // Re-syncing does not create duplicates
      await tripProvider.syncTripsFromApi();
      final countTrip1 = cachedTrips.where((t) => t.id == 'trip-sync-1').length;
      expect(countTrip1, 1);
    });

    test('10. TripProvider offline resilience: keeps Hive data when API fails', () async {
      final failingClient = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: failingClient);
      final tripProvider = TripProvider(apiService: api);

      // Pre-seed a local trip in Hive
      final localTrip = TripModel(
        id: 'local-trip-offline',
        title: 'Offline Trip',
        destination: 'Himalayas',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 8),
      );
      await HiveStorageService.saveTrip(localTrip);

      // loadTrips attempts remote sync which fails silently, but local trip remains intact
      tripProvider.loadTrips(syncRemote: true);
      // Wait for any asynchronous microtasks
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tripProvider.trips.any((t) => t.id == 'local-trip-offline'), true);
    });

    test('11. GuideProvider merges remote guides while preserving local user favorites', () async {
      // Pre-save guide with isFavorite: true in Hive
      final localGuide = GuideModel(
        id: 'guide-fav-test',
        name: 'Favorited Guide',
        tourTitle: 'Sunrise Tour',
        location: 'Bali',
        category: 'Adventure',
        rating: 4.9,
        reviewsCount: 200,
        pricePerPerson: 1000.0,
        description: 'Great guide',
        isFavorite: true,
      );
      await HiveStorageService.saveGuide(localGuide);

      // Backend returns guide without isFavorite: false
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'data': [
              {
                'id': 'guide-fav-test',
                'name': 'Favorited Guide Updated',
                'tourTitle': 'Sunrise Tour',
                'location': 'Bali',
                'category': 'Adventure',
                'rating': 5.0,
                'reviewsCount': 250,
                'pricePerPerson': 1000.0,
                'description': 'Great guide updated',
                'isFavorite': false, // backend defaults to false
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final guideProvider = GuideProvider(apiService: api);
      guideProvider.loadGuides(syncRemote: false);

      await guideProvider.syncGuidesFromApi();

      final updatedGuide = guideProvider.guides.firstWhere((g) => g.id == 'guide-fav-test');
      expect(updatedGuide.name, 'Favorited Guide Updated');
      expect(updatedGuide.rating, 5.0);
      // User favorite status is preserved!
      expect(updatedGuide.isFavorite, true);
    });

    test('12. ExpenseProvider saves to Hive immediately and syncs with backend', () async {
      bool backendCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/trips/trip-exp-sync/expenses') {
          backendCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'exp-sync-1',
                'tripId': 'trip-exp-sync',
                'title': 'Coffee',
                'amount': 250.0,
                'category': 'Food',
                'date': '2026-06-01T08:00:00.000Z',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(baseUrl: 'http://127.0.0.1:3000/api', client: mockClient);
      final expenseProvider = ExpenseProvider(apiService: api);

      final exp = ExpenseModel(
        id: 'exp-sync-1',
        tripId: 'trip-exp-sync',
        title: 'Coffee',
        amount: 250.0,
        category: 'Food',
        date: DateTime(2026, 6, 1, 8),
      );

      await expenseProvider.addExpense(exp);
      expect(expenseProvider.expenses.any((e) => e.id == 'exp-sync-1'), true);
      expect(backendCalled, true);
      expect(HiveStorageService.getExpenses('trip-exp-sync').any((e) => e.id == 'exp-sync-1'), true);
    });
  });
}
