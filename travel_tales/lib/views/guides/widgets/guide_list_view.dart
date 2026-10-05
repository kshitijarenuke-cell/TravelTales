import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/guide_provider.dart';
import 'guide_card.dart';
import '../guide_details_screen.dart';

class GuideListView extends StatelessWidget {
  const GuideListView({super.key});

  @override
  Widget build(BuildContext context) {
    final guideProvider = context.watch<GuideProvider>();
    final guides = guideProvider.filteredGuides;

    if (guides.isEmpty) {
      return _buildEmptyState(context, guideProvider);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: guides.length,
      separatorBuilder: (context2, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final guide = guides[index];
        return Stack(
          children: [
            GuideCard(
              guide: guide,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideDetailsScreen(guide: guide),
                  ),
                );
              },
              onFavoriteToggle: () {
                context.read<GuideProvider>().toggleFavorite(guide.id);
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GuideFavoriteButton(
                isFavorite: guide.isFavorite,
                onToggle: () {
                  context.read<GuideProvider>().toggleFavorite(guide.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, GuideProvider guideProvider) {
    final hasFilters = guideProvider.searchQuery.isNotEmpty ||
        guideProvider.selectedCategory != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 36,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No Guides Found' : 'No Guides Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filter to find guides.'
                  : 'Local guide recommendations will appear here.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  context.read<GuideProvider>().clearFilters();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
