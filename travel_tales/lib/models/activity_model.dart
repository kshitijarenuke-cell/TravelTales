class ActivityModel {
  final String id;
  final String tripId;
  final int dayNumber;
  final DateTime date;
  final String timeString; // e.g. "08:00", "10:00"
  final String title;
  final String location;
  final String category; // e.g. "Breakfast", "Temple", "Lunch", "Beach Club", "Dinner"
  final String? notes;
  final double? latitude;
  final double? longitude;

  ActivityModel({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.date,
    required this.timeString,
    required this.title,
    required this.location,
    required this.category,
    this.notes,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'dayNumber': dayNumber,
      'date': date.toIso8601String(),
      'timeString': timeString,
      'title': title,
      'location': location,
      'category': category,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ActivityModel.fromMap(Map<dynamic, dynamic> map) {
    return ActivityModel(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      dayNumber: (map['dayNumber'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      timeString: map['timeString'] as String,
      title: map['title'] as String,
      location: map['location'] as String,
      category: map['category'] as String,
      notes: map['notes'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  ActivityModel copyWith({
    String? id,
    String? tripId,
    int? dayNumber,
    DateTime? date,
    String? timeString,
    String? title,
    String? location,
    String? category,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      timeString: timeString ?? this.timeString,
      title: title ?? this.title,
      location: location ?? this.location,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
