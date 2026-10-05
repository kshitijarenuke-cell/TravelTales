import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/services/api_service.dart';

void main() {
  group('Phase 4: Flutter ↔ Node.js ↔ Real Firestore Live E2E Integration Test', () {
    final api = ApiService(
      baseUrl: 'http://127.0.0.1:3000/api',
      timeout: const Duration(seconds: 30),
      tokenProvider: () async => 'test-mock-token:flutter-test-user-1',
    );
    bool serverReachable = false;

    setUpAll(() async {
      try {
        final socket = await Socket.connect('127.0.0.1', 3000, timeout: const Duration(seconds: 1));
        await socket.close();
        serverReachable = true;
      } catch (_) {
        serverReachable = false;
      }
    });

    test('1. Verify health check on live Node.js server', () async {
      if (!serverReachable) {
        // Backend server offline; skip in offline environments
        return;
      }
      final health = await api.checkHealth();
      expect(health['success'], true);
      expect(health['message'], 'TravelTales API is running');
      expect(health['firebase'], 'connected');
      expect(health['firestore'], 'connected');
    });

    test(
      '2. Complete Trip CRUD against live backend & Firestore',
      () async {
      if (!serverReachable) {
        return;
      }
      final newTrip = TripModel(
        id: 'flutter-live-trip-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Flutter E2E Kyoto Journey',
        destination: 'Kyoto, Japan',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 8),
        budget: 75000.0,
        isOfflineReady: true,
      );

      // 1. Create Trip
      final created = await api.createTrip(newTrip);
      expect(created.id, newTrip.id);
      expect(created.title, 'Flutter E2E Kyoto Journey');
      expect(created.budget, 75000.0);

      // 2. Fetch Trip by ID
      final fetched = await api.getTripById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Flutter E2E Kyoto Journey');
      expect(fetched.destination, 'Kyoto, Japan');

      // 3. Update Trip
      final updatedTrip = created.copyWith(budget: 80000.0, title: 'Flutter E2E Kyoto Journey (Updated)');
      final updated = await api.updateTrip(updatedTrip);
      expect(updated.budget, 80000.0);
      expect(updated.title, 'Flutter E2E Kyoto Journey (Updated)');

      // 4. Create Activity under Trip
      final activity = ActivityModel(
        id: 'flutter-live-act-${DateTime.now().millisecondsSinceEpoch}',
        tripId: created.id,
        dayNumber: 1,
        date: DateTime(2026, 11, 1),
        timeString: '10:00 AM',
        title: 'Kinkaku-ji Golden Pavilion',
        location: 'Kinkakujicho, Kita Ward, Kyoto',
        category: 'Sightseeing',
        notes: 'Visit Zen Buddhist temple',
      );
      final createdAct = await api.createActivity(created.id, activity);
      expect(createdAct.id, activity.id);
      expect(createdAct.title, 'Kinkaku-ji Golden Pavilion');

      // 5. Fetch Activities for Trip
      final activities = await api.getActivities(created.id);
      expect(activities.any((a) => a.id == activity.id), true);

      // 6. Update Activity
      final updatedAct = createdAct.copyWith(timeString: '10:30 AM');
      final savedAct = await api.updateActivity(updatedAct);
      expect(savedAct.timeString, '10:30 AM');

      // 7. Create Expense under Trip
      final expense = ExpenseModel(
        id: 'flutter-live-exp-${DateTime.now().millisecondsSinceEpoch}',
        tripId: created.id,
        title: 'Temple Admission Tickets',
        amount: 1000.0,
        category: 'Activities',
        date: DateTime(2026, 11, 1),
        notes: '2 adult tickets',
      );
      final createdExp = await api.createExpense(created.id, expense);
      expect(createdExp.id, expense.id);
      expect(createdExp.amount, 1000.0);

      // 8. Fetch Expenses for Trip
      final expenses = await api.getExpenses(created.id);
      expect(expenses.any((e) => e.id == expense.id), true);

      // 9. Update Expense
      final updatedExp = createdExp.copyWith(amount: 1200.0);
      final savedExp = await api.updateExpense(updatedExp);
      expect(savedExp.amount, 1200.0);

      // 10. Load Guides from Backend
      final guides = await api.getGuides();
      expect(guides, isNotEmpty);
      expect(guides.any((g) => g.tourTitle.contains('Uluwatu') || g.name.contains('Wayan')), true);

      // 11. Delete Activity
      final actDeleted = await api.deleteActivity(activity.id);
      expect(actDeleted, true);

      // 12. Delete Expense
      final expDeleted = await api.deleteExpense(expense.id);
      expect(expDeleted, true);

      // 13. Delete Trip
      final tripDeleted = await api.deleteTrip(created.id);
      expect(tripDeleted, true);

      // 14. Verify Trip No Longer Exists
      final deletedCheck = await api.getTripById(created.id);
      expect(deletedCheck, isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
