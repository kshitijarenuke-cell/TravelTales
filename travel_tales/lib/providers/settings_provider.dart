import 'package:flutter/foundation.dart';
import '../services/hive_storage_service.dart';

/// Provider for managing app user profile, settings, and preferences.
/// All changes are persisted directly to Hive.
class SettingsProvider with ChangeNotifier {
  String _userName = 'Kshitija Renuke';
  String _userEmail = 'kshitijarenuke@gmail.com';
  bool _notificationsEnabled = true;
  bool _tripRemindersEnabled = true;
  bool _offlineStorageEnabled = true;
  String _currency = 'INR (₹)';

  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get tripRemindersEnabled => _tripRemindersEnabled;
  bool get offlineStorageEnabled => _offlineStorageEnabled;
  String get currency => _currency;

  void loadSettings() {
    _userName = HiveStorageService.getUserName();
    _userEmail = HiveStorageService.getUserEmail();
    _notificationsEnabled = HiveStorageService.getNotificationsEnabled();
    _tripRemindersEnabled = HiveStorageService.getTripRemindersEnabled();
    _offlineStorageEnabled = HiveStorageService.getOfflineStorageEnabled();
    _currency = HiveStorageService.getCurrency();
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (name != null) {
      _userName = name;
      await HiveStorageService.setUserName(name);
    }
    if (email != null) {
      _userEmail = email;
      await HiveStorageService.setUserEmail(email);
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await HiveStorageService.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setTripRemindersEnabled(bool value) async {
    _tripRemindersEnabled = value;
    await HiveStorageService.setTripRemindersEnabled(value);
    notifyListeners();
  }

  Future<void> setOfflineStorageEnabled(bool value) async {
    _offlineStorageEnabled = value;
    await HiveStorageService.setOfflineStorageEnabled(value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await HiveStorageService.setCurrency(value);
    notifyListeners();
  }
}
