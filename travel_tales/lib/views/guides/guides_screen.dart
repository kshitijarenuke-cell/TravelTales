import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/guide_provider.dart';
import 'widgets/guide_list_view.dart';
import 'filter_guides_screen.dart';
import '../navigation/main_navigation_shell.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Food',
    'Culture',
    'Adventure',
    'Nature',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guideProvider = context.watch<GuideProvider>();
    final selectedCategory = guideProvider.selectedCategory;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          key: const ValueKey('guides_back_button'),
          icon: const Icon(Icons.chevron_left_rounded, size: 28,
              color: AppColors.charcoal),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
              );
            }
          },
        ),
        title: const Text(
          'Local Guides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.charcoal, size: 22),
            tooltip: 'Filter Guides',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FilterGuidesScreen(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildSearchBar(guideProvider),
              ),
              // Category chips
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                child: _buildCategoryChips(guideProvider, selectedCategory),
              ),
            ],
          ),
        ),
      ),
      body: const GuideListView(),
    );
  }

  Widget _buildSearchBar(GuideProvider guideProvider) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          guideProvider.setSearchQuery(value);
        },
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.charcoal,
        ),
        decoration: InputDecoration(
          hintText: 'Search guides or places...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.muted.withValues(alpha: 0.7),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.muted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.muted),
                  onPressed: () {
                    _searchController.clear();
                    guideProvider.setSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
      GuideProvider guideProvider, String selectedCategory) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context2, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () {
              guideProvider.selectCategory(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.subtle,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
