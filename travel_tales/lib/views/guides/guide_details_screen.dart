import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/guide_model.dart';
import '../../providers/guide_provider.dart';

class GuideDetailsScreen extends StatelessWidget {
  final GuideModel guide;

  const GuideDetailsScreen({
    super.key,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    // Watch provider so favorite state updates reflect live
    final guideProvider = context.watch<GuideProvider>();
    // Get the freshest guide state from provider (in case it was updated)
    final liveGuide = guideProvider.guides.firstWhere(
      (g) => g.id == guide.id,
      orElse: () => guide,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Hero image header
              SliverToBoxAdapter(
                child: _buildHeroSection(context, liveGuide, guideProvider),
              ),
              // Content body
              SliverToBoxAdapter(
                child: _buildContentBody(liveGuide),
              ),
            ],
          ),
          // Floating nav buttons overlaid on hero
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  key: const ValueKey('guide_details_back_button'),
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildCircleButton(
                  icon: liveGuide.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: liveGuide.isFavorite
                      ? const Color(0xFFEF4444)
                      : AppColors.charcoal,
                  onTap: () {
                    context.read<GuideProvider>().toggleFavorite(liveGuide.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      // Book Now bottom bar
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, GuideModel liveGuide, GuideProvider guideProvider) {
    return SizedBox(
      height: 270,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: liveGuide.imageUrl != null && liveGuide.imageUrl!.isNotEmpty
            ? Image.network(
                liveGuide.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    _buildHeroFallback(),
              )
            : _buildHeroFallback(),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 64,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    Key? key,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.charcoal,
        ),
      ),
    );
  }

  Widget _buildContentBody(GuideModel liveGuide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            liveGuide.tourTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // Rating row
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.starGold),
              const SizedBox(width: 4),
              Text(
                liveGuide.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_formatReviewCount(liveGuide.reviewsCount)} reviews)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildCategoryChip(liveGuide.category),
              // Add location chip
              _buildLocationChip(liveGuide.location),
            ],
          ),
          const SizedBox(height: 16),
          // Price
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '₹ ${_formatPrice(liveGuide.pricePerPerson)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                const TextSpan(
                  text: ' per person',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            liveGuide.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // What's Included
          const Text(
            "What's Included",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          _buildIncludedItem('Local guide'),
          _buildIncludedItem('Entry fees & permits'),
          _buildIncludedItem('Dedicated viewing point'),
          _buildIncludedItem('Hotel pick-up & drop-off'),
          const SizedBox(height: 20),
          // Languages
          if (liveGuide.languages.isNotEmpty) ...[
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: liveGuide.languages
                  .map((lang) => _buildCategoryChip(lang))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildLocationChip(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded,
              size: 12, color: AppColors.muted),
          const SizedBox(width: 3),
          Text(
            location,
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

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_rounded,
              size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.charcoal,
            ),
          ),
        ],
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
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking for ${guide.tourTitle}!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primaryTeal,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k == k.truncate() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatPrice(double price) {
    final int pInt = price.toInt();
    if (pInt >= 1000) {
      final thousands = pInt ~/ 1000;
      final remainder = pInt % 1000;
      if (remainder == 0) return '$thousands,000';
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return pInt.toString();
  }
}
