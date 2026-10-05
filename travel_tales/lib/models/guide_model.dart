class GuideModel {
  final String id;
  final String name;
  final String tourTitle;
  final String location;
  final String category; // "Food", "Culture", "Adventure", "Nature"
  final double rating;
  final int reviewsCount;
  final double pricePerPerson;
  final String description;
  final String? imageUrl;
  final List<String> languages;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;

  GuideModel({
    required this.id,
    required this.name,
    required this.tourTitle,
    required this.location,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerPerson,
    required this.description,
    this.imageUrl,
    this.languages = const ['English'],
    this.isFavorite = false,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tourTitle': tourTitle,
      'location': location,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerPerson': pricePerPerson,
      'description': description,
      'imageUrl': imageUrl,
      'languages': languages,
      'isFavorite': isFavorite,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory GuideModel.fromMap(Map<dynamic, dynamic> map) {
    return GuideModel(
      id: map['id'] as String,
      name: map['name'] as String,
      tourTitle: map['tourTitle'] as String,
      location: map['location'] as String,
      category: map['category'] as String,
      rating: (map['rating'] as num).toDouble(),
      reviewsCount: (map['reviewsCount'] as num).toInt(),
      pricePerPerson: (map['pricePerPerson'] as num).toDouble(),
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String?,
      languages: (map['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['English'],
      isFavorite: map['isFavorite'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  GuideModel copyWith({
    String? id,
    String? name,
    String? tourTitle,
    String? location,
    String? category,
    double? rating,
    int? reviewsCount,
    double? pricePerPerson,
    String? description,
    String? imageUrl,
    List<String>? languages,
    bool? isFavorite,
    double? latitude,
    double? longitude,
  }) {
    return GuideModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tourTitle: tourTitle ?? this.tourTitle,
      location: location ?? this.location,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      languages: languages ?? this.languages,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
