import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../firebase_options.dart';

/// User representation encapsulating Firebase Auth user attributes.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  String toString() => 'AuthUser(uid: $uid, email: $email)';
}

/// Result object returned by authentication operations.
class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? idToken;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.user,
    this.idToken,
    this.errorMessage,
  });
}

typedef AuthHandler = Future<AuthResult> Function(String email, String password, bool isSignUp);

/// Service handling Firebase Authentication operations.
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  static const String apiKey = 'AIzaSyBLTA7qrJvP_WKW5FhuTHqwQ5IpWQm0XFQ';

  /// Optional mock handler for hermetic widget and unit tests
  AuthHandler? mockAuthHandler;

  String? _restIdToken;
  String? _restRefreshToken;
  DateTime? _restTokenExpiry;
  AuthUser? _restUser;

  bool _isFirebaseInitialized = false;

  /// Initializes Firebase Core if not already initialized.
  Future<void> initialize() async {
    if (_isFirebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
    } catch (e) {
      debugPrint('[FirebaseAuthService] Native Firebase init skipped or unavailable: $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Whether native [fb.FirebaseAuth] is available.
  bool get _hasNativeAuth {
    if (!_isFirebaseInitialized) return false;
    try {
      return fb.FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Current authenticated user, or null if unauthenticated.
  AuthUser? get currentUser {
    if (_hasNativeAuth) {
      final nativeUser = fb.FirebaseAuth.instance.currentUser;
      if (nativeUser != null) {
        return AuthUser(
          uid: nativeUser.uid,
          email: nativeUser.email,
          displayName: nativeUser.displayName,
        );
      }
    }
    return _restUser;
  }

  /// Returns true if a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Retrieves the current user's Firebase ID token for API authorization.
  /// Automatically refreshes the token if expired.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_hasNativeAuth) {
      try {
        final nativeUser = fb.FirebaseAuth.instance.currentUser;
        if (nativeUser != null) {
          return await nativeUser.getIdToken(forceRefresh);
        }
      } catch (e) {
        debugPrint('[FirebaseAuthService] Native getIdToken failed: $e');
      }
    }

    if (_restIdToken != null) {
      // Check if REST token needs refresh
      final now = DateTime.now();
      final isExpired = _restTokenExpiry != null && now.isAfter(_restTokenExpiry!);
      if ((isExpired || forceRefresh) && _restRefreshToken != null) {
        await _refreshRestToken();
      }
      return _restIdToken;
    }

    return null;
  }

  /// Signs up a new user with email and password via Firebase Auth.
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage: 'Email and password cannot be empty.',
      );
    }

    if (mockAuthHandler != null) {
      final res = await mockAuthHandler!(cleanEmail, password, true);
      if (res.success && res.user != null) {
        _restUser = res.user;
        _restIdToken = res.idToken ?? 'mock-id-token';
      }
      return res;
    }

    if (_hasNativeAuth) {
      try {
        final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          final token = await user.getIdToken();
          return AuthResult(
            success: true,
            user: AuthUser(uid: user.uid, email: user.email, displayName: user.displayName),
            idToken: token,
          );
        }
      } on fb.FirebaseAuthException catch (e) {
        return AuthResult(
          success: false,
          errorMessage: _formatAuthError(e.code, e.message),
        );
      } catch (e) {
        // Fall back to REST if native fails unexpectedly
        debugPrint('[FirebaseAuthService] Native signup failed, attempting REST: $e');
      }
    }

    // Firebase Auth REST API
    return _restSignUp(cleanEmail, password);
  }

  /// Signs in an existing user with email and password via Firebase Auth.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage: 'Email and password cannot be empty.',
      );
    }

    if (mockAuthHandler != null) {
      final res = await mockAuthHandler!(cleanEmail, password, false);
      if (res.success && res.user != null) {
        _restUser = res.user;
        _restIdToken = res.idToken ?? 'mock-id-token';
      }
      return res;
    }

    if (_hasNativeAuth) {
      try {
        final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          final token = await user.getIdToken();
          return AuthResult(
            success: true,
            user: AuthUser(uid: user.uid, email: user.email, displayName: user.displayName),
            idToken: token,
          );
        }
      } on fb.FirebaseAuthException catch (e) {
        return AuthResult(
          success: false,
          errorMessage: _formatAuthError(e.code, e.message),
        );
      } catch (e) {
        // Fall back to REST if native fails unexpectedly
        debugPrint('[FirebaseAuthService] Native signin failed, attempting REST: $e');
      }
    }

    // Firebase Auth REST API
    return _restSignIn(cleanEmail, password);
  }

  /// Signs out the currently authenticated user and clears session tokens.
  Future<void> signOut() async {
    if (_hasNativeAuth) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('[FirebaseAuthService] Native signOut error: $e');
      }
    }
    _restIdToken = null;
    _restRefreshToken = null;
    _restTokenExpiry = null;
    _restUser = null;
  }

  /// Sets an active session directly (useful for tests or mocking).
  void setSession({
    required String uid,
    required String email,
    required String idToken,
    String? refreshToken,
    DateTime? expiry,
  }) {
    _restUser = AuthUser(uid: uid, email: email);
    _restIdToken = idToken;
    _restRefreshToken = refreshToken;
    _restTokenExpiry = expiry ?? DateTime.now().add(const Duration(hours: 1));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REST API IMPLEMENTATION
  // ───────────────────────────────────────────────────────────────────────────

  Future<AuthResult> _restSignUp(String email, String password) async {
    try {
      final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final idToken = body['idToken'] as String;
        final refreshToken = body['refreshToken'] as String?;
        final localId = body['localId'] as String;
        final userEmail = body['email'] as String? ?? email;
        final expiresIn = int.tryParse(body['expiresIn']?.toString() ?? '3600') ?? 3600;

        _restIdToken = idToken;
        _restRefreshToken = refreshToken;
        _restTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        _restUser = AuthUser(uid: localId, email: userEmail);

        return AuthResult(
          success: true,
          user: _restUser,
          idToken: idToken,
        );
      } else {
        final errorMsg = body['error']?['message']?.toString() ?? 'Sign up failed.';
        return AuthResult(
          success: false,
          errorMessage: _formatAuthError(errorMsg, errorMsg),
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error connecting to Firebase Authentication: $e',
      );
    }
  }

  Future<AuthResult> _restSignIn(String email, String password) async {
    try {
      final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final idToken = body['idToken'] as String;
        final refreshToken = body['refreshToken'] as String?;
        final localId = body['localId'] as String;
        final userEmail = body['email'] as String? ?? email;
        final expiresIn = int.tryParse(body['expiresIn']?.toString() ?? '3600') ?? 3600;

        _restIdToken = idToken;
        _restRefreshToken = refreshToken;
        _restTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        _restUser = AuthUser(uid: localId, email: userEmail);

        return AuthResult(
          success: true,
          user: _restUser,
          idToken: idToken,
        );
      } else {
        final errorMsg = body['error']?['message']?.toString() ?? 'Sign in failed.';
        return AuthResult(
          success: false,
          errorMessage: _formatAuthError(errorMsg, errorMsg),
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error connecting to Firebase Authentication: $e',
      );
    }
  }

  Future<void> _refreshRestToken() async {
    if (_restRefreshToken == null) return;
    try {
      final uri = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$apiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$_restRefreshToken',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _restIdToken = body['id_token'] as String;
        _restRefreshToken = body['refresh_token'] as String? ?? _restRefreshToken;
        final expiresIn = int.tryParse(body['expires_in']?.toString() ?? '3600') ?? 3600;
        _restTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      }
    } catch (e) {
      debugPrint('[FirebaseAuthService] Token refresh failed: $e');
    }
  }

  String _formatAuthError(String code, String? message) {
    switch (code) {
      case 'EMAIL_EXISTS':
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'INVALID_PASSWORD':
      case 'EMAIL_NOT_FOUND':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password. Please verify your credentials.';
      case 'WEAK_PASSWORD':
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'INVALID_EMAIL':
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'USER_DISABLED':
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}
