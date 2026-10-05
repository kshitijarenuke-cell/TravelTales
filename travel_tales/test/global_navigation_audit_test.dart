import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/models/guide_model.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/providers/auth_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/providers/offline_map_provider.dart';
import 'package:travel_tales/providers/settings_provider.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/services/hive_storage_service.dart';
import 'package:travel_tales/services/mock_data_service.dart';
import 'package:travel_tales/views/auth/login_screen.dart';
import 'package:travel_tales/views/expenses/add_expense_screen.dart';
import 'package:travel_tales/views/expenses/expenses_screen.dart';
import 'package:travel_tales/views/guides/filter_guides_screen.dart';
import 'package:travel_tales/views/guides/guide_details_screen.dart';
import 'package:travel_tales/views/guides/guides_screen.dart';
import 'package:travel_tales/views/itinerary/add_activity_screen.dart';
import 'package:travel_tales/views/maps/location_permission_screen.dart';
import 'package:travel_tales/views/maps/maps_screen.dart';
import 'package:travel_tales/views/maps/offline_maps_screen.dart';
import 'package:travel_tales/views/profile/profile_settings_screen.dart';
import 'package:travel_tales/views/splash/splash_screen.dart';
import 'package:travel_tales/views/trip/create_trip_screen.dart';
import 'package:travel_tales/views/trip/trip_overview_screen.dart';

