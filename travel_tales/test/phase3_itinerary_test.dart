import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travel_tales/core/widgets/custom_date_time_picker_dialog.dart';
import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/views/itinerary/itinerary_screen.dart';
import 'package:travel_tales/views/itinerary/widgets/timeline_node.dart';

void main() {
  group('Phase 3 Itinerary & Activity Tests', () {
    testWidgets('TimelineNode renders time, title, location and category badge', (WidgetTester tester) async {
      final activity = ActivityModel(
        id: 'act-101',
        tripId: 'trip-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '08:00',
        title: 'Breakfast',
        location: 'Cafe Wayan',
        category: 'Breakfast',
        notes: 'Organic Balinese coffee',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineNode(
              activity: activity,
              isFirst: true,
              isLast: false,
            ),
          ),
        ),
      );

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Breakfast'), findsNWidgets(2)); // Title and Category badge
      expect(find.text('Cafe Wayan'), findsOneWidget);
      expect(find.text('Organic Balinese coffee'), findsOneWidget);
    });

    testWidgets('CustomDateTimePickerDialog renders header, date tab and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateTimePickerDialog(
              initialDate: DateTime(2025, 4, 12),
              initialTime: const TimeOfDay(hour: 10, minute: 0),
              firstDate: DateTime(2025, 1, 1),
              lastDate: DateTime(2025, 12, 31),
            ),
          ),
        ),
      );

      expect(find.text('Select Date & Time'), findsOneWidget);
      expect(find.text('TRIP SCHEDULE'), findsOneWidget);
      expect(find.text('12 Apr 2025'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('ItineraryScreen renders Day tabs and Add Activity button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = TripModel(
        id: 'trip-bali-test',
        title: 'Bali Adventure',
        destination: 'Indonesia',
        startDate: DateTime(2025, 4, 12),
        endDate: DateTime(2025, 4, 20),
        budget: 40000.0,
      );

      final tripProvider = TripProvider();
      tripProvider.selectTrip(trip);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ChangeNotifierProvider(create: (_) => GuideProvider()),
          ],
          child: const MaterialApp(
            home: ItineraryScreen(),
          ),
        ),
      );

      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('Bali Adventure'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Add Activity'), findsOneWidget);
    });
  });
}
