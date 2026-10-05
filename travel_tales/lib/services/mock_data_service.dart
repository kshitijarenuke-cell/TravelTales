import '../models/trip_model.dart';
import '../models/activity_model.dart';
import '../models/expense_model.dart';
import '../models/guide_model.dart';
import 'hive_storage_service.dart';

class MockDataService {
  static Future<void> seedInitialDataIfEmpty() async {
    final existingTrips = HiveStorageService.getTrips();
    if (existingTrips.isNotEmpty) return;

    // Seed Trips
    final tripBali = TripModel(
      id: 'trip-bali-1',
      title: 'Bali Adventure',
      destination: 'Indonesia',
      startDate: DateTime(2025, 4, 12),
      endDate: DateTime(2025, 4, 20),
      budget: 40000.0,
      isOfflineReady: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=800&q=80',
    );

    final tripGoa = TripModel(
      id: 'trip-goa-2',
      title: 'Goa Getaway',
      destination: 'India',
      startDate: DateTime(2025, 5, 5),
      endDate: DateTime(2025, 5, 10),
      budget: 25000.0,
      isOfflineReady: false,
      coverImageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80',
    );

    final tripManali = TripModel(
      id: 'trip-manali-3',
      title: 'Manali Escape',
      destination: 'India',
      startDate: DateTime(2025, 6, 15),
      endDate: DateTime(2025, 6, 22),
      budget: 35000.0,
      isOfflineReady: false,
      coverImageUrl: 'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?auto=format&fit=crop&w=800&q=80',
    );

    await HiveStorageService.saveTrip(tripBali);
    await HiveStorageService.saveTrip(tripGoa);
    await HiveStorageService.saveTrip(tripManali);

    // Seed Activities for Bali
    final activities = [
      ActivityModel(
        id: 'act-1',
        tripId: 'trip-bali-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '08:00',
        title: 'Breakfast',
        location: 'Cafe Wayan',
        category: 'Breakfast',
        notes: 'Try traditional Balinese organic coffee and pancakes',
        latitude: -8.5195,
        longitude: 115.2633,
      ),
      ActivityModel(
        id: 'act-2',
        tripId: 'trip-bali-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '10:00',
        title: 'Uluwatu Temple',
        location: 'Temple · 2 hrs',
        category: 'Temple',
        notes: 'Cliff-edge temple with stunning ocean views',
        latitude: -8.8291,
        longitude: 115.0848,
      ),
      ActivityModel(
        id: 'act-3',
        tripId: 'trip-bali-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '13:00',
        title: 'Lunch',
        location: 'Single Fin Bali',
        category: 'Lunch',
        notes: 'Surfer hotspot with panoramic sea view',
        latitude: -8.8149,
        longitude: 115.0884,
      ),
      ActivityModel(
        id: 'act-4',
        tripId: 'trip-bali-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '16:00',
        title: 'Beach Club',
        location: 'Bingin Beach',
        category: 'Beach Club',
        notes: 'Sunset chilling and refreshing drinks',
        latitude: -8.8058,
        longitude: 115.1130,
      ),
      ActivityModel(
        id: 'act-5',
        tripId: 'trip-bali-1',
        dayNumber: 1,
        date: DateTime(2025, 4, 12),
        timeString: '19:00',
        title: 'Dinner',
        location: 'The Loft',
        category: 'Dinner',
        notes: 'Artisan healthy gourmet dining',
        latitude: -8.6539,
        longitude: 115.1301,
      ),
      ActivityModel(
        id: 'act-6',
        tripId: 'trip-bali-1',
        dayNumber: 2,
        date: DateTime(2025, 4, 13),
        timeString: '09:00',
        title: 'Sacred Monkey Forest',
        location: 'Ubud Sanctuary',
        category: 'Nature',
        notes: 'Walk through ancient temple forest with macaques',
        latitude: -8.5188,
        longitude: 115.2587,
      ),
      ActivityModel(
        id: 'act-7',
        tripId: 'trip-bali-1',
        dayNumber: 2,
        date: DateTime(2025, 4, 13),
        timeString: '14:30',
        title: 'Tegallalang Rice Terrace',
        location: 'Tegallalang',
        category: 'Sightseeing',
        notes: 'Iconic stepped green rice paddies and jungle swings',
        latitude: -8.4347,
        longitude: 115.2796,
      ),
      ActivityModel(
        id: 'act-8',
        tripId: 'trip-bali-1',
        dayNumber: 3,
        date: DateTime(2025, 4, 14),
        timeString: '06:00',
        title: 'Mount Batur Sunrise Trek',
        location: 'Kintamani',
        category: 'Adventure',
        notes: 'Early morning volcano summit trek above the clouds',
        latitude: -8.2421,
        longitude: 115.3753,
      ),
      ActivityModel(
        id: 'act-9',
        tripId: 'trip-bali-1',
        dayNumber: 4,
        date: DateTime(2025, 4, 15),
        timeString: '10:00',
        title: 'Nusa Penida Boat Tour',
        location: 'Sanur Port',
        category: 'Island Tour',
        notes: 'Speedboat to Kelingking T-Rex cliff and snorkeling',
        latitude: -8.7278,
        longitude: 115.5444,
      ),
    ];

    for (final act in activities) {
      await HiveStorageService.saveActivity(act);
    }

    // Seed Expenses for Bali (Total: ₹ 24,500)
    final expenses = [
      ExpenseModel(
        id: 'exp-1',
        tripId: 'trip-bali-1',
        title: 'Flight Tickets',
        amount: 12000.0,
        category: 'Flight',
        date: DateTime(2025, 4, 12),
        notes: 'Roundtrip flights',
      ),
      ExpenseModel(
        id: 'exp-2',
        tripId: 'trip-bali-1',
        title: 'Hotel Stay',
        amount: 8500.0,
        category: 'Hotel',
        date: DateTime(2025, 4, 12),
        notes: 'Eco-resort villa booking',
      ),
      ExpenseModel(
        id: 'exp-3',
        tripId: 'trip-bali-1',
        title: 'Food',
        amount: 2300.0,
        category: 'Food',
        date: DateTime(2025, 4, 13),
        notes: 'Cafes and local warung meals',
      ),
      ExpenseModel(
        id: 'exp-4',
        tripId: 'trip-bali-1',
        title: 'Transport',
        amount: 1200.0,
        category: 'Transport',
        date: DateTime(2025, 4, 14),
        notes: 'Scooter rental & fuel',
      ),
    ];

    for (final exp in expenses) {
      await HiveStorageService.saveExpense(exp);
    }

    // Seed Local Guides
    final guides = [
      GuideModel(
        id: 'guide-1',
        name: 'Wayan Sudra',
        tourTitle: 'Uluwatu Sunset Tour',
        location: 'Uluwatu, Bali',
        category: 'Culture',
        rating: 4.8,
        reviewsCount: 1200,
        pricePerPerson: 1500.0,
        description: 'Born and raised in Uluwatu, specializing in clifftop temple folklore, traditional Kecak fire dance secrets, and secluded sunset vistas.',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        languages: ['English', 'Indonesian', 'Balinese'],
        isFavorite: true,
        latitude: -8.8291,
        longitude: 115.0848,
      ),
      GuideModel(
        id: 'guide-2',
        name: 'Made Artha',
        tourTitle: 'Local Food Tour',
        location: 'Ubud & Denpasar',
        category: 'Food',
        rating: 4.7,
        reviewsCount: 856,
        pricePerPerson: 1200.0,
        description: 'Passionate culinary explorer taking you off the tourist trail into secret night markets, authentic roast suckling pork (Babi Guling), and spice gardens.',
        imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        languages: ['English', 'Indonesian'],
        isFavorite: false,
        latitude: -8.5069,
        longitude: 115.2625,
      ),
      GuideModel(
        id: 'guide-3',
        name: 'Ketut Sujana',
        tourTitle: 'Bali Cultural Tour',
        location: 'Central Bali',
        category: 'Culture',
        rating: 4.9,
        reviewsCount: 1100,
        pricePerPerson: 1400.0,
        description: 'Certified heritage guide leading immersive visits to water purification temples (Tirta Empul), royal palaces, and artisan stone carving villages.',
        imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        languages: ['English', 'French', 'Indonesian'],
        isFavorite: false,
        latitude: -8.4150,
        longitude: 115.3142,
      ),
      GuideModel(
        id: 'guide-4',
        name: 'Nyoman Putra',
        tourTitle: 'Hidden Beaches Tour',
        location: 'Bukit Peninsula',
        category: 'Adventure',
        rating: 4.6,
        reviewsCount: 732,
        pricePerPerson: 1400.0,
        description: 'Explore secret cove beaches, limestone sea caves, and hidden surf spots that cannot be found on standard tourist maps.',
        imageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=400&q=80',
        languages: ['English', 'Indonesian'],
        isFavorite: false,
        latitude: -8.8447,
        longitude: 115.1205,
      ),
      GuideModel(
        id: 'guide-5',
        name: 'Gede Windu',
        tourTitle: 'Mount Batur Sunrise Trek',
        location: 'Kintamani',
        category: 'Adventure',
        rating: 4.9,
        reviewsCount: 2300,
        pricePerPerson: 2200.0,
        description: 'Experienced mountain guide who has summited Mount Batur over 1,500 times. Expert in safety, volcanic steam cooking, and astronomy.',
        imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
        languages: ['English', 'German', 'Indonesian'],
        isFavorite: false,
        latitude: -8.2421,
        longitude: 115.3753,
      ),
    ];

    await HiveStorageService.saveGuides(guides);
  }
}
