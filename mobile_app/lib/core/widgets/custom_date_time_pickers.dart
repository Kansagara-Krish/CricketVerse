// lib/core/widgets/custom_date_time_pickers.dart
// Reusable Custom Animated Date Picker and Wheel Time Picker matching design references

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// --- CUSTOM ANIMATED DATE PICKER DIALOG ---
class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final String title;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.title,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required String title,
  }) {
    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CustomDatePicker',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.85, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: scale.value,
            child: Align(
              alignment: Alignment.center,
              child: CustomDatePickerDialog(initialDate: initialDate, title: title),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  bool _isYearPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; // Sunday = 0

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar: "September 2026 >" & Navigation arrows "< >"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _isYearPicker = !_isYearPicker),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedMonth),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isYearPicker ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                          color: const Color(0xFF2563EB),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isYearPicker)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF2563EB), size: 24),
                        onPressed: _prevMonth,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 24),
                        onPressed: _nextMonth,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Animated Switcher between Month Calendar View and Year Picker Grid View
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _isYearPicker
                  ? _buildYearPickerGrid()
                  : _buildMonthCalendarGrid(daysInMonth, firstWeekday),
            ),

            const SizedBox(height: 20),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    'Select Date',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendarGrid(int daysInMonth, int firstWeekday) {
    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      key: ValueKey('calendar_${_focusedMonth.year}_${_focusedMonth.month}'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) {
            return SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: firstWeekday + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (ctx, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - firstWeekday + 1;
            final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
            final isSelected = cellDate.year == _selectedDate.year &&
                cellDate.month == _selectedDate.month &&
                cellDate.day == _selectedDate.day;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = cellDate;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearPickerGrid() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - 2 + i);

    return GridView.builder(
      key: const ValueKey('year_picker'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (ctx, index) {
        final year = years[index];
        final isSelected = year == _focusedMonth.year;

        return InkWell(
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(year, _focusedMonth.month);
              _isYearPicker = false;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Text(
                '$year',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- CUSTOM WHEEL TIME PICKER DIALOG (Matching Image 1 Wheel Spinner Reference) ---
class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const CustomTimePickerDialog({
    super.key,
    required this.initialTime,
    required this.title,
  });

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
    required String title,
  }) {
    return showGeneralDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CustomTimePicker',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.85, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack));
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: scale.value,
            child: Align(
              alignment: Alignment.center,
              child: CustomTimePickerDialog(initialTime: initialTime, title: title),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late int _selectedHour; // 1 to 12
  late int _selectedMinute; // 0 to 59
  late String _selectedPeriod; // AM or PM

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;

  @override
  void initState() {
    super.initState();
    final hour = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
    _selectedHour = hour;
    _selectedMinute = widget.initialTime.minute;
    _selectedPeriod = widget.initialTime.period == DayPeriod.am ? 'AM' : 'PM';

    _hourController = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
    _periodController = FixedExtentScrollController(initialItem: _selectedPeriod == 'AM' ? 0 : 1);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  TimeOfDay _getFinalTime() {
    int hour24 = _selectedHour;
    if (_selectedPeriod == 'PM' && _selectedHour != 12) {
      hour24 += 12;
    } else if (_selectedPeriod == 'AM' && _selectedHour == 12) {
      hour24 = 0;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 18),

            // Wheel Spinner Container with Center Highlight Pill matching Image 1
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  // Center Highlight Capsule Box
                  Center(
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // 3 Scroll Wheels: Hour | Minute | Period (AM/PM)
                  Row(
                    children: [
                      // Hours Wheel (1..12)
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedHour = index + 1;
                            });
                          },
                          children: List.generate(12, (index) {
                            final hourStr = '${index + 1}';
                            final isSel = (index + 1) == _selectedHour;
                            return Center(
                              child: Text(
                                hourStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w400,
                                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Minutes Wheel (00..59)
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedMinute = index;
                            });
                          },
                          children: List.generate(60, (index) {
                            final minStr = index.toString().padLeft(2, '0');
                            final isSel = index == _selectedMinute;
                            return Center(
                              child: Text(
                                minStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w400,
                                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Period Wheel (AM / PM)
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _periodController,
                          itemExtent: 44,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedPeriod = index == 0 ? 'AM' : 'PM';
                            });
                          },
                          children: ['AM', 'PM'].map((p) {
                            final isSel = p == _selectedPeriod;
                            return Center(
                              child: Text(
                                p,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w400,
                                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bottom Actions (Cancel & Confirm)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _getFinalTime()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    'Select Time',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
