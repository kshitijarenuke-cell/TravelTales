import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_date_time_picker_dialog.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/expense_model.dart';
import '../../models/trip_model.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final TripModel trip;

  const AddExpenseScreen({
    super.key,
    required this.trip,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Food';
  late DateTime _selectedDate;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded},
    {'name': 'Hotel', 'icon': Icons.hotel_rounded},
    {'name': 'Activities', 'icon': Icons.confirmation_number_outlined},
    {'name': 'Flight', 'icon': Icons.flight_rounded},
    {'name': 'Other', 'icon': Icons.receipt_long_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.trip.startDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await CustomDateTimePickerDialog.show(
      context: context,
      initialDate: _selectedDate,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate.add(const Duration(days: 30)),
    );

    if (result != null) {
      setState(() {
        _selectedDate = DateTime(result.year, result.month, result.day);
      });
    }
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount greater than 0.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newExpense = ExpenseModel(
      id: const Uuid().v4(),
      tripId: widget.trip.id,
      title: _titleController.text.trim(),
      amount: parsedAmount,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    context.read<ExpenseProvider>().addExpense(newExpense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense "${newExpense.title}" of ₹ ${newExpense.amount.round()} added!'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('add_expense_back_button'),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Expense'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Field 1: Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.subtle, width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
                              items: _categories.map((item) {
                                final name = item['name'] as String;
                                final icon = item['icon'] as IconData;
                                return DropdownMenuItem(
                                  value: name,
                                  child: Row(
                                    children: [
                                      Icon(icon, size: 18, color: AppColors.primaryTeal),
                                      const SizedBox(width: 10),
                                      Text(
                                        name,
                                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Amount Field
                    CustomTextField(
                      label: 'Amount',
                      hintText: '0.00',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Center(
                          widthFactor: 0.0,
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an expense amount';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Please enter a valid amount greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.subtle, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormatted,
                                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field 4: Description / Title
                    CustomTextField(
                      label: 'Description',
                      hintText: 'e.g. Dinner at local restaurant',
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Field 5: Optional Notes
                    CustomTextField(
                      label: 'Notes (Optional)',
                      hintText: 'e.g. Paid via card, split with travel companions',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              // Save Expense CTA Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: CustomButton(
                  text: 'Save Expense',
                  onPressed: _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
