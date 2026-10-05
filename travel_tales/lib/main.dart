import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'providers/trip_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/guide_provider.dart';
import 'providers/offline_map_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/hive_storage_service.dart';
import 'services/mock_data_service.dart';
import 'services/firebase_auth_service.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive local persistence
  await HiveStorageService.init();

  // Initialize Firebase Auth
  await FirebaseAuthService.instance.initialize();

  // Seed realistic demo data matching UI references (Bali, Goa, Manali, Expenses, Guides)
  await MockDataService.seedInitialDataIfEmpty();

  runApp(const TravelTalesApp());
}

class TravelTalesApp extends StatelessWidget {
  const TravelTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()..loadTrips()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadExpensesForTrip('trip-bali-1')),
        ChangeNotifierProvider(create: (_) => GuideProvider()..loadGuides()),
        ChangeNotifierProvider(create: (_) => OfflineMapProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: MaterialApp(
        title: 'TravelTales',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
