import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:travel_tales/providers/auth_provider.dart';
import 'package:travel_tales/providers/settings_provider.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/providers/offline_map_provider.dart';
import 'package:travel_tales/views/auth/login_screen.dart';
import 'package:travel_tales/views/auth/signup_screen.dart';
import 'package:travel_tales/views/splash/splash_screen.dart';
import 'package:travel_tales/views/navigation/main_navigation_shell.dart';

import 'package:travel_tales/services/firebase_auth_service.dart';

Widget _createLoginWidget({
  AuthProvider? authProvider,
  TripProvider? tripProvider,
  SettingsProvider? settingsProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<TripProvider>(
        create: (_) => tripProvider ?? TripProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => settingsProvider ?? SettingsProvider(),
      ),
      ChangeNotifierProvider<ExpenseProvider>(
        create: (_) => ExpenseProvider(),
      ),
      ChangeNotifierProvider<GuideProvider>(
        create: (_) => GuideProvider(),
      ),
      ChangeNotifierProvider<OfflineMapProvider>(
        create: (_) => OfflineMapProvider(),
      ),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  setUp(() {
    FirebaseAuthService.instance.mockAuthHandler = (email, password, isSignUp) async {
      if (email == AuthProvider.demoEmail && password == AuthProvider.demoPassword) {
        return const AuthResult(
          success: true,
          user: AuthUser(uid: 'demo-uid-123', email: AuthProvider.demoEmail),
          idToken: 'test-mock-token:demo-uid-123',
        );
      }
      return const AuthResult(
        success: false,
        errorMessage: 'Invalid email or password. Please check your credentials.',
      );
    };
  });

  tearDown(() async {
    FirebaseAuthService.instance.mockAuthHandler = null;
    await FirebaseAuthService.instance.signOut();
  });

  group('Final Phase – AuthProvider Unit Tests', () {
    test('default authentication state is unauthenticated', () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUserEmail, isNull);
      expect(auth.errorMessage, isNull);
      expect(auth.isLoading, isFalse);
    });

    test('login with incorrect credentials fails and sets error message', () async {
      final auth = AuthProvider();
      final result = await auth.login('wrong@example.com', 'wrongpassword');

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, isNotNull);
      expect(auth.errorMessage, contains('Invalid email or password'));
    });

    test('login with correct demo credentials succeeds and clears errors', () async {
      final auth = AuthProvider();
      final result = await auth.login(
        AuthProvider.demoEmail,
        AuthProvider.demoPassword,
      );

      expect(result, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUserEmail, AuthProvider.demoEmail);
      expect(auth.errorMessage, isNull);
    });

    test('logout clears authentication state and session', () async {
      final auth = AuthProvider();
      await auth.login(AuthProvider.demoEmail, AuthProvider.demoPassword);
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUserEmail, isNull);
    });
  });

  group('Final Phase – LoginScreen Widget Tests', () {
    testWidgets('renders brand title, welcome heading, and form fields', (tester) async {
      await tester.pumpWidget(_createLoginWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Log in to your TravelTales account'), findsOneWidget);
      expect(find.text('Demo Credentials'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('empty email validation triggers error', (tester) async {
      await tester.pumpWidget(_createLoginWidget());
      await tester.pumpAndSettle();

      // Tap Log In with empty fields
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('invalid email format triggers validation error', (tester) async {
      await tester.pumpWidget(_createLoginWidget());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'notanemail');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('empty password triggers validation error', (tester) async {
      await tester.pumpWidget(_createLoginWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'valid@example.com');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('auto-fill populates demo credentials', (tester) async {
      await tester.pumpWidget(_createLoginWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();

      expect(find.text(AuthProvider.demoEmail), findsOneWidget);
      expect(find.text(AuthProvider.demoPassword), findsOneWidget);
    });

    testWidgets('incorrect credentials display error banner and stay on login', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(_createLoginWidget(authProvider: auth));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'user@example.com');
      await tester.enterText(textFields.at(1), 'WrongPassword123');

      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Error banner is displayed
      expect(find.text('Invalid email or password. Please check your credentials.'), findsOneWidget);
      // Still on login
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('correct demo credentials successfully navigate to MainNavigationShell', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(_createLoginWidget(authProvider: auth));
      await tester.pumpAndSettle();

      // Auto fill and submit
      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should have navigated to MainNavigationShell
      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('Final Phase – Splash Screen Integration Tests', () {
    testWidgets('tapping Log In on SplashScreen navigates to LoginScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
            ),
          ],
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log In rich text link
      final loginFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Log In'),
      );
      expect(loginFinder, findsOneWidget);
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();

      // Navigated to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });

  group('Final Phase – SignupScreen Widget & Flow Tests', () {
    Widget createSignupWidget({AuthProvider? authProvider}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => authProvider ?? AuthProvider(),
          ),
          ChangeNotifierProvider<TripProvider>(
            create: (_) => TripProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<ExpenseProvider>(
            create: (_) => ExpenseProvider(),
          ),
          ChangeNotifierProvider<GuideProvider>(
            create: (_) => GuideProvider(),
          ),
          ChangeNotifierProvider<OfflineMapProvider>(
            create: (_) => OfflineMapProvider(),
          ),
        ],
        child: const MaterialApp(
          home: SignupScreen(),
        ),
      );
    }

    testWidgets('renders brand title, headings, and all 3 form fields', (tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Join TravelTales to plan and share your journeys'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('empty fields trigger validation errors', (tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('short password triggers min length error', (tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newuser@example.com');
      await tester.enterText(fields.at(1), '123');
      await tester.enterText(fields.at(2), '123');

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('password mismatch triggers validation error', (tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newuser@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'differentPassword');

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful signup navigates to MainNavigationShell', (tester) async {
      FirebaseAuthService.instance.mockAuthHandler = (email, password, isSignUp) async {
        return const AuthResult(
          success: true,
          user: AuthUser(uid: 'new-user-uid', email: 'newuser@example.com'),
          idToken: 'test-mock-token:new-user-uid',
        );
      };

      final auth = AuthProvider();
      await tester.pumpWidget(createSignupWidget(authProvider: auth));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newuser@example.com');
      await tester.enterText(fields.at(1), 'securePassword123');
      await tester.enterText(fields.at(2), 'securePassword123');

      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);
    });

    testWidgets('signup failure displays error banner', (tester) async {
      FirebaseAuthService.instance.mockAuthHandler = (email, password, isSignUp) async {
        return const AuthResult(
          success: false,
          errorMessage: 'An account already exists with this email address.',
        );
      };

      final auth = AuthProvider();
      await tester.pumpWidget(createSignupWidget(authProvider: auth));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'existing@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'password123');

      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('An account already exists with this email address.'), findsOneWidget);
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });
}
