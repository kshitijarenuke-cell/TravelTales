import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/providers/auth_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/providers/offline_map_provider.dart';
import 'package:travel_tales/providers/settings_provider.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/services/firebase_auth_service.dart';
import 'package:travel_tales/services/hive_storage_service.dart';
import 'package:travel_tales/services/itinerary_generator_service.dart';
import 'package:travel_tales/services/mock_data_service.dart';
import 'package:travel_tales/views/expenses/expenses_screen.dart';
import 'package:travel_tales/views/itinerary/add_activity_screen.dart';
import 'package:travel_tales/views/maps/maps_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('traveltales_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveStorageService.tripsBoxName);
    await Hive.openBox(HiveStorageService.activitiesBoxName);
    await Hive.openBox(HiveStorageService.expensesBoxName);
    await Hive.openBox(HiveStorageService.guidesBoxName);
    await Hive.openBox(HiveStorageService.settingsBoxName);
    await Hive.openBox(HiveStorageService.offlineMapsBoxName);
    await MockDataService.seedInitialDataIfEmpty();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Part 1 & 2: Smart Itinerary Generation, Editing, and Deletion', () {
    test('1. Mumbai trip automatically generates starter itinerary', () async {
      final trip = TripModel(
        id: 'trip-mumbai-test',
        title: 'Mumbai City Break',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 25000,
      );

      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      expect(activities.isNotEmpty, isTrue);
      final titles = activities.map((a) => a.title).toList();
      expect(titles.any((t) => t.contains('Gateway of India')), isTrue);
      expect(titles.any((t) => t.contains('Colaba Causeway')), isTrue);
      expect(titles.any((t) => t.contains('Marine Drive')), isTrue);
      expect(titles.any((t) => t.contains('Siddhivinayak Temple')), isTrue);
      expect(titles.any((t) => t.contains('Juhu Beach')), isTrue);
    });

    test('2. Generated activities belong to the correct trip', () async {
      final trip = TripModel(
        id: 'trip-goa-test',
        title: 'Goa Holiday',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 10),
        endDate: DateTime(2025, 11, 14),
        budget: 35000,
      );

      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      for (final act in activities) {
        expect(act.tripId, equals(trip.id));
      }
    });

    test('3. Generated activities are assigned to correct dates/days within trip duration', () async {
      final trip = TripModel(
        id: 'trip-bali-test',
        title: 'Bali Getaway',
        destination: 'Bali',
        startDate: DateTime(2025, 5, 1),
        endDate: DateTime(2025, 5, 3), // 3 days
        budget: 45000,
      );

      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      expect(trip.durationInDays, equals(3));
      for (final act in activities) {
        expect(act.dayNumber, inInclusiveRange(1, 3));
        final expectedDate = trip.startDate.add(Duration(days: act.dayNumber - 1));
        expect(act.date.year, equals(expectedDate.year));
        expect(act.date.month, equals(expectedDate.month));
        expect(act.date.day, equals(expectedDate.day));
      }
    });

    test('4. Generated activities persist in Hive', () async {
      final trip = TripModel(
        id: 'trip-persist-test',
        title: 'Manali Retreat',
        destination: 'Manali',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 3),
        budget: 30000,
      );

      final generated = await ItineraryGeneratorService.generateStarterItinerary(trip);
      final fromHive = HiveStorageService.getActivities(trip.id);

      expect(fromHive.length, equals(generated.length));
      expect(fromHive.first.title, equals(generated.first.title));
    });

    test('5. Generated activity can be edited and updates in Hive and Provider', () async {
      final trip = TripModel(
        id: 'trip-edit-test',
        title: 'Mumbai Tour',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 2),
        budget: 20000,
      );
      await HiveStorageService.saveTrip(trip);
      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final targetActivity = activities.first;
      final updated = targetActivity.copyWith(
        title: 'Gateway of India VIP Sunrise Tour',
        location: 'Apollo Bunder, Colaba, Mumbai',
        notes: 'Pre-booked speed boat ride',
        timeString: '06:30 AM',
      );

      await tripProvider.updateActivity(updated);

      final foundInProvider = tripProvider.activities.firstWhere((a) => a.id == targetActivity.id);
      expect(foundInProvider.title, equals('Gateway of India VIP Sunrise Tour'));
      expect(foundInProvider.notes, equals('Pre-booked speed boat ride'));
      expect(foundInProvider.timeString, equals('06:30 AM'));

      final fromHive = HiveStorageService.getActivities(trip.id);
      final foundInHive = fromHive.firstWhere((a) => a.id == targetActivity.id);
      expect(foundInHive.title, equals('Gateway of India VIP Sunrise Tour'));
    });

    test('6. Generated activity can be deleted and updates Hive and Provider', () async {
      final trip = TripModel(
        id: 'trip-delete-test',
        title: 'Mumbai Quick Trip',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 2),
        budget: 15000,
      );
      await HiveStorageService.saveTrip(trip);
      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);
      final initialCount = tripProvider.activities.length;
      final toDeleteId = activities.first.id;

      await tripProvider.deleteActivity(toDeleteId);

      expect(tripProvider.activities.length, equals(initialCount - 1));
      expect(tripProvider.activities.any((a) => a.id == toDeleteId), isFalse);

      final fromHive = HiveStorageService.getActivities(trip.id);
      expect(fromHive.any((a) => a.id == toDeleteId), isFalse);
    });

    test('7. User can still manually add activities', () async {
      final trip = TripModel(
        id: 'trip-manual-test',
        title: 'Goa Fun',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 1),
        endDate: DateTime(2025, 11, 3),
        budget: 30000,
      );
      await HiveStorageService.saveTrip(trip);
      await ItineraryGeneratorService.generateStarterItinerary(trip);

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);
      final countBefore = tripProvider.activities.length;

      final manualActivity = ActivityModel(
        id: 'manual-act-1',
        tripId: trip.id,
        title: 'Sunset Cruise Party',
        category: 'Adventure',
        location: 'Panaji Jetty',
        dayNumber: 2,
        date: trip.startDate.add(const Duration(days: 1)),
        timeString: '05:30 PM',
        notes: 'Live music & drinks',
        latitude: 15.4989,
        longitude: 73.8278,
      );

      await tripProvider.addActivity(manualActivity);

      expect(tripProvider.activities.length, equals(countBefore + 1));
      expect(tripProvider.activities.any((a) => a.title == 'Sunset Cruise Party'), isTrue);

      final fromHive = HiveStorageService.getActivities(trip.id);
      expect(fromHive.any((a) => a.id == 'manual-act-1'), isTrue);
    });

    test('8. Unknown destination gets generic fallback starter itinerary', () async {
      final trip = TripModel(
        id: 'trip-unknown-test',
        title: 'Kyoto Adventure',
        destination: 'Kyoto',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 9, 3),
        budget: 60000,
      );

      final activities = await ItineraryGeneratorService.generateStarterItinerary(trip);

      expect(activities.isNotEmpty, isTrue);
      expect(activities.length, inInclusiveRange(3, 9));
      for (final a in activities) {
        expect(a.tripId, equals(trip.id));
        expect(a.title.contains('Kyoto'), isTrue);
      }
    });
  });

  group('Part 3 & 4: Maps Search & Category Filter Tests', () {
    testWidgets('9. Map search filters results case-insensitively', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-search-trip',
        title: 'Mumbai Trip',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
        await ItineraryGeneratorService.generateStarterItinerary(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
          ],
          child: const MaterialApp(
            home: MapsScreen(
              bypassPermissionForTesting: true,
              disableTileLayerForTesting: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Search for "Gateway"
      await tester.enterText(find.byType(TextField), 'gateway');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should find Gateway of India
      expect(find.text('No matching places'), findsNothing);

      // Search for non-existent place
      await tester.enterText(find.byType(TextField), 'Eiffel Tower');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No matching places'), findsOneWidget);
    });

    testWidgets('10. Map category filter works', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-filter-trip',
        title: 'Mumbai Exploration',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
        await ItineraryGeneratorService.generateStarterItinerary(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
          ],
          child: const MaterialApp(
            home: MapsScreen(
              bypassPermissionForTesting: true,
              disableTileLayerForTesting: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on 'Sightseeing' filter chip
      await tester.tap(find.text('Sightseeing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // No error, places matching Sightseeing remain visible
      expect(find.text('No matching places'), findsNothing);
    });

    testWidgets('11. Map search + category filter work together', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-both-trip',
        title: 'Mumbai Explorer',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
        await ItineraryGeneratorService.generateStarterItinerary(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
          ],
          child: const MaterialApp(
            home: MapsScreen(
              bypassPermissionForTesting: true,
              disableTileLayerForTesting: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Search = 'Drive' and Category = 'Nature'
      await tester.enterText(find.byType(TextField), 'Drive');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Nature'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Marine Drive is Nature and matches "Drive"
      expect(find.text('No matching places'), findsNothing);
    });

    testWidgets('12. Clearing map search restores results', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-clear-trip',
        title: 'Mumbai Tour',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
        await ItineraryGeneratorService.generateStarterItinerary(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
          ],
          child: const MaterialApp(
            home: MapsScreen(
              bypassPermissionForTesting: true,
              disableTileLayerForTesting: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Type non-existent query
      await tester.enterText(find.byType(TextField), 'NonExistentXYZ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No matching places'), findsOneWidget);

      // Tap clear filters button in empty overlay
      await tester.tap(find.text('Clear Filters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Results restored
      expect(find.text('No matching places'), findsNothing);
    });

    testWidgets('12b. Selecting a map activity and tapping View Details navigates to detail screen with correct data', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-view-details-trip',
        title: 'Mumbai Tour',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
        await ItineraryGeneratorService.generateStarterItinerary(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final mappableActivities = tripProvider.activities
          .where((a) => a.latitude != null && a.longitude != null)
          .toList();
      expect(mappableActivities.isNotEmpty, isTrue);
      final selectedActivity = mappableActivities.first;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
          ],
          child: MaterialApp(
            home: MapsScreen(
              bypassPermissionForTesting: true,
              disableTileLayerForTesting: true,
              initialSelectedActivity: selectedActivity,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The place card appears with "View Details"
      final viewDetailsButton = find.text('View Details');
      expect(viewDetailsButton, findsOneWidget);

      // Tap "View Details"
      await tester.tap(viewDetailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Successfully navigated to AddActivityScreen / Activity Details
      expect(find.byType(AddActivityScreen), findsOneWidget);
      expect(find.text('Activity Details'), findsOneWidget);

      // Verify correct activity data is displayed
      expect(find.text(selectedActivity.title), findsWidgets);
      expect(find.text(selectedActivity.location), findsWidgets);
      if (selectedActivity.notes != null && selectedActivity.notes!.isNotEmpty) {
        expect(find.text(selectedActivity.notes!), findsOneWidget);
      }

      // Verify back navigation returns to MapsScreen
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MapsScreen), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });
  });

  group('Part 5: Expense Filter Icon, Modal, and Sorting', () {
    testWidgets('13. Expense filter icon opens filter UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'expense-test-trip',
        title: 'Goa Trip',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 1),
        endDate: DateTime(2025, 11, 5),
        budget: 50000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final expenseProvider = ExpenseProvider();
      await tester.runAsync(() async {
        await expenseProvider.addExpense(ExpenseModel(
          id: 'exp-1',
          tripId: trip.id,
          title: 'Seafood Lunch',
          amount: 2500,
          category: 'Food',
          date: DateTime(2025, 11, 2),
        ));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
          ],
          child: const MaterialApp(home: ExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter/tune icon in budget card
      final filterIcon = find.byIcon(Icons.tune_rounded);
      expect(filterIcon, findsOneWidget);
      await tester.tap(filterIcon);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and options
      expect(find.text('Filter & Sort Expenses'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('14. Expense filter changes visible transactions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'expense-filter-trip',
        title: 'Goa Trip 2',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 1),
        endDate: DateTime(2025, 11, 5),
        budget: 50000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final expenseProvider = ExpenseProvider();
      await tester.runAsync(() async {
        await expenseProvider.addExpense(ExpenseModel(
          id: 'exp-food',
          tripId: trip.id,
          title: 'Beach Cafe',
          amount: 1200,
          category: 'Food',
          date: DateTime(2025, 11, 1),
        ));
        await expenseProvider.addExpense(ExpenseModel(
          id: 'exp-hotel',
          tripId: trip.id,
          title: 'Resort Stay',
          amount: 8500,
          category: 'Hotel',
          date: DateTime(2025, 11, 2),
        ));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
          ],
          child: const MaterialApp(home: ExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beach Cafe'), findsOneWidget);
      expect(find.text('Resort Stay'), findsOneWidget);

      // Open filter modal
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select 'Food' in modal and tap 'Apply Filters'
      await tester.tap(find.widgetWithText(GestureDetector, 'Food').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Only Food is visible
      expect(find.text('Beach Cafe'), findsOneWidget);
      expect(find.text('Resort Stay'), findsNothing);
    });

    testWidgets('15. Clearing expense filter restores all transactions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'expense-clear-trip',
        title: 'Goa Trip 3',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 1),
        endDate: DateTime(2025, 11, 5),
        budget: 50000,
      );
      await tester.runAsync(() async {
        await HiveStorageService.saveTrip(trip);
      });

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final expenseProvider = ExpenseProvider();
      await tester.runAsync(() async {
        await expenseProvider.addExpense(ExpenseModel(
          id: 'exp-transport',
          tripId: trip.id,
          title: 'Scooter Rental',
          amount: 800,
          category: 'Transport',
          date: DateTime(2025, 11, 1),
        ));
        await expenseProvider.addExpense(ExpenseModel(
          id: 'exp-hotel-2',
          tripId: trip.id,
          title: 'Villa Stay',
          amount: 9000,
          category: 'Hotel',
          date: DateTime(2025, 11, 2),
        ));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
          ],
          child: const MaterialApp(home: ExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Open filter modal and select 'Transport'
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GestureDetector, 'Transport').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Scooter Rental'), findsOneWidget);
      expect(find.text('Villa Stay'), findsNothing);

      // Re-open filter modal and tap 'Reset'
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Both transactions restored
      expect(find.text('Scooter Rental'), findsOneWidget);
      expect(find.text('Villa Stay'), findsOneWidget);
    });
  });

  group('Part 6: Authentication & Regression Safety', () {
    test('16. Existing authentication still works with demo credentials', () async {
      FirebaseAuthService.instance.mockAuthHandler = (email, password, isSignUp) async {
        return AuthResult(
          success: true,
          user: AuthUser(uid: '3iTNBvEvp1QOYyD1StCLoVoFnmi2', email: email),
          idToken: 'test-mock-token:demo-user-kshitija',
        );
      };

      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);

      final success = await auth.login('kshitijarenuke@gmail.com', 'TravelTales@123');
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserEmail, equals('kshitijarenuke@gmail.com'));

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);

      FirebaseAuthService.instance.mockAuthHandler = null;
    });

    test('17. Existing Phase 1–7 functionality remains intact', () async {
      final tripProvider = TripProvider();
      final expenseProvider = ExpenseProvider();
      final guideProvider = GuideProvider();
      guideProvider.loadGuides();
      final settingsProvider = SettingsProvider();
      final offlineMapProvider = OfflineMapProvider();
      await offlineMapProvider.init();

      expect(tripProvider, isNotNull);
      expect(expenseProvider, isNotNull);
      expect(guideProvider.guides.isNotEmpty, isTrue);
      expect(settingsProvider.userName.isNotEmpty, isTrue);
      expect(offlineMapProvider.regions.isNotEmpty, isTrue);
    });
  });
}
