import 'package:flutter/foundation.dart';
import '../services/hive_storage_service.dart';
import '../services/firebase_auth_service.dart';

/// Provider for managing Firebase Authentication and session state.
///
/// Features:
/// - Real Firebase Email/Password Authentication (signup, login, logout).
/// - Session restoration across app restarts.
/// - Clear separation and isolation of user data upon logout.
/// - Never stores raw passwords in local storage or logs.
class AuthProvider with ChangeNotifier {
  /// Predefined demo credentials for case-study evaluation
  static const String demoEmail = 'kshitijarenuke@gmail.com';
  static const String demoPassword = 'TravelTales@123';

  bool _isAuthenticated = false;
  String? _currentUserEmail;
  String? _currentUserId;
  String? _errorMessage;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Restores session state from Firebase Auth or local Hive storage on app startup
  void init() {
    // 1. Check if Firebase Auth has an active user
    final fbUser = FirebaseAuthService.instance.currentUser;
    if (fbUser != null) {
      _isAuthenticated = true;
      _currentUserEmail = fbUser.email;
      _currentUserId = fbUser.uid;
      notifyListeners();
      return;
    }

    // 2. Fall back to local Hive session state
    _isAuthenticated = HiveStorageService.isLoggedIn();
    if (_isAuthenticated) {
      _currentUserEmail = HiveStorageService.getSessionUserEmail() ?? demoEmail;
      _currentUserId = HiveStorageService.getSessionUserId();
    }
    notifyListeners();
  }

  /// Authenticates with email and password via Firebase Authentication.
  ///
  /// Returns `true` if login succeeds, `false` otherwise.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FirebaseAuthService.instance.signInWithEmail(email, password);

      if (result.success && result.user != null) {
        _isAuthenticated = true;
        _currentUserEmail = result.user!.email ?? email.trim();
        _currentUserId = result.user!.uid;
        _errorMessage = null;
        _isLoading = false;

        // Persist session state locally in Hive
        await HiveStorageService.setLoggedIn(true);
        await HiveStorageService.setSessionUserEmail(_currentUserEmail);
        await HiveStorageService.setSessionUserId(_currentUserId);

        notifyListeners();
        return true;
      } else {
        _isAuthenticated = false;
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Invalid email or password. Please check your credentials.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _isLoading = false;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user with email and password via Firebase Authentication.
  ///
  /// Returns `true` if signup succeeds, `false` otherwise.
  Future<bool> signup(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FirebaseAuthService.instance.signUpWithEmail(email, password);

      if (result.success && result.user != null) {
        _isAuthenticated = true;
        _currentUserEmail = result.user!.email ?? email.trim();
        _currentUserId = result.user!.uid;
        _errorMessage = null;
        _isLoading = false;

        // Persist session state locally in Hive
        await HiveStorageService.setLoggedIn(true);
        await HiveStorageService.setSessionUserEmail(_currentUserEmail);
        await HiveStorageService.setSessionUserId(_currentUserId);

        notifyListeners();
        return true;
      } else {
        _isAuthenticated = false;
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Registration failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _isLoading = false;
      _errorMessage = 'Signup failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Logs the user out: terminates Firebase session, clears session tokens,
  /// and wipes cached user-scoped trips/activities/expenses in Hive.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuthService.instance.signOut();
    } catch (e) {
      debugPrint('[AuthProvider] Error signing out of Firebase: $e');
    }

    _isAuthenticated = false;
    _currentUserEmail = null;
    _currentUserId = null;
    _errorMessage = null;
    _isLoading = false;

    // Clear session and user-specific data from Hive to ensure isolation
    await HiveStorageService.clearAuthSession();
    await HiveStorageService.clearUserScopedData();

    notifyListeners();
  }

  /// Sets an authenticated session directly (used in tests or mock environments).
  Future<void> setMockSession({
    required String uid,
    required String email,
    required String idToken,
  }) async {
    FirebaseAuthService.instance.setSession(
      uid: uid,
      email: email,
      idToken: idToken,
    );
    _isAuthenticated = true;
    _currentUserEmail = email;
    _currentUserId = uid;
    _errorMessage = null;
    _isLoading = false;

    await HiveStorageService.setLoggedIn(true);
    await HiveStorageService.setSessionUserEmail(email);
    await HiveStorageService.setSessionUserId(uid);

    notifyListeners();
  }

  /// Clears any existing error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
