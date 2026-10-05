import 'package:flutter/foundation.dart';
import '../models/guide_model.dart';
import '../services/hive_storage_service.dart';
import '../services/api_service.dart';

class GuideProvider with ChangeNotifier {
  final ApiService _apiService;

  GuideProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  List<GuideModel> _guides = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double _filterMinPrice = 0;
  double _filterMaxPrice = 5000;
  int _filterMinRating = 0; // 0 = Any rating
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  List<GuideModel> get guides => _guides;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double get filterMinPrice => _filterMinPrice;
  double get filterMaxPrice => _filterMaxPrice;
  int get filterMinRating => _filterMinRating;

  List<GuideModel> get filteredGuides {
    return _guides.where((guide) {
      final matchesCategory = _selectedCategory == 'All' ||
          guide.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          guide.tourTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guide.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guide.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMinPrice = guide.pricePerPerson >= _filterMinPrice;
      final matchesMaxPrice =
          _filterMaxPrice >= 5000 || guide.pricePerPerson <= _filterMaxPrice;
      final matchesRating =
          _filterMinRating == 0 || guide.rating >= _filterMinRating;
      return matchesCategory &&
          matchesQuery &&
          matchesMinPrice &&
          matchesMaxPrice &&
          matchesRating;
    }).toList();
  }

  /// Loads guides immediately from local Hive cache, and initiates background remote sync.
  void loadGuides({bool syncRemote = true}) {
    _guides = HiveStorageService.getGuides();
    notifyListeners();

    if (syncRemote) {
      syncGuidesFromApi();
    }
  }

  /// Synchronizes guides from the Node.js backend & Firestore into local Hive cache.
  Future<void> syncGuidesFromApi() async {
    _isSyncing = true;
    try {
      final remoteGuides = await _apiService.getGuides();
      if (remoteGuides.isNotEmpty) {
        // Preserve any local user favorites
        final existingFavorites = <String, bool>{
          for (final g in _guides) g.id: g.isFavorite,
        };

        final mergedGuides = remoteGuides.map((g) {
          if (existingFavorites.containsKey(g.id)) {
            return g.copyWith(isFavorite: existingFavorites[g.id]!);
          }
          return g;
        }).toList();

        await HiveStorageService.saveGuides(mergedGuides);
        _guides = HiveStorageService.getGuides();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[GuideProvider] Remote guides sync unavailable: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setFilterMinPrice(double value) {
    _filterMinPrice = value;
    notifyListeners();
  }

  void setFilterMaxPrice(double value) {
    _filterMaxPrice = value;
    notifyListeners();
  }

  void setFilterMinRating(int rating) {
    _filterMinRating = rating;
    notifyListeners();
  }

  /// Reset all filters to defaults.
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _filterMinPrice = 0;
    _filterMaxPrice = 5000;
    _filterMinRating = 0;
    notifyListeners();
  }

  Future<void> toggleFavorite(String guideId) async {
    final index = _guides.indexWhere((g) => g.id == guideId);
    if (index != -1) {
      final updatedGuide = _guides[index].copyWith(
        isFavorite: !_guides[index].isFavorite,
      );
      _guides[index] = updatedGuide;
      await HiveStorageService.saveGuide(updatedGuide);
      notifyListeners();
    }
  }
}