Widget createTestApp({
  required Widget child,
  TripProvider? tripProvider,
  ExpenseProvider? expenseProvider,
  GuideProvider? guideProvider,
  OfflineMapProvider? offlineMapProvider,
  AuthProvider? authProvider,
  SettingsProvider? settingsProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TripProvider>.value(
        value: tripProvider ?? (TripProvider()..loadTrips()),
      ),
      ChangeNotifierProvider<ExpenseProvider>.value(
        value: expenseProvider ?? ExpenseProvider(),
      ),
      ChangeNotifierProvider<GuideProvider>.value(
        value: guideProvider ?? (GuideProvider()..loadGuides()),
      ),
      ChangeNotifierProvider<OfflineMapProvider>.value(
        value: offlineMapProvider ?? OfflineMapProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider ?? SettingsProvider(),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('traveltales_nav_test_');
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

  group('Part 5: Global Back / Close Button Functionality Tests', () {
    testWidgets('1. Maps back button works and returns to previous screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MapsScreen(
                            bypassPermissionForTesting: true,
                            disableTileLayerForTesting: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Maps'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Maps'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MapsScreen), findsOneWidget);

      // Tap Maps back button
      final mapsBackButton = find.byKey(const ValueKey('maps_back_button'));
      expect(mapsBackButton, findsOneWidget);
      await tester.tap(mapsBackButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(MapsScreen), findsNothing);
      expect(find.text('Open Maps'), findsOneWidget);
    });

    testWidgets('2. Maps close button works (closes overlay if selected, closes screen if no overlay)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testActivity = ActivityModel(
        id: 'act-overlay-test',
        tripId: 'trip-1',
        dayNumber: 1,
        date: DateTime(2025, 9, 1),
        timeString: '10:00 AM',
        title: 'Overlay Activity',
        location: 'Kuta',
        category: 'Sightseeing',
        latitude: -8.72,
        longitude: 115.17,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MapsScreen(
                            bypassPermissionForTesting: true,
                            disableTileLayerForTesting: true,
                            initialSelectedActivity: testActivity,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Maps With Selection'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Maps With Selection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Activity card and View Details are visible
      expect(find.text('View Details'), findsOneWidget);

      // Tap Maps close button -> closes overlay first
      final mapsCloseButton = find.byKey(const ValueKey('maps_close_button'));
      expect(mapsCloseButton, findsOneWidget);
      await tester.tap(mapsCloseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('View Details'), findsNothing);
      expect(find.byType(MapsScreen), findsOneWidget);

      // Tap Maps close button again -> navigates back to previous screen
      await tester.tap(mapsCloseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(MapsScreen), findsNothing);
      expect(find.text('Open Maps With Selection'), findsOneWidget);
    });

    testWidgets('3. Offline Maps back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const MapsScreen(
            bypassPermissionForTesting: true,
            disableTileLayerForTesting: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open Offline Maps via Layers FAB
      final layersFab = find.byIcon(Icons.layers_rounded);
      expect(layersFab, findsOneWidget);
      await tester.tap(layersFab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OfflineMapsScreen), findsOneWidget);

      // Tap back button
      final offlineBack = find.byKey(const ValueKey('offline_maps_back_button'));
      expect(offlineBack, findsOneWidget);
      await tester.tap(offlineBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(OfflineMapsScreen), findsNothing);
      expect(find.byType(MapsScreen), findsOneWidget);
    });

    testWidgets('4. Guide Details back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final guide = GuideModel(
        id: 'guide-test-back',
        name: 'Wayan S.',
        tourTitle: 'Sunrise Temple Tour',
        location: 'Ubud, Bali',
        rating: 4.9,
        reviewsCount: 120,
        pricePerPerson: 1500,
        category: 'Culture',
        languages: ['English', 'Indonesian'],
        description: 'Experience authentic Bali.',
      );

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GuideDetailsScreen(guide: guide),
                        ),
                      );
                    },
                    child: const Text('Open Guide Details'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Guide Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideDetailsScreen), findsOneWidget);

      // Tap Guide Details back button
      final guideBack = find.byKey(const ValueKey('guide_details_back_button'));
      expect(guideBack, findsOneWidget);
      await tester.tap(guideBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(GuideDetailsScreen), findsNothing);
      expect(find.text('Open Guide Details'), findsOneWidget);
    });

    testWidgets('5. Trip Overview back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'test-trip-overview-back',
        title: 'Goa Holiday',
        destination: 'Goa',
        startDate: DateTime(2025, 11, 1),
        endDate: DateTime(2025, 11, 5),
        budget: 35000,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TripOverviewScreen(trip: trip),
                        ),
                      );
                    },
                    child: const Text('Open Overview'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Overview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TripOverviewScreen), findsOneWidget);

      final tripBack = find.byKey(const ValueKey('trip_overview_back_button'));
      expect(tripBack, findsOneWidget);
      await tester.tap(tripBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(TripOverviewScreen), findsNothing);
      expect(find.text('Open Overview'), findsOneWidget);
    });

    testWidgets('6. Add Activity back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'trip-add-act-test',
        title: 'Manali Expedition',
        destination: 'Manali',
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 4),
        budget: 40000,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddActivityScreen(
                            trip: trip,
                            initialDayNumber: 1,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Add Activity'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AddActivityScreen), findsOneWidget);

      final addActBack = find.byKey(const ValueKey('add_activity_back_button'));
      expect(addActBack, findsOneWidget);
      await tester.tap(addActBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(AddActivityScreen), findsNothing);
      expect(find.text('Open Add Activity'), findsOneWidget);
    });

    testWidgets('7. Add Expense back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'trip-add-exp-test',
        title: 'Kerala Trip',
        destination: 'Kerala',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 5),
        budget: 30000,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(trip: trip),
                        ),
                      );
                    },
                    child: const Text('Open Add Expense'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Expense'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AddExpenseScreen), findsOneWidget);

      final addExpBack = find.byKey(const ValueKey('add_expense_back_button'));
      expect(addExpBack, findsOneWidget);
      await tester.tap(addExpBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsNothing);
      expect(find.text('Open Add Expense'), findsOneWidget);
    });

    testWidgets('8. Create Trip back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateTripScreen(),
                        ),
                      );
                    },
                    child: const Text('Open Create Trip'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Create Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CreateTripScreen), findsOneWidget);

      final createTripBack = find.byKey(const ValueKey('create_trip_back_button'));
      expect(createTripBack, findsOneWidget);
      await tester.tap(createTripBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(CreateTripScreen), findsNothing);
      expect(find.text('Open Create Trip'), findsOneWidget);
    });

    testWidgets('9. Profile back works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Open Profile'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProfileSettingsScreen), findsOneWidget);

      final profileBack = find.byKey(const ValueKey('profile_back_button'));
      expect(profileBack, findsOneWidget);
      await tester.tap(profileBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(ProfileSettingsScreen), findsNothing);
      expect(find.text('Open Profile'), findsOneWidget);
    });

    testWidgets('10. Modal close/dismiss works on Profile sheets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProfileSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Notifications menu item
      await tester.dragUntilVisible(
        find.text('Notifications'),
        find.byType(SingleChildScrollView),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      // Tap Notifications row
      await tester.tap(find.text('Notifications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Notification Preferences'), findsOneWidget);

      // Tap close button in notification sheet
      final closeNotif = find.byKey(const ValueKey('close_notifications_sheet'));
      expect(closeNotif, findsOneWidget);
      await tester.tap(closeNotif);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('Notification Preferences'), findsNothing);

      // Scroll to Help & Support
      await tester.dragUntilVisible(
        find.text('Help & Support'),
        find.byType(SingleChildScrollView),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      // Tap Help & Support row
      await tester.tap(find.text('Help & Support'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('support@traveltales.app'), findsOneWidget);

      // Tap close button in help support sheet
      final closeHelp = find.byKey(const ValueKey('close_help_support_sheet'));
      expect(closeHelp, findsOneWidget);
      await tester.tap(closeHelp);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('support@traveltales.app'), findsNothing);
    });

    testWidgets('11. Expense filter sheet can be closed', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'expense-filter-close-trip',
        title: 'Jaipur Trip',
        destination: 'Jaipur',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 15000,
      );
      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      final expenseProvider = ExpenseProvider();
      await tester.runAsync(() async {
        await expenseProvider.addExpense(
          ExpenseModel(
            id: 'exp-filter-test-1',
            tripId: trip.id,
            amount: 500,
            category: 'Food',
            title: 'Lunch',
            date: DateTime(2025, 10, 1),
          ),
        );
      });

      await tester.pumpWidget(
        createTestApp(
          tripProvider: tripProvider,
          expenseProvider: expenseProvider,
          child: const ExpensesScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap filter icon in budget progress card
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Filter & Sort Expenses'), findsOneWidget);

      // Tap close button on filter sheet
      final closeFilter = find.byKey(const ValueKey('close_expense_filter'));
      expect(closeFilter, findsOneWidget);
      await tester.tap(closeFilter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Filter & Sort Expenses'), findsNothing);
      expect(find.byType(ExpensesScreen), findsOneWidget);
    });

    testWidgets('12. Guide filter screen can be closed/back navigated', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const GuidesScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open Filter Guides via tune icon in AppBar
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FilterGuidesScreen), findsOneWidget);

      // Tap back button
      final filterGuidesBack = find.byKey(const ValueKey('filter_guides_back_button'));
      expect(filterGuidesBack, findsOneWidget);
      await tester.tap(filterGuidesBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(FilterGuidesScreen), findsNothing);
      expect(find.byType(GuidesScreen), findsOneWidget);
    });

    testWidgets('13. Location Permission back works and triggers onDeny', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool deniedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LocationPermissionScreen(
            onAllow: () {},
            onDeny: () {
              deniedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Allow Location Access'), findsOneWidget);

      // Tap "Not Now"
      await tester.tap(find.text('Not Now'));
      await tester.pump();

      expect(deniedCalled, isTrue);
    });

    testWidgets('14. Login back behavior works correctly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const SplashScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Log In" rich text link on Splash Screen
      final loginLink = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Log In'),
      );
      expect(loginLink, findsOneWidget);
      await tester.tap(loginLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap Login back button
      final loginBack = find.byKey(const ValueKey('login_back_button'));
      expect(loginBack, findsOneWidget);
      await tester.tap(loginBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('15. Existing Logout flow still works and dialog cancel/logout works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const ProfileSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Logout button
      await tester.dragUntilVisible(
        find.text('Logout'),
        find.byType(SingleChildScrollView),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      // Tap Logout row
      await tester.tap(find.text('Logout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog appears
      expect(find.text('Are you sure you want to log out of TravelTales?'), findsOneWidget);

      // Cancel button dismisses dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Are you sure you want to log out of TravelTales?'), findsNothing);
      expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    });

    testWidgets('16. Existing View Details navigation and back still works', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'map-view-details-nav-audit',
        title: 'Mumbai Tour',
        destination: 'Mumbai',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 3),
        budget: 20000,
      );
      final activity = ActivityModel(
        id: 'act-view-details-nav-audit',
        tripId: trip.id,
        dayNumber: 1,
        date: DateTime(2025, 10, 1),
        timeString: '09:00 AM',
        title: 'Marine Drive Walk',
        location: 'Marine Drive, Mumbai',
        category: 'Sightseeing',
        latitude: 18.9432,
        longitude: 72.8234,
        notes: 'Sunset walk',
      );

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        createTestApp(
          tripProvider: tripProvider,
          child: MapsScreen(
            bypassPermissionForTesting: true,
            disableTileLayerForTesting: true,
            initialSelectedActivity: activity,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Place card with "View Details" is visible
      final viewDetailsButton = find.text('View Details');
      expect(viewDetailsButton, findsOneWidget);

      // Tap View Details
      await tester.tap(viewDetailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(AddActivityScreen), findsOneWidget);
      expect(find.text('Activity Details'), findsOneWidget);
      expect(find.text('Marine Drive Walk'), findsWidgets);

      // Back navigation returns to MapsScreen
      final addActBack = find.byKey(const ValueKey('add_activity_back_button'));
      expect(addActBack, findsOneWidget);
      await tester.tap(addActBack);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(MapsScreen), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });
  });
}
