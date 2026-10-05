import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:travel_tales/models/expense_model.dart';
import 'package:travel_tales/models/trip_model.dart';
import 'package:travel_tales/providers/trip_provider.dart';
import 'package:travel_tales/providers/expense_provider.dart';
import 'package:travel_tales/providers/guide_provider.dart';
import 'package:travel_tales/views/expenses/expenses_screen.dart';
import 'package:travel_tales/views/expenses/widgets/budget_progress_card.dart';
import 'package:travel_tales/views/expenses/widgets/expense_card.dart';

void main() {
  group('Phase 4 Expenses & Budget Tests', () {
    testWidgets('BudgetProgressCard renders dynamic calculations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressCard(
              totalSpent: 24500.0,
              budget: 40000.0,
            ),
          ),
        ),
      );

      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹ 24,500'), findsOneWidget);
      expect(find.text('Budget: ₹ 40,000'), findsOneWidget);
      expect(find.text('Remaining: ₹ 15,500'), findsOneWidget);
      expect(find.text('61%'), findsOneWidget);
    });

    testWidgets('ExpenseCard renders title, formatted date and rupee amount', (WidgetTester tester) async {
      final expense = ExpenseModel(
        id: 'exp-test',
        tripId: 'trip-1',
        title: 'Flight Tickets',
        amount: 12000.0,
        category: 'Flight',
        date: DateTime(2025, 4, 12),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: expense,
            ),
          ),
        ),
      );

      expect(find.text('Flight Tickets'), findsOneWidget);
      expect(find.text('12 Apr 2025'), findsOneWidget);
      expect(find.text('₹ 12,000'), findsOneWidget);
    });

    testWidgets('ExpensesScreen renders empty state when trip has no expenses', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyTrip = TripModel(
        id: 'empty-trip-id',
        title: 'New Trip',
        destination: 'Nowhere',
        startDate: DateTime(2025, 7, 1),
        endDate: DateTime(2025, 7, 5),
        budget: 20000.0,
      );

      final tripProvider = TripProvider();
      tripProvider.selectTrip(emptyTrip);

      final expenseProvider = ExpenseProvider();
      expenseProvider.loadExpensesForTrip('empty-trip-id');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider(create: (_) => GuideProvider()),
          ],
          child: const MaterialApp(
            home: ExpensesScreen(),
          ),
        ),
      );

      expect(find.text('No expenses yet!'), findsOneWidget);
      expect(find.text('Start tracking your expenses to stay within budget.'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
    });
  });
}
