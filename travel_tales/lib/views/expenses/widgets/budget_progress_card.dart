import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  final double totalSpent;
  final double budget;
  final VoidCallback? onFilterTap;

  const BudgetProgressCard({
    super.key,
    required this.totalSpent,
    required this.budget,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final int percentage = (progress * 100).round();
    final totalSpentFormatted = DateFormatter.formatCurrency(totalSpent);
    final budgetFormatted = DateFormatter.formatCurrency(budget);
    final remainingAmount = (budget - totalSpent).clamp(0.0, double.infinity);
    final remainingFormatted = DateFormatter.formatCurrency(remainingAmount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.subtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label and Filter icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Spent',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                  letterSpacing: 0.2,
                ),
              ),
              if (onFilterTap != null)
                GestureDetector(
                  onTap: onFilterTap,
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Total Spent Large Text
          Text(
            totalSpentFormatted,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 10),

          // Budget and Percentage Sub-row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Budget: $budgetFormatted',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remaining: $remainingFormatted',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
