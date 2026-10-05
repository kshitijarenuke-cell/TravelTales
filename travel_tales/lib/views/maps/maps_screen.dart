import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/activity_model.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../../providers/offline_map_provider.dart';
import '../itinerary/add_activity_screen.dart';
import '../navigation/main_navigation_shell.dart';
import 'location_permission_screen.dart';
import 'offline_maps_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Location permission state
// ──────────────────────────────────────────────────────────────────────────────
enum _LocState {
  unknown, // initial - not yet requested
  granted, // permission granted (shows map normally)
  denied, // denied once - map shows without user loc
  permanentlyDenied, // must open settings
  permissionUi, // showing our custom permission screen
}

/// Maps screen matching traveltales_maps_screen UI reference.
///
/// Features:
/// - flutter_map with OpenStreetMap tiles
/// - Activity markers from selected trip (only activities with lat/lon)
/// - Tapping a marker shows the place preview card at the bottom
/// - Current-location FAB (requests permission on first tap)
/// - Layers FAB → opens Offline Maps screen
/// - Search bar (UI only, no backend search)
/// - Graceful handling for permission denied / service unavailable
class MapsScreen extends StatefulWidget {
  final bool bypassPermissionForTesting;
  final bool disableTileLayerForTesting;
  final ActivityModel? initialSelectedActivity;

  const MapsScreen({
    super.key,
    this.bypassPermissionForTesting = false,
    this.disableTileLayerForTesting = false,
    this.initialSelectedActivity,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Sightseeing',
    'Nature',
    'Food',
    'Culture',
    'Adventure',
    'Shopping',
    'Relaxation',
  ];

  _LocState _locState = _LocState.unknown;
  ActivityModel? _selectedActivity;
  bool _mapReady = false;

  // Default center: Bali (covers most seed activities)
  static const LatLng _defaultCenter = LatLng(-8.4095, 115.1889);
  static const double _defaultZoom = 10.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedActivity != null) {
      _selectedActivity = widget.initialSelectedActivity;
    }
    if (widget.bypassPermissionForTesting) {
      _locState = _LocState.granted;
    } else {
      _checkExistingPermission();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (!mounted) return;
      setState(() {
        if (status.isGranted) {
          _locState = _LocState.granted;
        } else if (status.isPermanentlyDenied) {
          _locState = _LocState.permanentlyDenied;
        } else {
          // Not yet granted → show our custom permission UI on first entry
          _locState = _LocState.permissionUi;
        }
      });
    } catch (_) {
      // Platform not available (e.g., web / test) → skip permission
      if (mounted) setState(() => _locState = _LocState.denied);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!mounted) return;
      setState(() {
        if (status.isGranted) {
          _locState = _LocState.granted;
        } else if (status.isPermanentlyDenied) {
          _locState = _LocState.permanentlyDenied;
        } else {
          _locState = _LocState.denied;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _locState = _LocState.denied);
    }
  }

  void _onPermissionAllow() {
    setState(() => _locState = _LocState.unknown);
    _requestLocationPermission();
  }

  void _onPermissionDeny() {
    setState(() => _locState = _LocState.denied);
  }

