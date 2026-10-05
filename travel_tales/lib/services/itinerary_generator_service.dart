import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../models/trip_model.dart';
import 'hive_storage_service.dart';

/// Template data entry for destination starter itineraries.
class _ActivityTemplate {
  final String timeString;
  final String title;
  final String location;
  final String category;
  final String notes;
  final double? latitude;
  final double? longitude;

  const _ActivityTemplate({
    required this.timeString,
    required this.title,
    required this.location,
    required this.category,
    required this.notes,
    this.latitude,
    this.longitude,
  });
}

/// Service that automatically generates starter itineraries for trips
/// based on destination matching and actual trip duration.
class ItineraryGeneratorService {
  // Destination-specific templates
  static final Map<String, List<List<_ActivityTemplate>>> _destinationTemplates = {
    'mumbai': [
      // Day 1
      [
        const _ActivityTemplate(
          timeString: '09:00',
          title: 'Gateway of India',
          location: 'Apollo Bandar, Colaba',
          category: 'Sightseeing',
          notes: 'Iconic 20th-century monument overlooking the Arabian Sea',
          latitude: 18.9220,
          longitude: 72.8347,
        ),
        const _ActivityTemplate(
          timeString: '13:00',
          title: 'Colaba Causeway',
          location: 'Colaba, South Mumbai',
          category: 'Food',
          notes: 'Bustling street shopping, historic cafes & street snacks',
          latitude: 18.9217,
          longitude: 72.8317,
        ),
        const _ActivityTemplate(
          timeString: '17:30',
          title: 'Marine Drive',
          location: 'Netaji Subhash Chandra Bose Road',
          category: 'Nature',
          notes: 'Walk along the Queen\'s Necklace for evening sunset views',
          latitude: 18.9432,
          longitude: 72.8230,
        ),
      ],
      // Day 2
      [
        const _ActivityTemplate(
          timeString: '09:30',
          title: 'Siddhivinayak Temple',
          location: 'Prabhadevi',
          category: 'Temple',
          notes: 'Famous Hindu temple dedicated to Lord Ganesha',
          latitude: 19.0169,
          longitude: 72.8304,
        ),
        const _ActivityTemplate(
          timeString: '14:00',
          title: 'Bandra Fort',
          location: 'Bandra West, By the Sea',
          category: 'Sightseeing',
          notes: 'Historic Portuguese fort with panoramic Bandra-Worli Sea Link views',
          latitude: 19.0435,
          longitude: 72.8197,
        ),
        const _ActivityTemplate(
          timeString: '17:30',
          title: 'Bandra Bandstand',
          location: 'Bandstand Promenade',
          category: 'Nature',
          notes: 'Rocky seaside walkway popular for evening sea breezes and cafes',
          latitude: 19.0519,
          longitude: 72.8189,
        ),
      ],
      // Day 3
      [
        const _ActivityTemplate(
          timeString: '10:00',
          title: 'Juhu Beach',
          location: 'Juhu Tara Road',
          category: 'Nature',
          notes: 'Lively beach atmosphere, pav bhaji, bhelpuri and ocean view',
          latitude: 19.0988,
          longitude: 72.8264,
        ),
        const _ActivityTemplate(
          timeString: '16:00',
          title: 'Local shopping / food experience',
          location: 'Linking Road & Hill Road, Bandra',
          category: 'Food',
          notes: 'Street food, fashion shopping, and Mumbai street delights',
          latitude: 19.0657,
          longitude: 72.8335,
        ),
      ],
      // Day 4+ fallback
      [
        const _ActivityTemplate(
          timeString: '10:00',
          title: 'Elephanta Caves Tour',
          location: 'Elephanta Island (Ferry from Gateway)',
          category: 'Culture',
          notes: 'UNESCO World Heritage rock-cut cave temples',
          latitude: 18.9633,
          longitude: 72.9315,
        ),
        const _ActivityTemplate(
          timeString: '16:00',
          title: 'Chhatrapati Shivaji Maharaj Terminus',
          location: 'Fort, Mumbai',
          category: 'Sightseeing',
          notes: 'Splendid Victorian Gothic architecture landmark',
          latitude: 18.9400,
          longitude: 72.8354,
        ),
      ],
    ],

    'goa': [
      // Day 1
      [
        const _ActivityTemplate(
          timeString: '09:00',
          title: 'Calangute Beach & Water Sports',
          location: 'North Goa',
          category: 'Nature',
          notes: 'Parasailing, jet ski, and relaxing by the golden sands',
          latitude: 15.5439,
          longitude: 73.7553,
        ),
        const _ActivityTemplate(
          timeString: '13:30',
          title: 'Beachside Seafood Shacks',
          location: 'Baga Beach',
          category: 'Food',
          notes: 'Goan fish curry and authentic coastal delicacies',
          latitude: 15.5553,
          longitude: 73.7517,
        ),
        const _ActivityTemplate(
          timeString: '17:30',
          title: 'Sunset at Fort Aguada',
          location: 'Sinquerim',
          category: 'Sightseeing',
          notes: '17th-century Portuguese fortress overlooking Mandovi Bay',
          latitude: 15.4920,
          longitude: 73.7737,
        ),
      ],
      // Day 2
      [
        const _ActivityTemplate(
          timeString: '10:00',
          title: 'Basilica of Bom Jesus',
          location: 'Old Goa',
          category: 'Culture',
          notes: 'Baroque UNESCO world heritage site holding mortal remains of St. Francis Xavier',
          latitude: 15.5009,
          longitude: 73.9116,
        ),
        const _ActivityTemplate(
          timeString: '14:30',
          title: 'Fontainhas Latin Quarter Walk',
          location: 'Panaji',
          category: 'Sightseeing',
          notes: 'Colorful colonial Portuguese villas and art cafes',
          latitude: 15.4989,
          longitude: 73.8315,
        ),
        const _ActivityTemplate(
          timeString: '18:00',
          title: 'Mandovi River Sunset Cruise',
          location: 'Panaji Jetty',
          category: 'Activity',
          notes: 'Scenic boat ride with traditional Goan folk performances',
          latitude: 15.5015,
          longitude: 73.8290,
        ),
      ],
      // Day 3
      [
        const _ActivityTemplate(
          timeString: '09:00',
          title: 'Dudhsagar Waterfalls Trek',
          location: 'Sonaulim, Bhagwan Mahaveer Sanctuary',
          category: 'Nature',
          notes: 'Four-tiered milky cascade nestled in the Western Ghats',
          latitude: 15.3144,
          longitude: 74.3143,
        ),
        const _ActivityTemplate(
          timeString: '15:30',
          title: 'Sahakari Spice Plantation Tour',
          location: 'Curti, Ponda',
          category: 'Food',
          notes: 'Spices exploration and traditional buffet lunch',
          latitude: 15.4026,
          longitude: 74.0152,
        ),
      ],
    ],

    'bali': [
      // Day 1
      [
        const _ActivityTemplate(
          timeString: '08:30',
          title: 'Cafe Wayan Breakfast',
          location: 'Monkey Forest Rd, Ubud',
          category: 'Breakfast',
          notes: 'Organic tropical fruits and Balinese coffee',
          latitude: -8.5195,
          longitude: 115.2633,
        ),
        const _ActivityTemplate(
          timeString: '11:00',
          title: 'Sacred Monkey Forest Sanctuary',
          location: 'Ubud, Gianyar',
          category: 'Nature',
          notes: 'Ancient moss-covered temples and wild macaque monkeys',
          latitude: -8.5188,
          longitude: 115.2585,
        ),
        const _ActivityTemplate(
          timeString: '16:30',
          title: 'Uluwatu Temple & Sunset',
          location: 'Pecatu, South Kuta',
          category: 'Temple',
          notes: 'Cliff-edge temple with Kecak Fire Dance at dusk',
          latitude: -8.8291,
          longitude: 115.0848,
        ),
      ],
      // Day 2
      [
        const _ActivityTemplate(
          timeString: '09:00',
          title: 'Tegallalang Rice Terraces',
          location: 'Tegallalang, Ubud',
          category: 'Nature',
          notes: 'Iconic stepped green rice paddies and jungle swings',
          latitude: -8.4343,
          longitude: 115.2785,
        ),
        const _ActivityTemplate(
          timeString: '13:00',
          title: 'Traditional Balinese Feast',
          location: 'Gianyar regency',
          category: 'Lunch',
          notes: 'Nasi Campur and fresh coconut water by the river',
          latitude: -8.5414,
          longitude: 115.3262,
        ),
        const _ActivityTemplate(
          timeString: '16:30',
          title: 'Tanah Lot Sea Temple',
          location: 'Beraban, Tabanan',
          category: 'Temple',
          notes: 'Offshore rocky temple famous for dramatic sunset silhouettes',
          latitude: -8.6212,
          longitude: 115.0868,
        ),
      ],
      // Day 3
      [
        const _ActivityTemplate(
          timeString: '10:00',
          title: 'Seminyak Beach Club',
          location: 'Seminyak Beach',
          category: 'Beach Club',
          notes: 'Daybeds, infinity pool, and coastal beats',
          latitude: -8.6913,
          longitude: 115.1554,
        ),
        const _ActivityTemplate(
          timeString: '15:00',
          title: 'Sukawati Art Market',
          location: 'Gianyar',
          category: 'Sightseeing',
          notes: 'Local paintings, woodcarvings, and handicrafts',
          latitude: -8.5969,
          longitude: 115.2831,
        ),
      ],
    ],

    'manali': [
      // Day 1
      [
        const _ActivityTemplate(
          timeString: '09:30',
          title: 'Hadimba Devi Temple',
          location: 'Dhungri Forest',
          category: 'Temple',
          notes: 'Ancient pagoda-style wooden temple among giant deodar trees',
          latitude: 32.2483,
          longitude: 77.1685,
        ),
        const _ActivityTemplate(
          timeString: '13:30',
          title: 'Old Manali Cafe Hopping',
          location: 'Old Manali Village',
          category: 'Food',
          notes: 'Bohemian cafes, apple crumbles, and riverside vibes',
          latitude: 32.2530,
          longitude: 77.1750,
        ),
        const _ActivityTemplate(
          timeString: '17:00',
          title: 'Mall Road Stroll',
          location: 'Mall Road, Manali Center',
          category: 'Sightseeing',
          notes: 'Woolen shawls, local handicrafts, and hot momos',
          latitude: 32.2396,
          longitude: 77.1887,
        ),
      ],
      // Day 2
      [
        const _ActivityTemplate(
          timeString: '08:30',
          title: 'Solang Valley Adventure Sports',
          location: 'Solang Valley',
          category: 'Activity',
          notes: 'Paragliding, zorbing, and alpine mountain views',
          latitude: 32.3166,
          longitude: 77.1575,
        ),
        const _ActivityTemplate(
          timeString: '15:00',
          title: 'Jogini Waterfall Trek',
          location: 'Vashisht',
          category: 'Nature',
          notes: 'Picturesque pine trail leading to gushing waterfalls',
          latitude: 32.2680,
          longitude: 77.1950,
        ),
      ],
      // Day 3
      [
        const _ActivityTemplate(
          timeString: '09:00',
          title: 'Rohtang Pass Excursion',
          location: 'Rohtang Pass (3,978 m)',
          category: 'Nature',
          notes: 'Majestic Himalayan snow peaks and panoramic glaciers',
          latitude: 32.3716,
          longitude: 77.2466,
        ),
        const _ActivityTemplate(
          timeString: '16:00',
          title: 'Vashisht Hot Water Springs',
          location: 'Vashisht Village',
          category: 'Culture',
          notes: 'Natural sulfur thermal baths and ancient stone temple',
          latitude: 32.2612,
          longitude: 77.1872,
        ),
      ],
    ],
  };

