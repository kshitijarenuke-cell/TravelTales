import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trip_model.dart';
import '../models/activity_model.dart';
import '../models/expense_model.dart';
import '../models/guide_model.dart';
import 'firebase_auth_service.dart';

/// Exception thrown by [ApiService] when an HTTP or network error occurs.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode = 0,
    this.details,
  });

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}

typedef TokenProvider = Future<String?> Function();

/// Service handling all REST API interactions between Flutter and the TravelTales Node.js backend.
class ApiService {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  TokenProvider? tokenProvider;

  ApiService({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.tokenProvider,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// Default singleton instance
  static ApiService instance = ApiService(
    tokenProvider: () => FirebaseAuthService.instance.getIdToken(),
  );

  /// Determines the backend API base URL from compile-time environment or development default.
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host machine localhost to 10.0.2.2
      return 'http://10.0.2.2:3000/api';
    }
    // Web, iOS Simulator, macOS, Windows, Linux
    return 'http://127.0.0.1:3000/api';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEALTH CHECK
  // ───────────────────────────────────────────────────────────────────────────

  /// Checks server and Firebase/Firestore connection health.
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _get('/health');
    return response as Map<String, dynamic>;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TRIPS CRUD
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches all trips from the backend Firestore collection.
  Future<List<TripModel>> getTrips() async {
    final body = await _get('/trips');
    final data = body['data'];
    if (data is List) {
      return data
          .map((item) => TripModel.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches a single trip by ID.
  Future<TripModel?> getTripById(String id) async {
    try {
      final body = await _get('/trips/$id');
      final data = body['data'];
      if (data is Map) {
        return TripModel.fromMap(data);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Creates a new trip in the backend.
  Future<TripModel> createTrip(TripModel trip) async {
    final payload = trip.toMap();
    final body = await _post('/trips', payload);
    return TripModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Updates an existing trip in the backend.
  Future<TripModel> updateTrip(TripModel trip) async {
    final payload = {
      'title': trip.title,
      'destination': trip.destination,
      'startDate': trip.startDate.toIso8601String(),
      'endDate': trip.endDate.toIso8601String(),
      'budget': trip.budget,
      'isOfflineReady': trip.isOfflineReady,
      if (trip.coverImageUrl != null) 'coverImageUrl': trip.coverImageUrl,
    };
    final body = await _put('/trips/${trip.id}', payload);
    return TripModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Deletes a trip (and cascades child activities/expenses) in the backend.
  Future<bool> deleteTrip(String tripId) async {
    await _delete('/trips/$tripId');
    return true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTIVITIES CRUD
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches all activities for a specific trip.
  Future<List<ActivityModel>> getActivities(String tripId) async {
    final body = await _get('/trips/$tripId/activities');
    final data = body['data'];
    if (data is List) {
      return data
          .map((item) => ActivityModel.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a new activity under a specific trip.
  Future<ActivityModel> createActivity(String tripId, ActivityModel activity) async {
    final payload = activity.toMap();
    final body = await _post('/trips/$tripId/activities', payload);
    return ActivityModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Updates an existing activity by ID.
  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    final payload = {
      'dayNumber': activity.dayNumber,
      'date': activity.date.toIso8601String(),
      'timeString': activity.timeString,
      'title': activity.title,
      'location': activity.location,
      'category': activity.category,
      if (activity.notes != null) 'notes': activity.notes,
      if (activity.latitude != null) 'latitude': activity.latitude,
      if (activity.longitude != null) 'longitude': activity.longitude,
    };
    final body = await _put('/activities/${activity.id}', payload);
    return ActivityModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Deletes an activity by ID.
  Future<bool> deleteActivity(String activityId) async {
    await _delete('/activities/$activityId');
    return true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXPENSES CRUD
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches all expenses for a specific trip.
  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    final body = await _get('/trips/$tripId/expenses');
    final data = body['data'];
    if (data is List) {
      return data
          .map((item) => ExpenseModel.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a new expense under a specific trip.
  Future<ExpenseModel> createExpense(String tripId, ExpenseModel expense) async {
    final payload = expense.toMap();
    final body = await _post('/trips/$tripId/expenses', payload);
    return ExpenseModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Updates an existing expense by ID.
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final payload = {
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': expense.date.toIso8601String(),
      if (expense.notes != null) 'notes': expense.notes,
    };
    final body = await _put('/expenses/${expense.id}', payload);
    return ExpenseModel.fromMap(body['data'] as Map<dynamic, dynamic>);
  }

  /// Deletes an expense by ID.
  Future<bool> deleteExpense(String expenseId) async {
    await _delete('/expenses/$expenseId');
    return true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GUIDES GET
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches guides from the backend, with optional category or search filters.
  Future<List<GuideModel>> getGuides({String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    String path = '/guides';
    if (queryParams.isNotEmpty) {
      final query = Uri(queryParameters: queryParams).query;
      path = '$path?$query';
    }

    final body = await _get(path);
    final data = body['data'];
    if (data is List) {
      return data
          .map((item) => GuideModel.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches a single guide by ID.
  Future<GuideModel?> getGuideById(String id) async {
    try {
      final body = await _get('/guides/$id');
      final data = body['data'];
      if (data is Map) {
        return GuideModel.fromMap(data);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HTTP HELPERS & PARSING
  // ───────────────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (tokenProvider != null) {
      try {
        final token = await tokenProvider!();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('[ApiService] Failed to obtain auth token: $e');
      }
    }
    return headers;
  }

  Uri _buildUri(String path) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<dynamic> _get(String path) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(_buildUri(path), headers: headers)
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .post(_buildUri(path), headers: headers, body: jsonEncode(body))
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .put(_buildUri(path), headers: headers, body: jsonEncode(body))
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .delete(_buildUri(path), headers: headers)
          .timeout(timeout);
      return _parseResponse(response);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  dynamic _parseResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final message = (jsonBody is Map && jsonBody['message'] != null)
        ? jsonBody['message'].toString()
        : 'Request failed with status code ${response.statusCode}';

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      details: jsonBody,
    );
  }

  ApiException _wrapException(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    if (error is TimeoutException) {
      return const ApiException(
        message: 'Request timed out. Please check your network connection.',
        statusCode: 408,
      );
    }
    if (error is SocketException) {
      return ApiException(
        message: 'Network connection unavailable: ${error.message}',
        statusCode: 0,
      );
    }
    return ApiException(
      message: error.toString(),
      statusCode: 0,
    );
  }
}
