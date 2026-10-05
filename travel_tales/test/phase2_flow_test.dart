import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/views/dashboard/widgets/trip_card.dart';
import 'package:travel_tales/views/trip/trip_overview_screen.dart';

void main() {
  group('Phase 2 Flow & Screen Tests', () {
    testWidgets('TripCard renders title, date range, duration, destination and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      final trip = TripModel(
        id: 'test-1',
        title: 'Bali Adventure',
        destination: 'Indonesia',
        startDate: DateTime(2025, 4, 12),
        endDate: DateTime(2025, 4, 20),
        budget: 40000.0,
        isOfflineReady: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(
              trip: trip,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Bali Adventure'), findsOneWidget);
      expect(find.text('12 Apr - 20 Apr 2025'), findsOneWidget);
      expect(find.text('9 days'), findsOneWidget);
      expect(find.text('Indonesia'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);

      await tester.tap(find.text('Bali Adventure'));
      expect(tapped, isTrue);
    });

    testWidgets('TripOverviewScreen renders stats and quick access cards dynamically', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'trip-bali-1',
        title: 'Bali Adventure',
        destination: 'Indonesia',
        startDate: DateTime(2025, 4, 12),
        endDate: DateTime(2025, 4, 20),
        budget: 40000.0,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TripProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ChangeNotifierProvider(create: (_) => GuideProvider()),
          ],
          child: MaterialApp(
            home: TripOverviewScreen(trip: trip),
          ),
        ),
      );

      expect(find.text('Bali Adventure'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('Guides'), findsOneWidget);
      expect(find.text('Days Left'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Local Guides'), findsOneWidget);
      expect(find.text('Maps'), findsOneWidget);
    });
  });
}
