import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/guide_provider.dart';

class FilterGuidesScreen extends StatefulWidget {
  const FilterGuidesScreen({super.key});

  @override
  State<FilterGuidesScreen> createState() => _FilterGuidesScreenState();
}

class _FilterGuidesScreenState extends State<FilterGuidesScreen> {
  // Local state for filter dialog (applied on confirm)
  late String _selectedCategory;
  late double _minPrice;
  late double _maxPrice;
  late int _minRating;

  static const List<String> _categories = [
    'All',
    'Food',
    'Culture',
    'Adventure',
    'Nature',
  ];

  static const double _priceMin = 0;
  static const double _priceMax = 5000;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GuideProvider>();
    _selectedCategory = provider.selectedCategory;
    _minPrice = provider.filterMinPrice;
    _maxPrice = provider.filterMaxPrice;
    _minRating = provider.filterMinRating;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('filter_guides_back_button'),
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Filter Guides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.subtle,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 14),
            _buildCategoryChips(),
            const SizedBox(height: 28),

            // SECTION 2: Price Range
            _buildSectionTitle('Price Range'),
            const SizedBox(height: 12),
            _buildPriceRangeCard(),
            const SizedBox(height: 28),

            // SECTION 3: Rating
            _buildSectionTitle('Rating'),
            const SizedBox(height: 12),
            _buildRatingCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context2, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal
                    : const Color(0xFFEBF0F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRangeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Min / Max labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceBadge('Min:', _minPrice),
              _buildPriceBadge('Max:', _maxPrice),
            ],
          ),
          const SizedBox(height: 16),
          // RangeSlider
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: _priceMin,
            max: _priceMax,
            divisions: 50,
            activeColor: AppColors.primaryTeal,
            inactiveColor: AppColors.subtle,
            onChanged: (RangeValues values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          // Scale labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹ 0',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('₹ 2,500',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('₹ 5,000+',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(String label, double value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.2)),
          ),
          child: Text(
            '₹ ${_formatPrice(value)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return GestureDetector(
      onTap: _cycleRating,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(5, (index) {
                final filled = index < _minRating;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: filled
                        ? AppColors.starGold
                        : AppColors.lightGrey,
                  ),
                );
              }),
            ),
            Row(
              children: [
                Text(
                  _minRating == 0 ? 'Any' : '$_minRating+',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cycleRating() {
    setState(() {
      _minRating = (_minRating + 1) % 6; // 0 → 1 → 2 → 3 → 4 → 5 → 0
    });
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
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
      child: Row(
        children: [
          // Apply Filters button
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Clear All button
          OutlinedButton(
            onPressed: _clearAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.subtle),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final provider = context.read<GuideProvider>();
    provider.selectCategory(_selectedCategory);
    provider.setFilterMinPrice(_minPrice);
    provider.setFilterMaxPrice(_maxPrice);
    provider.setFilterMinRating(_minRating);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _selectedCategory = 'All';
      _minPrice = _priceMin;
      _maxPrice = _priceMax;
      _minRating = 0;
    });
    context.read<GuideProvider>().clearFilters();
    Navigator.of(context).pop();
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
