import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_tales/core/widgets/custom_button.dart';
import 'package:travel_tales/core/widgets/custom_card.dart';
import 'package:travel_tales/core/widgets/empty_state_widget.dart';

void main() {
  testWidgets('CustomButton renders label and responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Create Trip',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Create Trip'), findsOneWidget);
    await tester.tap(find.text('Create Trip'));
    expect(tapped, isTrue);
  });

  testWidgets('EmptyStateWidget renders message and action button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No Expenses Yet',
            message: 'Keep track of flights, stays, and meals.',
            actionText: 'Add Expense',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('No Expenses Yet'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('CustomCard renders child properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });
}
