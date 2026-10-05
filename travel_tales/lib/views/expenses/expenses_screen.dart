import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/trip_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import 'add_expense_screen.dart';
import '../navigation/main_navigation_shell.dart';
import 'widgets/budget_progress_card.dart';
import 'widgets/expense_card.dart';

class ExpensesScreen extends StatefulWidget {
  final bool showBackButton;

  const ExpensesScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Hotel',
    'Activities',
    'Flight',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripProvider = context.read<TripProvider>();
      if (tripProvider.selectedTrip != null) {
        context.read<ExpenseProvider>().loadExpensesForTrip(tripProvider.selectedTrip!.id);
      }
    });
  }

  void _navigateToAddExpense(BuildContext context, TripModel trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final selectedTrip = tripProvider.selectedTrip;

    if (selectedTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Expenses'),
          leading: widget.showBackButton
              ? IconButton(
                  key: const ValueKey('expenses_back_button'),
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
            icon: Icons.account_balance_wallet_outlined,
            title: 'No Trip Selected',
            message: 'Please select or create a trip from the Dashboard first.',
          ),
        ),
      );
    }

    // Ensure expenses are loaded for the selected trip
    if (expenseProvider.currentTripId != selectedTrip.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<ExpenseProvider>().loadExpensesForTrip(selectedTrip.id);
        }
      });
    }

    final allExpenses = expenseProvider.expenses;
    final filteredExpenses = expenseProvider.filteredExpenses;
    final selectedCategory = expenseProvider.selectedCategory;
    final totalSpent = expenseProvider.totalSpent;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                key: const ValueKey('expenses_back_button'),
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
              'Expenses',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryTeal, size: 26),
            onPressed: () => _navigateToAddExpense(context, selectedTrip),
          ),
        ],
      ),
      body: SafeArea(
        child: allExpenses.isEmpty
            ? _buildEmptyState(context, selectedTrip)
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat.toLowerCase() == selectedCategory.toLowerCase();

                        return GestureDetector(
                          onTap: () => expenseProvider.selectCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryTeal : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryTeal : AppColors.subtle,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primaryTeal.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.charcoal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Budget & Total Spent Summary Card
                  BudgetProgressCard(
                    totalSpent: totalSpent,
                    budget: selectedTrip.budget,
                    onFilterTap: () => _showExpenseFilterSheet(context),
                  ),
                  const SizedBox(height: 20),

                  // Section Title: Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Text(
                        '${filteredExpenses.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Expenses List
                  if (filteredExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No expenses under "$selectedCategory"',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredExpenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return ExpenseCard(
                          expense: expense,
                          onTap: () {
                            _showExpenseDetailSheet(context, expense);
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: allExpenses.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () => _navigateToAddExpense(context, selectedTrip),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Expense',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, TripModel trip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Backpack / Luggage illustration icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2), width: 1.5),
              ),
              child: const Icon(
                Icons.backpack_outlined,
                size: 44,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No expenses yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your expenses to stay within budget.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 48,
              child: CustomButton(
                text: 'Add Expense',
                onPressed: () => _navigateToAddExpense(context, trip),
                borderRadius: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetailSheet(BuildContext context, dynamic expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  expense.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${expense.amount.round()}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.category,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Notes: ${expense.notes!}',
                    style: const TextStyle(fontSize: 13, color: AppColors.charcoal, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      context.read<ExpenseProvider>().deleteExpense(expense.id);
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpenseFilterSheet(BuildContext context) {
    final expenseProvider = context.read<ExpenseProvider>();
    String tempCategory = expenseProvider.selectedCategory;
    String tempSort = expenseProvider.sortBy;

    const sortOptions = [
      'Default',
      'Highest Amount',
      'Lowest Amount',
      'Newest Date',
      'Oldest Date',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.subtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter & Sort Expenses',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            expenseProvider.resetFilters();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('close_expense_filter'),
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                          onPressed: () => Navigator.of(ctx).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                  // Categories section
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = tempCategory.toLowerCase() == cat.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryTeal : AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryTeal : AppColors.subtle,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Sort section
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortOptions.map((sort) {
                      final isSelected = tempSort == sort;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempSort = sort;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryTeal : AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryTeal : AppColors.subtle,
                            ),
                          ),
                          child: Text(
                            sort,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        expenseProvider.selectCategory(tempCategory);
                        expenseProvider.setSortBy(tempSort);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        );
      },
    );
  }
}
