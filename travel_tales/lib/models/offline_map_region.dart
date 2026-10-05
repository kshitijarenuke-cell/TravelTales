/// Represents a single offline map region entry.
///
/// IMPORTANT OFFLINE MAP STRATEGY NOTE:
/// This app uses flutter_map with OpenStreetMap tiles (ONLINE only).
/// True offline tile caching (downloading thousands of .png tile files to
/// device storage) requires licensing compliance with OSM tile usage policy
/// and a dedicated offline tile server or a paid vector tile SDK such as
/// Mapbox or MapTiler — none of which are included in this project.
///
/// This model therefore tracks a DEMO offline-ready state that persists
/// across restarts. The user can mark a region as "downloaded" (simulating
/// preparation), which demonstrates the complete UI/state architecture.
///
/// When a region is marked offline-ready the map can still render using
/// flutter_map's normal network tiles; the UI honestly represents the
/// download as a DEMO preparation action.
enum OfflineMapStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

class OfflineMapRegion {
  final String id;
  final String regionName;
  final int sizeMb;
  final int expiryDays;
  final OfflineMapStatus status;
  /// Download progress 0.0 – 1.0 (only valid while status == downloading)
  final double progress;

  const OfflineMapRegion({
    required this.id,
    required this.regionName,
    required this.sizeMb,
    required this.expiryDays,
    this.status = OfflineMapStatus.notDownloaded,
    this.progress = 0.0,
  });

  OfflineMapRegion copyWith({
    String? id,
    String? regionName,
    int? sizeMb,
    int? expiryDays,
    OfflineMapStatus? status,
    double? progress,
  }) {
    return OfflineMapRegion(
      id: id ?? this.id,
      regionName: regionName ?? this.regionName,
      sizeMb: sizeMb ?? this.sizeMb,
      expiryDays: expiryDays ?? this.expiryDays,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'regionName': regionName,
      'sizeMb': sizeMb,
      'expiryDays': expiryDays,
      'status': status.index,
      'progress': progress,
    };
  }

  factory OfflineMapRegion.fromMap(Map<dynamic, dynamic> map) {
    return OfflineMapRegion(
      id: map['id'] as String,
      regionName: map['regionName'] as String,
      sizeMb: (map['sizeMb'] as num).toInt(),
      expiryDays: (map['expiryDays'] as num).toInt(),
      status: OfflineMapStatus.values[(map['status'] as num?)?.toInt() ?? 0],
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
