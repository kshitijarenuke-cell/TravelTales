import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guide_model.dart';

class GuideCard extends StatelessWidget {
  final GuideModel guide;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const GuideCard({
    super.key,
    required this.guide,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtle.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryLight,
              ),
              clipBehavior: Clip.antiAlias,
              child: guide.imageUrl != null && guide.imageUrl!.isNotEmpty
                  ? Image.network(
                      guide.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackThumbnail(),
                    )
                  : _buildFallbackThumbnail(),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tour Title
                    Text(
                      guide.tourTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating row
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.starGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          guide.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '(${_formatReviewCount(guide.reviewsCount)} reviews)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Price
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '₹ ${_formatPrice(guide.pricePerPerson)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const TextSpan(
                            text: ' per person',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 32,
          color: AppColors.primaryTeal,
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

/// Favorite heart button for the guide card (rendered as Stack overlay).
class GuideFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const GuideFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFavorite),
          color: const Color(0xFFEF4444),
          size: 22,
        ),
      ),
    );
  }
}
