import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/activity_model.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import 'add_activity_screen.dart';
import '../navigation/main_navigation_shell.dart';
import 'widgets/timeline_node.dart';

class ItineraryScreen extends StatelessWidget {
  final bool showBackButton;

  const ItineraryScreen({
    super.key,
    this.showBackButton = false,
  });

  void _navigateToAddActivity(BuildContext context, TripModel trip, int currentDay) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          trip: trip,
          initialDayNumber: currentDay,
        ),
      ),
    );
  }

  void _navigateToEditActivity(BuildContext context, TripModel trip, ActivityModel activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          trip: trip,
          initialDayNumber: activity.dayNumber,
          initialActivity: activity,
        ),
      ),
    );
  }

  void _confirmDeleteActivity(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Activity',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text('Are you sure you want to delete "${activity.title}" from your itinerary?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<TripProvider>().deleteActivity(activity.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Activity "${activity.title}" deleted.'),
                    backgroundColor: AppColors.charcoal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final selectedTrip = tripProvider.selectedTrip;

    if (selectedTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Itinerary'),
          leading: showBackButton
              ? IconButton(
                  key: const ValueKey('itinerary_back_button'),
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
                      );
                    }
                  },
                )
              : null,
        ),
        body: const Center(
          child: EmptyStateWidget(
            icon: Icons.calendar_month_outlined,
            title: 'No Trip Selected',
            message: 'Please select or create a trip from the Dashboard first.',
          ),
        ),
      );
    }

    final totalDays = selectedTrip.durationInDays;
    final selectedDay = tripProvider.selectedDayNumber;
    final dayActivities = tripProvider.selectedDayActivities;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                key: const ValueKey('itinerary_back_button'),
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
                    );
                  }
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Itinerary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            Text(
              selectedTrip.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Day Tabs Selector
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: totalDays,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final dayNum = index + 1;
                  final dayDate = selectedTrip.startDate.add(Duration(days: index));
                  final dayDateStr = DateFormat('d MMM').format(dayDate);
                  final isSelected = dayNum == selectedDay;

                  return GestureDetector(
                    onTap: () => tripProvider.selectDay(dayNum),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 68,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryTeal : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryTeal : AppColors.subtle,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primaryTeal.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Day $dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.charcoal,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayDateStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.muted,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Timeline Schedule Area
            Expanded(
              child: dayActivities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: EmptyStateWidget(
                          icon: Icons.event_note_rounded,
                          title: 'No Activities for Day $selectedDay',
                          message: 'Plan your day by adding visits, meals, tours or attractions.',
                          actionText: '+ Add Activity',
                          onAction: () => _navigateToAddActivity(context, selectedTrip, selectedDay),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      children: [
                        // Timeline nodes
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayActivities.length,
                          itemBuilder: (context, index) {
                            final activity = dayActivities[index];
                            final isFirst = index == 0;
                            final isLast = index == dayActivities.length - 1;

                            return TimelineNode(
                              activity: activity,
                              isFirst: isFirst,
                              isLast: isLast,
                              onEdit: () => _navigateToEditActivity(context, selectedTrip, activity),
                              onDelete: () => _confirmDeleteActivity(context, activity),
                            );
                          },
                        ),
                      ],
                    ),
            ),

            // Bottom Add Activity Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: CustomButton(
                  text: 'Add Activity',
                  icon: Icons.add,
                  onPressed: () => _navigateToAddActivity(context, selectedTrip, selectedDay),
                  borderRadius: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
