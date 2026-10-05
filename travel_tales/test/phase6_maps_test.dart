import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:travel_tales/models/offline_map_region.dart';
import 'package:travel_tales/providers/offline_map_provider.dart';
import 'package:travel_tales/views/maps/location_permission_screen.dart';
import 'package:travel_tales/views/maps/offline_maps_screen.dart';

void main() {
  group('Phase 6 – OfflineMapRegion Model Tests', () {
    test('OfflineMapRegion serialization round-trip', () {
      const region = OfflineMapRegion(
        id: 'offline-bali',
        regionName: 'Bali (Full Map)',
        sizeMb: 120,
        expiryDays: 30,
        status: OfflineMapStatus.downloaded,
        progress: 1.0,
      );

      final map = region.toMap();
      final restored = OfflineMapRegion.fromMap(map);

      expect(restored.id, 'offline-bali');
      expect(restored.regionName, 'Bali (Full Map)');
      expect(restored.sizeMb, 120);
      expect(restored.expiryDays, 30);
      expect(restored.status, OfflineMapStatus.downloaded);
      expect(restored.progress, 1.0);
    });

    test('OfflineMapRegion copyWith updates fields correctly', () {
      const region = OfflineMapRegion(
        id: 'offline-goa',
        regionName: 'Goa',
        sizeMb: 65,
        expiryDays: 30,
        status: OfflineMapStatus.notDownloaded,
      );

      final updated = region.copyWith(
        status: OfflineMapStatus.downloading,
        progress: 0.45,
      );

      expect(updated.id, 'offline-goa');
      expect(updated.regionName, 'Goa');
      expect(updated.sizeMb, 65);
      expect(updated.status, OfflineMapStatus.downloading);
      expect(updated.progress, 0.45);
    });

    test('OfflineMapStatus enum labels and states', () {
      expect(OfflineMapStatus.values.length, 4);
      expect(OfflineMapStatus.notDownloaded.name, 'notDownloaded');
      expect(OfflineMapStatus.downloading.name, 'downloading');
      expect(OfflineMapStatus.downloaded.name, 'downloaded');
      expect(OfflineMapStatus.error.name, 'error');
    });
  });

  group('Phase 6 – LocationPermissionScreen Widget Tests', () {
    testWidgets('renders title, description and action buttons', (tester) async {
      bool allowedTapped = false;
      bool deniedTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LocationPermissionScreen(
            onAllow: () => allowedTapped = true,
            onDeny: () => deniedTapped = true,
          ),
        ),
      );

      // Verify texts
      expect(find.text('Allow Location Access'), findsWidgets);
      expect(
        find.textContaining('We need your location to show nearby places'),
        findsOneWidget,
      );
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      // Tap Allow
      await tester.tap(find.text('Allow'));
      await tester.pump();
      expect(allowedTapped, isTrue);

      // Tap Not Now
      await tester.tap(find.text('Not Now'));
      await tester.pump();
      expect(deniedTapped, isTrue);
    });
  });

  group('Phase 6 – OfflineMapsScreen Widget Tests', () {
    testWidgets('renders offline maps list and storage summary', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OfflineMapProvider>(
              create: (_) => OfflineMapProvider(),
            ),
          ],
          child: const MaterialApp(
            home: OfflineMapsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify App Bar & Hero
      expect(find.text('Offline Map'), findsOneWidget);
      expect(find.text('Download Offline Map'), findsOneWidget);

      // Verify Saved Maps section header
      expect(find.text('Saved Maps'), findsOneWidget);

      // Verify Download New Map button exists
      expect(find.text('Download New Map'), findsOneWidget);
    });
  });
}
