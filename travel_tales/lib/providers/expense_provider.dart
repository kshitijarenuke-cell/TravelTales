import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/hive_storage_service.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService;

  ExpenseProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  List<ExpenseModel> _expenses = [];
  String _selectedCategory = 'All';
  String _sortBy = 'Default';
  String? _currentTripId;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  List<ExpenseModel> get expenses => _expenses;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  String? get currentTripId => _currentTripId;

  List<ExpenseModel> get filteredExpenses {
    List<ExpenseModel> list = _selectedCategory == 'All'
        ? List.from(_expenses)
        : _expenses.where((e) =>
            e.category.toLowerCase() == _selectedCategory.toLowerCase()
          ).toList();

    if (_sortBy == 'Highest Amount') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'Lowest Amount') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (_sortBy == 'Newest Date') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortBy == 'Oldest Date') {
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    return list;
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = 'All';
    _sortBy = 'Default';
    notifyListeners();
  }

  double get totalSpent {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalSpentForTrip(String tripId) {
    if (_currentTripId == tripId) {
      return totalSpent;
    }
    final tripExpenses = HiveStorageService.getExpenses(tripId);
    return tripExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Loads expenses from Hive immediately, then syncs with backend in background.
  void loadExpensesForTrip(String tripId, {bool syncRemote = true}) {
    if (_currentTripId == tripId && _expenses.isNotEmpty) {
      return;
    }
    _currentTripId = tripId;
    _expenses = HiveStorageService.getExpenses(tripId);
    notifyListeners();

    if (syncRemote) {
      syncExpensesFromApi(tripId);
    }
  }

  /// Forces reloading of expenses from Hive and syncs with backend.
  void forceReloadTrip(String tripId, {bool syncRemote = true}) {
    _currentTripId = tripId;
    _expenses = HiveStorageService.getExpenses(tripId);
    notifyListeners();

    if (syncRemote) {
      syncExpensesFromApi(tripId);
    }
  }

  /// Synchronizes expenses for a trip from backend into Hive cache.
  Future<void> syncExpensesFromApi(String tripId) async {
    _isSyncing = true;
    try {
      final remoteExpenses = await _apiService.getExpenses(tripId);
      if (remoteExpenses.isNotEmpty) {
        for (final exp in remoteExpenses) {
          await HiveStorageService.saveExpense(exp);
        }
        if (_currentTripId == tripId) {
          _expenses = HiveStorageService.getExpenses(tripId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ExpenseProvider] Remote expenses sync unavailable: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Adds a new expense to Hive immediately and syncs with backend.
  Future<void> addExpense(ExpenseModel expense) async {
    await HiveStorageService.saveExpense(expense);
    _currentTripId = expense.tripId;
    _expenses = HiveStorageService.getExpenses(expense.tripId);
    notifyListeners();

    try {
      final created = await _apiService.createExpense(expense.tripId, expense);
      await HiveStorageService.saveExpense(created);
      if (_currentTripId == expense.tripId) {
        _expenses = HiveStorageService.getExpenses(expense.tripId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ExpenseProvider] Backend addExpense failed, saved in Hive: $e');
    }
  }

  /// Updates an expense in Hive immediately and syncs with backend.
  Future<void> updateExpense(ExpenseModel expense) async {
    await HiveStorageService.saveExpense(expense);
    if (_currentTripId == expense.tripId) {
      _expenses = HiveStorageService.getExpenses(expense.tripId);
      notifyListeners();
    }

    try {
      final updated = await _apiService.updateExpense(expense);
      await HiveStorageService.saveExpense(updated);
      if (_currentTripId == expense.tripId) {
        _expenses = HiveStorageService.getExpenses(expense.tripId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ExpenseProvider] Backend updateExpense failed, saved in Hive: $e');
    }
  }

  /// Deletes an expense from Hive and syncs deletion to backend.
  Future<void> deleteExpense(String expenseId) async {
    await HiveStorageService.deleteExpense(expenseId);
    if (_currentTripId != null) {
      _expenses = HiveStorageService.getExpenses(_currentTripId!);
      notifyListeners();
    }

    try {
      await _apiService.deleteExpense(expenseId);
    } catch (e) {
      debugPrint('[ExpenseProvider] Backend deleteExpense failed, deleted in Hive: $e');
    }
  }

  /// Clears in-memory expense state on logout.
  void clear() {
    _expenses = [];
    _selectedCategory = 'All';
    _sortBy = 'Default';
    _currentTripId = null;
    _isSyncing = false;
    notifyListeners();
  }
}