  /// Generates starter activities for [trip] and saves them to Hive.
  /// Returns the list of created ActivityModel items.
  static Future<List<ActivityModel>> generateStarterItinerary(TripModel trip) async {
    final destinationKey = _resolveDestinationKey(trip.destination);
    final days = trip.durationInDays > 0 ? trip.durationInDays : 1;

    final List<ActivityModel> generatedActivities = [];
    const uuid = Uuid();

    for (int dayIndex = 0; dayIndex < days; dayIndex++) {
      final dayNumber = dayIndex + 1;
      final dayDate = trip.startDate.add(Duration(days: dayIndex));

      final templatesForDay = _getTemplatesForDay(
        destinationKey: destinationKey,
        destinationName: trip.destination,
        dayIndex: dayIndex,
      );

      for (final t in templatesForDay) {
        final activity = ActivityModel(
          id: uuid.v4(),
          tripId: trip.id,
          dayNumber: dayNumber,
          date: dayDate,
          timeString: t.timeString,
          title: t.title,
          location: t.location,
          category: t.category,
          notes: t.notes,
          latitude: t.latitude,
          longitude: t.longitude,
        );

        generatedActivities.add(activity);
        await HiveStorageService.saveActivity(activity);
      }
    }

    return generatedActivities;
  }

  /// Matches destination string case-insensitively to supported templates
  static String? _resolveDestinationKey(String destination) {
    final lower = destination.toLowerCase().trim();
    for (final key in _destinationTemplates.keys) {
      if (lower.contains(key) || key.contains(lower)) {
        return key;
      }
    }
    return null;
  }

