import 'package:flutter_test/flutter_test.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/models/activity_model.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/models/guide_model.dart';

void main() {
  group('TravelTales Models Serialization Tests', () {
    test('TripModel serialization and day calculation', () {
      final trip = TripModel(
        id: 'trip-1',
        title: 'Bali Adventure',
        destination: 'Indonesia',
        startDate: DateTime(2025, 4, 12),
        endDate: DateTime(2025, 4, 20),
        budget: 40000.0,
        isOfflineReady: true,
      );

      expect(trip.durationInDays, 9);
      final map = trip.toMap();
      final reconstructed = TripModel.fromMap(map);
      expect(reconstructed.id, 'trip-1');
      expect(reconstructed.title, 'Bali Adventure');
      expect(reconstructed.destination, 'Indonesia');
      expect(reconstructed.isOfflineReady, true);
    });

    test('ActivityModel serialization', () {
      final act = ActivityModel(
        id: 'act-1',
        tripId: 'trip-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '08:00',
        title: 'Breakfast',
        location: 'Cafe Wayan',
        category: 'Breakfast',
        latitude: -8.5195,
        longitude: 115.2633,
      );

      final map = act.toMap();
      final reconstructed = ActivityModel.fromMap(map);
      expect(reconstructed.title, 'Breakfast');
      expect(reconstructed.timeString, '08:00');
      expect(reconstructed.latitude, -8.5195);
    });

    test('ExpenseModel serialization', () {
      final exp = ExpenseModel(
        id: 'exp-1',
        tripId: 'trip-1',
        title: 'Flight Tickets',
        amount: 12000.0,
        category: 'Flight',
        date: DateTime(2025, 4, 12),
      );

      final map = exp.toMap();
      final reconstructed = ExpenseModel.fromMap(map);
      expect(reconstructed.amount, 12000.0);
      expect(reconstructed.category, 'Flight');
    });

    test('GuideModel serialization and favorites', () {
      final guide = GuideModel(
        id: 'guide-1',
        name: 'Wayan Sudra',
        tourTitle: 'Uluwatu Sunset Tour',
        location: 'Uluwatu, Bali',
        category: 'Culture',
        rating: 4.8,
        reviewsCount: 1200,
        pricePerPerson: 1500.0,
        description: 'Guide bio',
        isFavorite: true,
      );

      final map = guide.toMap();
      final reconstructed = GuideModel.fromMap(map);
      expect(reconstructed.rating, 4.8);
      expect(reconstructed.isFavorite, true);
    });
  });
}
