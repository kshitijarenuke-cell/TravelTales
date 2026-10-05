import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip_model.dart';
import '../models/activity_model.dart';
import '../models/expense_model.dart';
import '../models/guide_model.dart';

class HiveStorageService {
  static const String tripsBoxName = 'traveltales_trips';
  static const String activitiesBoxName = 'traveltales_activities';
  static const String expensesBoxName = 'traveltales_expenses';
  static const String guidesBoxName = 'traveltales_guides';
  static const String settingsBoxName = 'traveltales_settings';
  static const String offlineMapsBoxName = 'traveltales_offline_maps';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(tripsBoxName);
    await Hive.openBox(activitiesBoxName);
    await Hive.openBox(expensesBoxName);
    await Hive.openBox(guidesBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(offlineMapsBoxName);
  }

  // --- TRIPS ---
  static Box? get _tripsBox => Hive.isBoxOpen(tripsBoxName) ? Hive.box(tripsBoxName) : null;

  static List<TripModel> getTrips() {
    final box = _tripsBox;
    if (box == null) return [];
    final list = <TripModel>[];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        list.add(TripModel.fromMap(item));
      }
    }
    return list;
  }

  static Future<void> saveTrip(TripModel trip) async {
    final box = _tripsBox;
    if (box != null) {
      await box.put(trip.id, trip.toMap());
    }
  }

  static Future<void> deleteTrip(String tripId) async {
    final box = _tripsBox;
    if (box != null) {
      await box.delete(tripId);
    }
  }

  // --- ACTIVITIES ---
  static Box? get _activitiesBox => Hive.isBoxOpen(activitiesBoxName) ? Hive.box(activitiesBoxName) : null;

  static List<ActivityModel> getActivities(String tripId) {
    final box = _activitiesBox;
    if (box == null) return [];
    final list = <ActivityModel>[];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        final activity = ActivityModel.fromMap(item);
        if (activity.tripId == tripId) {
          list.add(activity);
        }
      }
    }
    // Sort by dayNumber, then by timeString
    list.sort((a, b) {
      final dayCmp = a.dayNumber.compareTo(b.dayNumber);
      if (dayCmp != 0) return dayCmp;
      return a.timeString.compareTo(b.timeString);
    });
    return list;
  }

  static Future<void> saveActivity(ActivityModel activity) async {
    final box = _activitiesBox;
    if (box != null) {
      await box.put(activity.id, activity.toMap());
    }
  }

  static Future<void> deleteActivity(String activityId) async {
    final box = _activitiesBox;
    if (box != null) {
      await box.delete(activityId);
    }
  }

  // --- EXPENSES ---
  static Box? get _expensesBox => Hive.isBoxOpen(expensesBoxName) ? Hive.box(expensesBoxName) : null;

  static List<ExpenseModel> getExpenses(String tripId) {
    final box = _expensesBox;
    if (box == null) return [];
    final list = <ExpenseModel>[];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        final expense = ExpenseModel.fromMap(item);
        if (expense.tripId == tripId) {
          list.add(expense);
        }
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> saveExpense(ExpenseModel expense) async {
    final box = _expensesBox;
    if (box != null) {
      await box.put(expense.id, expense.toMap());
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    final box = _expensesBox;
    if (box != null) {
      await box.delete(expenseId);
    }
  }

  // --- GUIDES ---
  static Box? get _guidesBox => Hive.isBoxOpen(guidesBoxName) ? Hive.box(guidesBoxName) : null;

  static List<GuideModel> getGuides() {
    final box = _guidesBox;
    if (box == null) return [];
    final list = <GuideModel>[];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        list.add(GuideModel.fromMap(item));
      }
    }
    return list;
  }

  static Future<void> saveGuide(GuideModel guide) async {
    final box = _guidesBox;
    if (box != null) {
      await box.put(guide.id, guide.toMap());
    }
  }

  static Future<void> saveGuides(List<GuideModel> guides) async {
    final box = _guidesBox;
    if (box != null) {
      for (final guide in guides) {
        await box.put(guide.id, guide.toMap());
      }
    }
  }

  // --- SETTINGS & PREFERENCES ---
  static Box? get _settingsBox => Hive.isBoxOpen(settingsBoxName) ? Hive.box(settingsBoxName) : null;

  static bool getOfflineStorageEnabled() {
    final box = _settingsBox;
    if (box == null) return true;
    return box.get('offline_storage_enabled', defaultValue: true) as bool;
  }

  static Future<void> setOfflineStorageEnabled(bool value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('offline_storage_enabled', value);
    }
  }

  static bool getNotificationsEnabled() {
    final box = _settingsBox;
    if (box == null) return true;
    return box.get('notifications_enabled', defaultValue: true) as bool;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('notifications_enabled', value);
    }
  }

  static bool getTripRemindersEnabled() {
    final box = _settingsBox;
    if (box == null) return true;
    return box.get('trip_reminders_enabled', defaultValue: true) as bool;
  }

  static Future<void> setTripRemindersEnabled(bool value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('trip_reminders_enabled', value);
    }
  }

  static String getUserName() {
    final box = _settingsBox;
    if (box == null) return 'Kshitija Renuke';
    return box.get('user_name', defaultValue: 'Kshitija Renuke') as String;
  }

  static Future<void> setUserName(String value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('user_name', value);
    }
  }

  static String getUserEmail() {
    final box = _settingsBox;
    if (box == null) return 'kshitijarenuke@gmail.com';
    return box.get('user_email', defaultValue: 'kshitijarenuke@gmail.com') as String;
  }

  static Future<void> setUserEmail(String value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('user_email', value);
    }
  }

  static String getCurrency() {
    final box = _settingsBox;
    if (box == null) return 'INR (₹)';
    return box.get('app_currency', defaultValue: 'INR (₹)') as String;
  }

  static Future<void> setCurrency(String value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('app_currency', value);
    }
  }

  // --- AUTH SESSION ---
  static bool isLoggedIn() {
    final box = _settingsBox;
    if (box == null) return false;
    return box.get('is_logged_in', defaultValue: false) as bool;
  }

  static Future<void> setLoggedIn(bool value) async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('is_logged_in', value);
    }
  }

  static String? getSessionUserEmail() {
    final box = _settingsBox;
    if (box == null) return null;
    return box.get('session_user_email') as String?;
  }

  static Future<void> setSessionUserEmail(String? email) async {
    final box = _settingsBox;
    if (box != null) {
      if (email != null) {
        await box.put('session_user_email', email);
      } else {
        await box.delete('session_user_email');
      }
    }
  }

  static String? getSessionUserId() {
    final box = _settingsBox;
    if (box == null) return null;
    return box.get('session_user_id') as String?;
  }

  static Future<void> setSessionUserId(String? userId) async {
    final box = _settingsBox;
    if (box != null) {
      if (userId != null) {
        await box.put('session_user_id', userId);
      } else {
        await box.delete('session_user_id');
      }
    }
  }

  static Future<void> clearAuthSession() async {
    final box = _settingsBox;
    if (box != null) {
      await box.put('is_logged_in', false);
      await box.delete('session_user_email');
      await box.delete('session_user_id');
    }
  }

  /// Clears cached user trips, activities, and expenses on logout to prevent
  /// cross-user data leakage on shared devices.
  static Future<void> clearUserScopedData() async {
    if (_tripsBox != null) await _tripsBox!.clear();
    if (_activitiesBox != null) await _activitiesBox!.clear();
    if (_expensesBox != null) await _expensesBox!.clear();
  }
}
