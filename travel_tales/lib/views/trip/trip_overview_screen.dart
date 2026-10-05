import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/guide_provider.dart';
import '../navigation/main_navigation_shell.dart';

class TripOverviewScreen extends StatelessWidget {
  final TripModel trip;

  const TripOverviewScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final dateRange = DateFormatter.formatTripDateRange(trip.startDate, trip.endDate);
    final daysText = '${trip.durationInDays} days';

    // Access providers
    final tripProvider = context.watch<TripProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final guideProvider = context.watch<GuideProvider>();

    final activitiesCount = tripProvider.activities.where((a) => a.tripId == trip.id).length;
    final totalSpentFormatted = DateFormatter.formatCurrency(expenseProvider.totalSpent);
    final guidesCount = guideProvider.guides.length;
    final daysLeft = trip.durationInDays;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('trip_overview_back_button'),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              trip.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$dateRange · $daysText',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.charcoal),
            onPressed: () {
              _showTripOptionsBottomSheet(context, trip);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Hero Image Card
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primaryLight,
                border: Border.all(color: AppColors.subtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      trip.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildHeroFallback(),
                    )
                  : _buildHeroFallback(),
            ),
            const SizedBox(height: 16),

            // 2x2 Trip Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _buildStatCard(
                  value: '$activitiesCount',
                  label: 'Activities',
                ),
                _buildStatCard(
                  value: totalSpentFormatted,
                  label: 'Total Expenses',
                ),
                _buildStatCard(
                  value: '$guidesCount',
                  label: 'Guides',
                ),
                _buildStatCard(
                  value: '$daysLeft',
                  label: 'Days Left',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Access Section Header
            Text(
              'Quick Access',
              style: AppTypography.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // 2x2 Quick Access Actions Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
              children: [
                _buildQuickActionCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Itinerary',
                  onTap: () {
                    // Navigate to Itinerary tab (index 1)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationShell(initialIndex: 1),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Expenses',
                  onTap: () {
                    // Navigate to Expenses tab (index 2)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationShell(initialIndex: 2),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.explore_rounded,
                  label: 'Local Guides',
                  onTap: () {
                    // Navigate to Guides tab (index 3)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationShell(initialIndex: 3),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.location_on_rounded,
                  label: 'Maps',
                  onTap: () {
                    // Navigate to Maps tab (index 4)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationShell(initialIndex: 4),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.subtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 48,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  void _showTripOptionsBottomSheet(BuildContext context, TripModel trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: AppColors.primaryTeal),
                  title: Text(trip.isOfflineReady ? 'Offline Data Synced' : 'Download for Offline Mode'),
                  subtitle: Text(trip.isOfflineReady ? 'Available without internet' : 'Cache maps and itinerary'),
                  trailing: Switch(
                    value: trip.isOfflineReady,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      context.read<TripProvider>().toggleOfflineStatus(trip.id, val);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppColors.charcoal),
                  title: const Text('Share Trip Itinerary'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip itinerary link copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
