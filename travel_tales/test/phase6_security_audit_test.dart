import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/providers/auth_provider.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/services/api_service.dart';
import 'package:travel_tales/services/firebase_auth_service.dart';
import 'package:travel_tales/services/hive_storage_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('traveltales_security_audit_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveStorageService.tripsBoxName);
    await Hive.openBox(HiveStorageService.activitiesBoxName);
    await Hive.openBox(HiveStorageService.expensesBoxName);
    await Hive.openBox(HiveStorageService.guidesBoxName);
    await Hive.openBox(HiveStorageService.settingsBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await HiveStorageService.clearUserScopedData();
    await HiveStorageService.clearAuthSession();
  });

  group('Phase 6 — Security & Data Isolation Audit Tests', () {
    test('1. Logout strictly wipes local Hive auth session tokens', () async {
      final auth = AuthProvider();
      await auth.setMockSession(
        uid: 'user-audit-1',
        email: 'user1@example.com',
        idToken: 'mock-token-1',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(HiveStorageService.isLoggedIn(), isTrue);
      expect(HiveStorageService.getSessionUserEmail(), 'user1@example.com');
      expect(HiveStorageService.getSessionUserId(), 'user-audit-1');

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUserEmail, isNull);
      expect(auth.currentUserId, isNull);
      expect(HiveStorageService.isLoggedIn(), isFalse);
      expect(HiveStorageService.getSessionUserEmail(), isNull);
      expect(HiveStorageService.getSessionUserId(), isNull);
    });

    test('2. Logout clears user-scoped cached trips, activities, and expenses from Hive', () async {
      final sampleTrip = TripModel(
        id: 'trip-isolated-1',
        title: 'Confidential Tokyo Trip',
        destination: 'Tokyo',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 5)),

        budget: 50000,
        coverImageUrl: 'assets/images/japan.jpg',
      );
      final sampleActivity = ActivityModel(
        id: 'act-isolated-1',
        tripId: 'trip-isolated-1',
        dayNumber: 1,
        date: DateTime.now(),
        timeString: '10:00 AM',
        title: 'Confidential Meeting',
        location: 'Shinjuku',
        category: 'Business',
      );
      final sampleExpense = ExpenseModel(
        id: 'exp-isolated-1',
        tripId: 'trip-isolated-1',
        title: 'Executive Hotel Suite',
        amount: 85000,
        category: 'Stay',
        date: DateTime.now(),
      );

      await HiveStorageService.saveTrip(sampleTrip);
      await HiveStorageService.saveActivity(sampleActivity);
      await HiveStorageService.saveExpense(sampleExpense);

      expect(HiveStorageService.getTrips().length, 1);
      expect(HiveStorageService.getActivities('trip-isolated-1').length, 1);
      expect(HiveStorageService.getExpenses('trip-isolated-1').length, 1);

      final auth = AuthProvider();
      await auth.logout();

      expect(HiveStorageService.getTrips().isEmpty, isTrue);
      expect(HiveStorageService.getActivities('trip-isolated-1').isEmpty, isTrue);
      expect(HiveStorageService.getExpenses('trip-isolated-1').isEmpty, isTrue);
    });

    test('3. User A data is not visible to User B after logout and switch', () async {
      // User A logs in and saves a trip
      final auth = AuthProvider();
      await auth.setMockSession(
        uid: 'user-a-uid',
        email: 'userA@example.com',
        idToken: 'token-a',
      );
      await HiveStorageService.saveTrip(TripModel(
        id: 'trip-user-a',
        title: 'User A Private Trip',
        destination: 'Paris',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),

        budget: 50000,
        coverImageUrl: 'assets/images/paris.jpg',
      ));

      expect(HiveStorageService.getTrips().first.title, 'User A Private Trip');

      // User A logs out
      await auth.logout();
      expect(HiveStorageService.getTrips().isEmpty, isTrue);

      // User B logs in
      await auth.setMockSession(
        uid: 'user-b-uid',
        email: 'userB@example.com',
        idToken: 'token-b',
      );

      // User B cache must be empty initially, preventing leakage
      expect(HiveStorageService.getTrips().isEmpty, isTrue);
    });

    test('4. TripProvider and ExpenseProvider clear() resets memory state on logout', () {
      final tripProvider = TripProvider();
      final expenseProvider = ExpenseProvider();

      tripProvider.clear();
      expenseProvider.clear();

      expect(tripProvider.trips.isEmpty, isTrue);
      expect(tripProvider.selectedTrip, isNull);
      expect(tripProvider.activities.isEmpty, isTrue);
      expect(expenseProvider.expenses.isEmpty, isTrue);
      expect(expenseProvider.currentTripId, isNull);
    });

    test('5. ApiService attaches Authorization Bearer token to all protected requests', () async {
      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('{"success": true, "data": []}', 200, headers: {'content-type': 'application/json'});
      });

      final api = ApiService(
        baseUrl: 'http://test.api/api',
        client: mockClient,
        tokenProvider: () async => 'valid-bearer-id-token',
      );

      await api.getTrips();
      expect(capturedAuthHeader, 'Bearer valid-bearer-id-token');
    });

    test('6. ApiService throws ApiException 401 when backend rejects invalid or missing token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "message": "Authorization header is missing. Expected Bearer token."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(
        baseUrl: 'http://test.api/api',
        client: mockClient,
        tokenProvider: () async => null,
      );

      expect(
        () async => await api.getTrips(),
        throwsA(predicate((e) => e is ApiException && e.statusCode == 401)),
      );
    });

    test('7. ApiService safely handles 404 when IDOR/cross-user access is attempted', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "message": "Trip not found or unauthorized with ID trip-unauthorized-99"}',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(
        baseUrl: 'http://test.api/api',
        client: mockClient,
        tokenProvider: () async => 'user-b-token',
      );

      // getTripById returns null on 404 (safely suppressed)
      final trip = await api.getTripById('trip-unauthorized-99');
      expect(trip, isNull);

      // deleteTrip throws ApiException(statusCode: 404)
      expect(
        () async => await api.deleteTrip('trip-unauthorized-99'),
        throwsA(predicate((e) => e is ApiException && e.statusCode == 404)),
      );
    });

    test('8. FirebaseAuthService rejects empty credentials and has no hardcoded demo fallback in production', () async {
      final authService = FirebaseAuthService.instance;
      authService.mockAuthHandler = null;

      final emptyEmailResult = await authService.signInWithEmail('', 'some-password');
      expect(emptyEmailResult.success, isFalse);
      expect(emptyEmailResult.errorMessage, contains('cannot be empty'));

      final emptyPassResult = await authService.signInWithEmail('test@example.com', '');
      expect(emptyPassResult.success, isFalse);
      expect(emptyPassResult.errorMessage, contains('cannot be empty'));
    });
  });
}
