import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/activity_model.dart';
import '../services/hive_storage_service.dart';
import '../services/api_service.dart';

class TripProvider with ChangeNotifier {
  final ApiService _apiService;

  TripProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  List<TripModel> _trips = [];
  TripModel? _selectedTrip;
  List<ActivityModel> _activities = [];
  String _searchQuery = '';
  int _selectedDayNumber = 1;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  List<TripModel> get trips {
    if (_searchQuery.trim().isEmpty) {
      return _trips;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _trips.where((t) =>
      t.title.toLowerCase().contains(query) ||
      t.destination.toLowerCase().contains(query)
    ).toList();
  }

  TripModel? get selectedTrip => _selectedTrip;
  List<ActivityModel> get activities => _activities;
  String get searchQuery => _searchQuery;
  int get selectedDayNumber => _selectedDayNumber;

  List<ActivityModel> get selectedDayActivities {
    return _activities.where((a) => a.dayNumber == _selectedDayNumber).toList();
  }

  /// Loads trips immediately from local Hive cache, and initiates background remote sync.
  void loadTrips({bool syncRemote = true}) {
    _trips = HiveStorageService.getTrips();
    if (_trips.isNotEmpty && _selectedTrip == null) {
      _selectedTrip = _trips.first;
    }
    if (_selectedTrip != null) {
      loadActivitiesForTrip(_selectedTrip!.id, syncRemote: false);
    }
    notifyListeners();

    if (syncRemote) {
      syncTripsFromApi();
    }
  }

  /// Synchronizes trips from the Node.js backend & Firestore into local Hive cache.
  Future<void> syncTripsFromApi() async {
    _isSyncing = true;
    try {
      final remoteTrips = await _apiService.getTrips();
      if (remoteTrips.isNotEmpty) {
        for (final trip in remoteTrips) {
          await HiveStorageService.saveTrip(trip);
        }
        _trips = HiveStorageService.getTrips();
        if (_selectedTrip != null) {
          final matched = _trips.where((t) => t.id == _selectedTrip!.id);
          if (matched.isNotEmpty) {
            _selectedTrip = matched.first;
          }
        } else if (_trips.isNotEmpty) {
          _selectedTrip = _trips.first;
        }
        notifyListeners();
      }
    } catch (e) {
      // Graceful offline fallback: keep cached Hive data intact
      debugPrint('[TripProvider] Remote trips sync unavailable: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectTrip(TripModel trip) {
    _selectedTrip = trip;
    _selectedDayNumber = 1;
    loadActivitiesForTrip(trip.id);
    notifyListeners();
  }

  void selectDay(int dayNumber) {
    _selectedDayNumber = dayNumber;
    notifyListeners();
  }

  /// Loads activities for a trip from Hive immediately, then syncs with backend.
  void loadActivitiesForTrip(String tripId, {bool syncRemote = true}) {
    _activities = HiveStorageService.getActivities(tripId);
    notifyListeners();

    if (syncRemote) {
      syncActivitiesFromApi(tripId);
    }
  }

  /// Synchronizes activities for a trip from backend into Hive cache.
  Future<void> syncActivitiesFromApi(String tripId) async {
    try {
      final remoteActivities = await _apiService.getActivities(tripId);
      if (remoteActivities.isNotEmpty) {
        for (final act in remoteActivities) {
          await HiveStorageService.saveActivity(act);
        }
        if (_selectedTrip?.id == tripId) {
          _activities = HiveStorageService.getActivities(tripId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[TripProvider] Activities remote sync unavailable: $e');
    }
  }

  /// Adds a new trip to Hive immediately and syncs with Node backend / Firestore.
  Future<void> addTrip(TripModel trip) async {
    await HiveStorageService.saveTrip(trip);
    _trips = HiveStorageService.getTrips();
    _selectedTrip = trip;
    loadActivitiesForTrip(trip.id, syncRemote: false);
    notifyListeners();

    try {
      final created = await _apiService.createTrip(trip);
      await HiveStorageService.saveTrip(created);
      _trips = HiveStorageService.getTrips();
      if (_selectedTrip?.id == created.id) {
        _selectedTrip = created;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[TripProvider] Backend addTrip failed, saved in Hive: $e');
    }
  }

  /// Updates an existing trip in Hive and syncs with backend.
  Future<void> updateTrip(TripModel trip) async {
    await HiveStorageService.saveTrip(trip);
    _trips = HiveStorageService.getTrips();
    if (_selectedTrip?.id == trip.id) {
      _selectedTrip = trip;
    }
    notifyListeners();

    try {
      final updated = await _apiService.updateTrip(trip);
      await HiveStorageService.saveTrip(updated);
      _trips = HiveStorageService.getTrips();
      if (_selectedTrip?.id == updated.id) {
        _selectedTrip = updated;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[TripProvider] Backend updateTrip failed, saved in Hive: $e');
    }
  }

  /// Deletes a trip from Hive and syncs deletion to backend.
  Future<void> deleteTrip(String tripId) async {
    await HiveStorageService.deleteTrip(tripId);
    _trips = HiveStorageService.getTrips();
    if (_selectedTrip?.id == tripId) {
      _selectedTrip = _trips.isNotEmpty ? _trips.first : null;
    }
    notifyListeners();

    try {
      await _apiService.deleteTrip(tripId);
    } catch (e) {
      debugPrint('[TripProvider] Backend deleteTrip failed, deleted in Hive: $e');
    }
  }

  /// Adds an activity to Hive and syncs to backend.
  Future<void> addActivity(ActivityModel activity) async {
    await HiveStorageService.saveActivity(activity);
    if (_selectedTrip != null) {
      _activities = HiveStorageService.getActivities(_selectedTrip!.id);
    }
    notifyListeners();

    try {
      final created = await _apiService.createActivity(activity.tripId, activity);
      await HiveStorageService.saveActivity(created);
      if (_selectedTrip != null && _selectedTrip!.id == created.tripId) {
        _activities = HiveStorageService.getActivities(_selectedTrip!.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[TripProvider] Backend addActivity failed, saved in Hive: $e');
    }
  }

  /// Updates an activity in Hive and syncs to backend.
  Future<void> updateActivity(ActivityModel activity) async {
    await HiveStorageService.saveActivity(activity);
    if (_selectedTrip != null) {
      _activities = HiveStorageService.getActivities(_selectedTrip!.id);
    }
    notifyListeners();

    try {
      final updated = await _apiService.updateActivity(activity);
      await HiveStorageService.saveActivity(updated);
      if (_selectedTrip != null && _selectedTrip!.id == updated.tripId) {
        _activities = HiveStorageService.getActivities(_selectedTrip!.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[TripProvider] Backend updateActivity failed, saved in Hive: $e');
    }
  }

  /// Deletes an activity from Hive and syncs deletion to backend.
  Future<void> deleteActivity(String activityId) async {
    await HiveStorageService.deleteActivity(activityId);
    if (_selectedTrip != null) {
      _activities = HiveStorageService.getActivities(_selectedTrip!.id);
    }
    notifyListeners();

    try {
      await _apiService.deleteActivity(activityId);
    } catch (e) {
      debugPrint('[TripProvider] Backend deleteActivity failed, deleted in Hive: $e');
    }
  }

  /// Toggles offline ready status in Hive and syncs with backend.
  Future<void> toggleOfflineStatus(String tripId, bool isOffline) async {
    if (_selectedTrip != null && _selectedTrip!.id == tripId) {
      _selectedTrip = _selectedTrip!.copyWith(isOfflineReady: isOffline);
      await HiveStorageService.saveTrip(_selectedTrip!);
      _trips = HiveStorageService.getTrips();
      notifyListeners();

      try {
        await _apiService.updateTrip(_selectedTrip!);
      } catch (e) {
        debugPrint('[TripProvider] Backend toggleOfflineStatus failed: $e');
      }
    }
  }

  /// Clears in-memory trip and activity state on logout.
  void clear() {
    _trips = [];
    _selectedTrip = null;
    _activities = [];
    _searchQuery = '';
    _selectedDayNumber = 1;
    _isSyncing = false;
    notifyListeners();
  }
}