  @override
  Widget build(BuildContext context) {
    // Show custom permission screen before using the map
    if (_locState == _LocState.permissionUi) {
      return LocationPermissionScreen(
        onAllow: _onPermissionAllow,
        onDeny: _onPermissionDeny,
      );
    }

    final tripProvider = context.watch<TripProvider>();
    final activities = tripProvider.activities;
    final selectedTrip = tripProvider.selectedTrip;

    final query = _searchQuery.trim().toLowerCase();

    // Activities that have valid lat/lon for markers only and match search + category
    final mappableActivities = activities.where((activity) {
      if (activity.latitude == null || activity.longitude == null) return false;

      // Category filter
      if (_selectedCategory.toLowerCase() != 'all') {
        final aCat = activity.category.toLowerCase();
        final sCat = _selectedCategory.toLowerCase();
        bool matchCat = aCat == sCat || aCat.contains(sCat) || sCat.contains(aCat);
        if (sCat == 'nature' && (aCat.contains('beach') || aCat.contains('nature') || aCat.contains('park') || aCat.contains('waterfall') || aCat.contains('mountain'))) {
          matchCat = true;
        } else if (sCat == 'culture' && (aCat.contains('temple') || aCat.contains('culture') || aCat.contains('heritage') || aCat.contains('history') || aCat.contains('fort'))) {
          matchCat = true;
        } else if (sCat == 'food' && (aCat.contains('food') || aCat.contains('dining') || aCat.contains('cafe') || aCat.contains('restaurant') || aCat.contains('breakfast') || aCat.contains('lunch') || aCat.contains('dinner'))) {
          matchCat = true;
        }
        if (!matchCat) return false;
      }

      // Search filter (Title, Location, Destination/Place name)
      if (query.isNotEmpty) {
        final matchesTitle = activity.title.toLowerCase().contains(query);
        final matchesLocation = activity.location.toLowerCase().contains(query);
        final matchesNotes = activity.notes?.toLowerCase().contains(query) ?? false;
        final matchesTripDest = (selectedTrip != null && selectedTrip.destination.toLowerCase().contains(query));

        if (!matchesTitle && !matchesLocation && !matchesNotes && !matchesTripDest) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedActivity != null) {
            setState(() => _selectedActivity = null);
            return;
          }
          _handleBackNavigation(context);
        },
        child: Stack(
          children: [
            // ── Interactive Map ──────────────────────────────────────────────
            _buildMap(mappableActivities),

          // ── Empty Search / Filter State ──────────────────────────────────
          if (mappableActivities.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 40, color: AppColors.muted),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching places',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No results found for "$_searchQuery".'
                          : 'No activities found in "$_selectedCategory".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategory = 'All';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top overlay: search bar + header ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopHeader(context),
          ),

          // ── Right FABs ──────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: _selectedActivity != null ? 240 : 100,
            child: _buildFABs(context),
          ),

          // ── Permanently denied banner ────────────────────────────────────
          if (_locState == _LocState.permanentlyDenied)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPermissionDeniedBanner(),
            ),

          // ── Selected activity bottom card ────────────────────────────────
          if (_selectedActivity != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPlaceCard(_selectedActivity!),
            ),
        ],
      ),
    ),
  );
}

  // ── Map widget ─────────────────────────────────────────────────────────────
  Widget _buildMap(List<ActivityModel> mappableActivities) {
    // Compute centre: first mappable activity if available, else default
    LatLng center = _defaultCenter;
    if (mappableActivities.isNotEmpty) {
      center = LatLng(
          mappableActivities.first.latitude!,
          mappableActivities.first.longitude!);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _defaultZoom,
        onMapReady: () => setState(() => _mapReady = true),
        onTap: (tapPosition, point) {
          // Tap on map background → deselect
          setState(() => _selectedActivity = null);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OSM tile layer
        if (!widget.disableTileLayerForTesting)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.traveltales.app',
            maxZoom: 19,
          ),
        // Activity markers
        MarkerLayer(
          markers: mappableActivities.map((activity) {
            final isSelected = _selectedActivity?.id == activity.id;
            return Marker(
              point: LatLng(activity.latitude!, activity.longitude!),
              width: isSelected ? 56 : 44,
              height: isSelected ? 64 : 52,
              child: GestureDetector(
                key: ValueKey('marker_${activity.id}'),
                onTap: () {
                  setState(() => _selectedActivity = activity);
                  // Re-center map on tapped marker
                  if (_mapReady) {
                    _mapController.move(
                      LatLng(activity.latitude!, activity.longitude!),
                      _mapController.camera.zoom < 12
                          ? 13.0
                          : _mapController.camera.zoom,
                    );
                  }
                },
                child: _buildMarker(activity, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarker(ActivityModel activity, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tooltip label (only when selected)
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              activity.title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
              maxLines: 1,
            ),
          ),
        // Pin
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring when selected
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            // Main pin circle
            Container(
              width: isSelected ? 24 : 20,
              height: isSelected ? 24 : 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 3,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        // Pin tail
        Container(
          width: 2,
          height: 6,
          color: isSelected ? AppColors.primaryTeal : AppColors.primaryDark,
        ),
      ],
    );
  }

  // ── Top header ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            Colors.white.withValues(alpha: 0.80),
            Colors.transparent,
          ],
          stops: const [0, 0.7, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                children: [
                  _buildCircleButton(
                    key: const ValueKey('maps_back_button'),
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _handleBackNavigation(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Maps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildCircleButton(
                    key: const ValueKey('maps_close_button'),
                    icon: Icons.close_rounded,
                    onTap: () => _handleCloseNavigation(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 14, color: AppColors.charcoal),
                  decoration: InputDecoration(
                    hintText: 'Search title, location, place...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted.withValues(alpha: 0.8),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category filter chips
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryTeal : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryTeal : AppColors.subtle,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.primaryTeal.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigationShell(initialIndex: 0),
        ),
      );
    }
  }

  void _handleCloseNavigation(BuildContext context) {
    if (_selectedActivity != null) {
      setState(() => _selectedActivity = null);
      return;
    }
    _handleBackNavigation(context);
  }

  Widget _buildCircleButton(
      {Key? key, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.charcoal),
      ),
    );
  }

  // ── FABs ───────────────────────────────────────────────────────────────────
  Widget _buildFABs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Location FAB
        _MapFAB(
          icon: Icons.navigation_rounded,
          tooltip: _locState == _LocState.granted
              ? 'My location'
              : 'Enable location',
          iconColor: _locState == _LocState.granted
              ? AppColors.primaryTeal
              : AppColors.muted,
          onTap: () {
            if (_locState == _LocState.granted) {
              // Center on default Bali location as demo
              if (_mapReady) {
                _mapController.move(_defaultCenter, _defaultZoom);
              }
            } else if (_locState == _LocState.permanentlyDenied) {
              openAppSettings();
            } else {
              setState(() => _locState = _LocState.permissionUi);
            }
          },
        ),
        const SizedBox(height: 12),
        // Offline map layers FAB
        _MapFAB(
          icon: Icons.layers_rounded,
          tooltip: 'Offline maps',
          iconColor: AppColors.charcoal,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<OfflineMapProvider>(),
                  child: const OfflineMapsScreen(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Bottom place card ──────────────────────────────────────────────────────
  Widget _buildBottomPlaceCard(ActivityModel activity) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity info row
          Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(activity.category),
                  size: 28,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.muted),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Category + time
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.starGold),
                        const SizedBox(width: 3),
                        Text(
                          activity.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.primaryTeal),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule_rounded,
                            size: 12, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          activity.timeString,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // View Details CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () async {
                final tripProvider = context.read<TripProvider>();
                final trip = tripProvider.selectedTrip ??
                    tripProvider.trips.firstWhere(
                      (t) => t.id == activity.tripId,
                      orElse: () => TripModel(
                        id: activity.tripId,
                        title: activity.location,
                        destination: activity.location,
                        startDate: activity.date,
                        endDate: activity.date,
                        budget: 0,
                      ),
                    );

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddActivityScreen(
                      trip: trip,
                      initialDayNumber: activity.dayNumber,
                      initialActivity: activity,
                      customTitle: 'Activity Details',
                    ),
                  ),
                );

                if (mounted) {
                  final updatedList = context.read<TripProvider>().activities;
                  final updated = updatedList.firstWhere(
                    (a) => a.id == activity.id,
                    orElse: () => activity,
                  );
                  setState(() {
                    _selectedActivity = updated;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permission denied banner ────────────────────────────────────────────────
  Widget _buildPermissionDeniedBanner() {
    return Container(
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Location permission denied. Open Settings to enable.',
                style: TextStyle(fontSize: 12, color: AppColors.charcoal),
              ),
            ),
            TextButton(
              onPressed: openAppSettings,
              child: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        return Icons.restaurant_rounded;
      case 'temple':
        return Icons.account_balance_rounded;
      case 'beach club':
        return Icons.beach_access_rounded;
      case 'nature':
        return Icons.park_rounded;
      case 'sightseeing':
        return Icons.photo_camera_rounded;
      case 'adventure':
        return Icons.hiking_rounded;
      case 'island tour':
        return Icons.directions_boat_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Floating Action Button helper
// ──────────────────────────────────────────────────────────────────────────────

class _MapFAB extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final VoidCallback onTap;

  const _MapFAB({
    required this.icon,
    required this.tooltip,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}