  /// Gets activities for a specific day index, falling back to sensible generic template
  static List<_ActivityTemplate> _getTemplatesForDay({
    required String? destinationKey,
    required String destinationName,
    required int dayIndex,
  }) {
    if (destinationKey != null && _destinationTemplates.containsKey(destinationKey)) {
      final daysList = _destinationTemplates[destinationKey]!;
      if (dayIndex < daysList.length) {
        return daysList[dayIndex];
      }
      // If trip is longer than template days, cycle through template days with sensible variation
      final cycled = daysList[dayIndex % daysList.length];
      return cycled.map((t) => _ActivityTemplate(
        timeString: t.timeString,
        title: '${t.title} (Part ${(dayIndex ~/ daysList.length) + 1})',
        location: t.location,
        category: t.category,
        notes: t.notes,
        latitude: t.latitude,
        longitude: t.longitude,
      )).toList();
    }

    // Generic fallback for any unrecognized destination
    return _buildGenericDayTemplates(destinationName, dayIndex + 1);
  }

  /// Sensible generic fallback itinerary for any custom destination
  static List<_ActivityTemplate> _buildGenericDayTemplates(String destination, int dayNumber) {
    switch (dayNumber) {
      case 1:
        return [
          _ActivityTemplate(
            timeString: '09:30',
            title: 'Explore $destination City Center',
            location: '$destination Downtown',
            category: 'Sightseeing',
            notes: 'Orientation walk around the primary landmark district and plazas',
            latitude: 20.01,
            longitude: 75.01,
          ),
          _ActivityTemplate(
            timeString: '13:00',
            title: '$destination Local Cuisine Tasting',
            location: 'Central $destination Dining Quarter',
            category: 'Food',
            notes: 'Sample local specialties and traditional dishes',
            latitude: 20.02,
            longitude: 75.02,
          ),
          _ActivityTemplate(
            timeString: '17:30',
            title: '$destination Sunset Viewpoint',
            location: '$destination Scenic Point',
            category: 'Nature',
            notes: 'Evening views and photography of the city skyline',
            latitude: 20.03,
            longitude: 75.03,
          ),
        ];
      case 2:
        return [
          _ActivityTemplate(
            timeString: '10:00',
            title: '$destination Heritage & Cultural Sites',
            location: 'Old Quarter, $destination',
            category: 'Culture',
            notes: 'Visit heritage monuments, museums, and historical architecture',
            latitude: 20.04,
            longitude: 75.04,
          ),
          _ActivityTemplate(
            timeString: '15:00',
            title: '$destination Artisan Market Shopping',
            location: '$destination Local Bazaar',
            category: 'Shopping',
            notes: 'Pick up regional souvenirs, arts, and crafts',
            latitude: 20.05,
            longitude: 75.05,
          ),
        ];
      default:
        return [
          _ActivityTemplate(
            timeString: '09:00',
            title: '$destination Outdoor Excursion Day $dayNumber',
            location: 'Outer $destination Sights',
            category: 'Nature',
            notes: 'Explore nearby nature trails, scenic parks, or coastal spots',
            latitude: 20.06 + (dayNumber * 0.01),
            longitude: 75.06 + (dayNumber * 0.01),
          ),
          _ActivityTemplate(
            timeString: '14:30',
            title: '$destination Leisure & Cafe Experience',
            location: 'Historic District, $destination',
            category: 'Food',
            notes: 'Relax at specialty cafes and observe local street life',
            latitude: 20.07 + (dayNumber * 0.01),
            longitude: 75.07 + (dayNumber * 0.01),
          ),
        ];
    }
  }
}
