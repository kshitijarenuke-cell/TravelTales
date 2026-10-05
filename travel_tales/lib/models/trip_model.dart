class TripModel {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final double budget;
  final bool isOfflineReady;

  TripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.coverImageUrl,
    this.budget = 40000.0,
    this.isOfflineReady = false,
  });

  int get durationInDays {
    final diff = endDate.difference(startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'budget': budget,
      'isOfflineReady': isOfflineReady,
    };
  }

  factory TripModel.fromMap(Map<dynamic, dynamic> map) {
    return TripModel(
      id: map['id'] as String,
      title: map['title'] as String,
      destination: map['destination'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      coverImageUrl: map['coverImageUrl'] as String?,
      budget: (map['budget'] as num?)?.toDouble() ?? 40000.0,
      isOfflineReady: map['isOfflineReady'] as bool? ?? false,
    );
  }

  TripModel copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? budget,
    bool? isOfflineReady,
  }) {
    return TripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      budget: budget ?? this.budget,
      isOfflineReady: isOfflineReady ?? this.isOfflineReady,
    );
  }
}
