import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_date_time_picker_dialog.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/activity_model.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';

class AddActivityScreen extends StatefulWidget {
  final TripModel trip;
  final int initialDayNumber;
  final ActivityModel? initialActivity;
  final String? customTitle;

  const AddActivityScreen({
    super.key,
    required this.trip,
    this.initialDayNumber = 1,
    this.initialActivity,
    this.customTitle,
  });

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedCategory = 'Sightseeing';

  final List<String> _categories = [
    'Sightseeing',
    'Food & Dining',
    'Adventure',
    'Culture & Art',
    'Relaxation',
    'Temple',
    'Beach Club',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Nature',
    'Shopping',
    'Activity',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialActivity != null) {
      final act = widget.initialActivity!;
      _nameController.text = act.title;
      _locationController.text = act.location;
      _notesController.text = act.notes ?? '';
      _selectedCategory = _categories.contains(act.category) ? act.category : 'Sightseeing';
      _selectedDate = act.date;
      final parts = act.timeString.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      } else {
        _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      }
    } else {
      // Calculate initial date based on initialDayNumber
      final offsetDays = widget.initialDayNumber - 1;
      _selectedDate = widget.trip.startDate.add(Duration(days: offsetDays));
      if (_selectedDate.isAfter(widget.trip.endDate)) {
        _selectedDate = widget.trip.startDate;
      }
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final result = await CustomDateTimePickerDialog.show(
      context: context,
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate.add(const Duration(days: 30)),
    );

    if (result != null) {
      setState(() {
        _selectedDate = DateTime(result.year, result.month, result.day);
        _selectedTime = TimeOfDay(hour: result.hour, minute: result.minute);
      });
    }
  }

  void _saveActivity() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Calculate day number relative to trip start date
    var diffDays = _selectedDate.difference(widget.trip.startDate).inDays;
    var dayNumber = diffDays + 1;
    if (dayNumber < 1) dayNumber = 1;

    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minStr = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    final tripProvider = context.read<TripProvider>();

    if (widget.initialActivity != null) {
      final updatedActivity = widget.initialActivity!.copyWith(
        dayNumber: dayNumber,
        date: _selectedDate,
        timeString: timeStr,
        title: _nameController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      tripProvider.updateActivity(updatedActivity);
      tripProvider.selectDay(dayNumber);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity "${updatedActivity.title}" updated successfully!'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final newActivity = ActivityModel(
        id: const Uuid().v4(),
        tripId: widget.trip.id,
        dayNumber: dayNumber,
        date: _selectedDate,
        timeString: timeStr,
        title: _nameController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      tripProvider.addActivity(newActivity);
      tripProvider.selectDay(dayNumber);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity "${newActivity.title}" added to Day $dayNumber!'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialActivity != null;
    final dateFormatted = DateFormat('d MMM yyyy').format(_selectedDate);
    final dt = DateTime(2025, 1, 1, _selectedTime.hour, _selectedTime.minute);
    final timeFormatted = DateFormat('hh:mm a').format(dt);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('add_activity_back_button'),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.customTitle ?? (isEditing ? 'Edit Activity' : 'Add Activity')),
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
                    // Activity Name Field
                    CustomTextField(
                      label: 'Activity Name',
                      hintText: 'e.g. Uluwatu Temple',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an activity name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Input
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
                          onTap: _pickDateTime,
                          child: Container(
                            height: 48,
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

                    // Time Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDateTime,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.subtle, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      timeFormatted,
                                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.watch_later_outlined,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
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
                          height: 48,
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
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
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

                    // Location Field
                    CustomTextField(
                      label: 'Location',
                      hintText: 'e.g. Uluwatu, Bali',
                      controller: _locationController,
                      suffixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes Field (Optional)
                    CustomTextField(
                      label: 'Notes (Optional)',
                      hintText: 'e.g. Remember to bring sunglasses & dress code for temple',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              // Save Activity CTA Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: CustomButton(
                  text: isEditing ? 'Save Changes' : 'Save Activity',
                  onPressed: _saveActivity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
