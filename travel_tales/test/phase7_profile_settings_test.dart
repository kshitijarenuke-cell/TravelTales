import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:travel_tales/providers/settings_provider.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/auth_provider.dart';
import 'package:travel_tales/views/profile/profile_settings_screen.dart';
import 'package:travel_tales/views/dashboard/trip_dashboard_screen.dart';

Widget _createProfileScreenWithProviders({
  SettingsProvider? settingsProvider,
  TripProvider? tripProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => settingsProvider ?? SettingsProvider(),
      ),
      ChangeNotifierProvider<TripProvider>(
        create: (_) => tripProvider ?? TripProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(),
      ),
    ],
    child: const MaterialApp(
      home: ProfileSettingsScreen(),
    ),
  );
}

void main() {
  group('Phase 7 – SettingsProvider Unit Tests', () {
    test('default settings values are set correctly', () {
      final provider = SettingsProvider();

      expect(provider.userName, 'Kshitija Renuke');
      expect(provider.userEmail, 'kshitijarenuke@gmail.com');
      expect(provider.notificationsEnabled, isTrue);
      expect(provider.tripRemindersEnabled, isTrue);
      expect(provider.offlineStorageEnabled, isTrue);
      expect(provider.currency, 'INR (₹)');
    });

    test('profile updates modify state and notify listeners', () async {
      final provider = SettingsProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.updateProfile(name: 'Jane Doe', email: 'jane@example.com');

      expect(provider.userName, 'Jane Doe');
      expect(provider.userEmail, 'jane@example.com');
      expect(notified, isTrue);
    });

    test('toggling preferences updates state', () async {
      final provider = SettingsProvider();

      await provider.setNotificationsEnabled(false);
      expect(provider.notificationsEnabled, isFalse);

      await provider.setTripRemindersEnabled(false);
      expect(provider.tripRemindersEnabled, isFalse);

      await provider.setOfflineStorageEnabled(false);
      expect(provider.offlineStorageEnabled, isFalse);

      await provider.setCurrency('USD (\$)');
      expect(provider.currency, 'USD (\$)');
    });
  });

  group('Phase 7 – ProfileSettingsScreen Widget Tests', () {
    testWidgets('renders profile header, user name, and email', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Profile'), findsOneWidget);

      // Verify User Details
      expect(find.text('Kshitija Renuke'), findsOneWidget);
      expect(find.text('kshitijarenuke@gmail.com'), findsOneWidget);
    });

    testWidgets('renders all menu options matching UI reference', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping Notifications opens preferences sheet', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Trip & Activity Reminders'), findsOneWidget);
    });

    testWidgets('tapping Help & Support opens information sheet', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('support@traveltales.app'), findsOneWidget);
      expect(find.text('FAQs & Itinerary Guide'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
    });

    testWidgets('tapping Settings opens preferences sheet with offline storage', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Offline Data Storage'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });

    testWidgets('tapping Logout shows confirmation dialog and Cancel dismisses it', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Log Out'), findsWidgets);
      expect(find.text('Are you sure you want to log out of TravelTales?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Are you sure you want to log out of TravelTales?'), findsNothing);
    });

    testWidgets('confirming Logout navigates to SplashScreen', (tester) async {
      await tester.pumpWidget(_createProfileScreenWithProviders());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Tap Log Out button in dialog
      final logoutButton = find.widgetWithText(ElevatedButton, 'Log Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Navigated to SplashScreen
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Dashboard user avatar navigates to ProfileSettingsScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
            ChangeNotifierProvider<TripProvider>(
              create: (_) => TripProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
            ),
          ],
          child: const MaterialApp(
            home: TripDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find avatar
      final avatarFinder = find.byType(GestureDetector).first;
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Should open ProfileSettingsScreen
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Kshitija Renuke'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });
  });
}
