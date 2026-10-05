import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/offline_map_region.dart';
import '../../providers/offline_map_provider.dart';

/// Offline Map management screen matching traveltales_offline_map reference.
///
/// Honest offline strategy (see [OfflineMapProvider] for full explanation):
/// The download button triggers a simulated 2.5-second preparation animation
/// that persists state in Hive. The app does NOT bulk-download OSM tile files
/// as that would violate OSM tile usage policy.
class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('offline_maps_back_button'),
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Offline Map',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.subtle),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero illustration + title
                  _buildHeroSection(),
                  // Saved maps list
                  _buildSavedMapsSection(context),
                ],
              ),
            ),
          ),
          // Bottom "Download New Map" button
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          // Folded map icon
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: const Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Download Offline Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Save maps for offline use and explore even without internet.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMapsSection(BuildContext context) {
    final offlineProvider = context.watch<OfflineMapProvider>();
    final regions = offlineProvider.regions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved Maps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          if (regions.isEmpty)
            _buildNoMapsState()
          else
            ...regions.map((region) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OfflineMapItem(region: region),
                )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoMapsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text(
        'No maps saved yet. Tap "Download New Map" to get started.',
        style: TextStyle(fontSize: 13, color: AppColors.muted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.subtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _showAddMapDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Download New Map',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showAddMapDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Add Map Region',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the destination name to add as an offline map region.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. Paris, Tokyo, New York',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newRegion = OfflineMapRegion(
                  id:
                      'offline-${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
                  regionName: name,
                  sizeMb: 30 + (name.length * 3), // deterministic demo size
                  expiryDays: 30,
                  status: OfflineMapStatus.notDownloaded,
                );
                context.read<OfflineMapProvider>().addRegion(newRegion);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Offline Map Region List Item
// ──────────────────────────────────────────────────────────────────────────────

class _OfflineMapItem extends StatelessWidget {
  final OfflineMapRegion region;

  const _OfflineMapItem({required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Map icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.regionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitleText(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              _buildActionButton(context),
            ],
          ),
          // Progress bar (visible only while downloading)
          if (region.status == OfflineMapStatus.downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: region.progress,
                backgroundColor: AppColors.subtle,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(region.progress * 100).toInt()}% — preparing demo data…',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitleText() {
    switch (region.status) {
      case OfflineMapStatus.downloaded:
        return '${region.sizeMb} MB · Ready (demo) · Expires in ${region.expiryDays} days';
      case OfflineMapStatus.downloading:
        return '${region.sizeMb} MB · Preparing...';
      case OfflineMapStatus.error:
        return 'Error — tap to retry';
      case OfflineMapStatus.notDownloaded:
        return '${region.sizeMb} MB · Expires in ${region.expiryDays} days';
    }
  }

  Widget _buildActionButton(BuildContext context) {
    switch (region.status) {
      case OfflineMapStatus.downloaded:
        return IconButton(
          tooltip: 'Delete offline map',
          icon: const Icon(Icons.delete_outline_rounded,
              size: 22, color: AppColors.muted),
          onPressed: () {
            context.read<OfflineMapProvider>().deleteRegion(region.id);
          },
        );
      case OfflineMapStatus.downloading:
        return IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close_rounded,
              size: 22, color: AppColors.muted),
          onPressed: () {
            context.read<OfflineMapProvider>().cancelDownload(region.id);
          },
        );
      case OfflineMapStatus.error:
        return IconButton(
          tooltip: 'Retry download',
          icon: const Icon(Icons.refresh_rounded,
              size: 22, color: AppColors.error),
          onPressed: () {
            context.read<OfflineMapProvider>().downloadRegion(region.id);
          },
        );
      case OfflineMapStatus.notDownloaded:
        return IconButton(
          tooltip: 'Download',
          icon: const Icon(Icons.download_rounded,
              size: 22, color: AppColors.charcoal),
          onPressed: () {
            context.read<OfflineMapProvider>().downloadRegion(region.id);
          },
        );
    }
  }
}
