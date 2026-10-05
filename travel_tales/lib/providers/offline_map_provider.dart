import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_map_region.dart';

/// Manages offline map region state and persists it in Hive.
///
/// HONEST OFFLINE STRATEGY:
/// This provider tracks a DEMO offline-ready state. The "download" action
/// simulates a preparation step (with a progress animation) and persists the
/// result so the state survives restarts. It does NOT actually download OSM
/// tile data — true bulk tile caching violates OSM tile usage policy and
/// requires a paid SDK or self-hosted tile server.
///
/// The UI architecture is complete and production-ready: the five states
/// (notDownloaded, downloading, downloaded, error, + empty) are all
/// handled. Swapping in a real tile-download SDK would only require updating
/// the [_simulateDownload] method.
class OfflineMapProvider with ChangeNotifier {
  static const String _boxName = 'traveltales_offline_maps';

  List<OfflineMapRegion> _regions = [];

  List<OfflineMapRegion> get regions => List.unmodifiable(_regions);

  /// Seed the default region list from trip destinations if storage is empty.
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _loadFromHive();
    if (_regions.isEmpty) {
      await _seedDefaults();
    }
    notifyListeners();
  }

  void _loadFromHive() {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : null;
    if (box == null) return;
    _regions = [];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        _regions.add(OfflineMapRegion.fromMap(item));
      }
    }
  }

  Future<void> _seedDefaults() async {
    _regions = [
      const OfflineMapRegion(
        id: 'offline-bali',
        regionName: 'Bali (Full Map)',
        sizeMb: 120,
        expiryDays: 30,
        status: OfflineMapStatus.notDownloaded,
      ),
      const OfflineMapRegion(
        id: 'offline-goa',
        regionName: 'Goa',
        sizeMb: 45,
        expiryDays: 30,
        status: OfflineMapStatus.notDownloaded,
      ),
      const OfflineMapRegion(
        id: 'offline-manali',
        regionName: 'Manali',
        sizeMb: 60,
        expiryDays: 30,
        status: OfflineMapStatus.notDownloaded,
      ),
    ];
    await _persistAll();
  }

  Future<void> _persistAll() async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : null;
    if (box == null) return;
    await box.clear();
    for (final region in _regions) {
      await box.put(region.id, region.toMap());
    }
  }

  Future<void> _persistRegion(OfflineMapRegion region) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : null;
    if (box != null) {
      await box.put(region.id, region.toMap());
    }
  }

  int _indexOf(String id) => _regions.indexWhere((r) => r.id == id);

  /// Start or retry the demo-download for a region.
  Future<void> downloadRegion(String regionId) async {
    final idx = _indexOf(regionId);
    if (idx == -1) return;

    // Mark as downloading, reset progress.
    _regions[idx] = _regions[idx].copyWith(
      status: OfflineMapStatus.downloading,
      progress: 0.0,
    );
    await _persistRegion(_regions[idx]);
    notifyListeners();

    await _simulateDownload(regionId);
  }

  /// Demo download: increments progress over ~2.5 seconds then marks done.
  Future<void> _simulateDownload(String regionId) async {
    const steps = 20;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 125));
      final idx = _indexOf(regionId);
      if (idx == -1) return;
      // Check if user cancelled.
      if (_regions[idx].status != OfflineMapStatus.downloading) return;
      _regions[idx] =
          _regions[idx].copyWith(progress: i / steps);
      notifyListeners();
    }
    final idx = _indexOf(regionId);
    if (idx == -1) return;
    _regions[idx] = _regions[idx].copyWith(
      status: OfflineMapStatus.downloaded,
      progress: 1.0,
    );
    await _persistRegion(_regions[idx]);
    notifyListeners();
  }

  /// Cancel a pending download.
  Future<void> cancelDownload(String regionId) async {
    final idx = _indexOf(regionId);
    if (idx == -1) return;
    _regions[idx] = _regions[idx].copyWith(
      status: OfflineMapStatus.notDownloaded,
      progress: 0.0,
    );
    await _persistRegion(_regions[idx]);
    notifyListeners();
  }

  /// Remove a downloaded region.
  Future<void> deleteRegion(String regionId) async {
    final idx = _indexOf(regionId);
    if (idx == -1) return;
    _regions[idx] = _regions[idx].copyWith(
      status: OfflineMapStatus.notDownloaded,
      progress: 0.0,
    );
    await _persistRegion(_regions[idx]);
    notifyListeners();
  }

  /// Add a new region to the list (for "Download New Map" flow).
  Future<void> addRegion(OfflineMapRegion region) async {
    if (_indexOf(region.id) != -1) return; // already exists
    _regions.add(region);
    await _persistRegion(region);
    notifyListeners();
  }

  bool get hasAnyDownloaded =>
      _regions.any((r) => r.status == OfflineMapStatus.downloaded);
}
