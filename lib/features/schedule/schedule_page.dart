import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/providers/google_calendar_provider.dart';
import 'package:bhitte_patro/core/providers/reminder_provider.dart';
import 'package:bhitte_patro/core/providers/auth_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:bhitte_patro/features/schedule/add_reminder/add_reminder_page.dart';
import 'package:bhitte_patro/features/schedule/widgets/reminder_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final List<String> _nepaliWeekDays = [
    'आइत',
    'सोम',
    'मंगल',
    'बुध',
    'बिही',
    'शुक्र',
    'शनि'
  ];

  final List<String> _nepaliMonths = [
    'बैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कात्तिक',
    'मंसिर',
    'पुस',
    'माघ',
    'फागुन',
    'चैत'
  ];

  late DateTime _focusedDate;
  int _selectedDayIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    
    // Auto-scroll to current hour after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  void _scrollToCurrentHour() {
    final currentHour = DateTime.now().hour;
    // Estimate: Each timeline row has a minimum height, roughly 60px including padding/borders
    // This is an approximation.
    final scrollOffset = currentHour * 60.0; 
    if (_timelineScrollController.hasClients) {
      _timelineScrollController.jumpTo(scrollOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _onDaySelected(int index) {
    setState(() => _selectedDayIndex = index);
    // Scroll to the selected item (assuming 60 width + 16 spacing)
    _scrollController.animateTo(
      index * (60.0 + 16.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  DateTime _getDateForIndex(int index) {
    return _focusedDate.add(Duration(days: index));
  }

  String _toNepaliNumber(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider);
    final reminders = ref.watch(reminderProvider);
    
    // Fetch events for the 14-day range
    final CalendarRange range = (
      start: _focusedDate,
      end: _focusedDate.add(const Duration(days: 14)),
    );
    final googleEventsAsync = ref.watch(googleCalendarEventsProvider(range));

    return calendarAsync.when(
      data: (calendarData) {
        final monthDaysData =
            calendarData['monthDaysData'] as Map<String, dynamic>;
        final selectedDate = _getDateForIndex(_selectedDayIndex);
        final selectedBs =
            NepaliDateConverter.convertToBs(selectedDate, monthDaysData);

        final filteredReminders = reminders
            .where((r) =>
                r.date.year == selectedDate.year &&
                r.date.month == selectedDate.month &&
                r.date.day == selectedDate.day)
            .toList();

        final googleEvents = googleEventsAsync.value ?? [];
        final filteredGoogleEvents = googleEvents.where((event) {
          final start = event.start?.dateTime ?? event.start?.date;
          if (start == null) return false;
          return start.year == selectedDate.year &&
              start.month == selectedDate.month &&
              start.day == selectedDate.day;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 16,
            title: Text(
                '${_nepaliMonths[selectedBs['month']! - 1]}, ${_toNepaliNumber(selectedBs['year']!)}',
                style:
                    AppTypography.boldTitle.copyWith(color: AppColors.darkBlue, fontSize: 20)),
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            actions: [
              if (googleEventsAsync.value?.isEmpty ?? true)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signInWithGoogle();
                      ref.refresh(googleCalendarEventsProvider(range));
                    },
                    icon: const FaIcon(FontAwesomeIcons.google, size: 16),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkBlue, width: 1.5),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddReminderPage()),
                      );
                    },
                    icon: const Icon(Icons.add, color: AppColors.darkBlue, size: 20),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildDaySelector(monthDaysData),
              if (googleEventsAsync.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBlue),
                  minHeight: 2,
                ),
              Expanded(
                child: ListView.builder(
                  controller: _timelineScrollController,
                  padding: const EdgeInsets.all(AppSpace.medium),
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    return _buildTimelineRow(
                        index, filteredReminders, filteredGoogleEvents);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildDaySelector(Map<String, dynamic> monthDaysData) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.medium),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.medium),
          itemCount: 14,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpace.medium),
          itemBuilder: (context, index) {
            final date = _getDateForIndex(index);
            final bsDate = NepaliDateConverter.convertToBs(date, monthDaysData);
            final isSelected = index == _selectedDayIndex;
            final isToday = index == 0;

            return GestureDetector(
              onTap: () => _onDaySelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.darkBlue
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _nepaliWeekDays[(date.weekday % 7)],
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white70 : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _toNepaliNumber(bsDate['day']!),
                      style: AppTypography.boldTitle.copyWith(
                        color: isSelected ? Colors.white : AppColors.black,
                        fontSize: 18,
                      ),
                    ),
                    if (isToday && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.darkBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineRow(int hour, List<dynamic> reminders, List<google_calendar.Event> googleEvents) {
    final hourReminders = reminders.where((r) => r.time.hour == hour).toList();
    final hourGoogleEvents = googleEvents.where((e) {
      final start = (e.start?.dateTime ?? e.start?.date)?.toLocal();
      return start?.hour == hour;
    }).toList();

    final currentHour = DateTime.now().hour;
    final isNow = hour == currentHour && _selectedDayIndex == 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Column
        Container(
          width: 50,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            textAlign: TextAlign.right,
            style: AppTypography.caption.copyWith(
              color: isNow ? AppColors.darkBlue : Colors.grey.shade500,
              fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Timeline content with vertical line
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isNow ? AppColors.darkBlue.withOpacity(0.5) : Colors.grey.shade200,
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hourReminders.isEmpty && hourGoogleEvents.isEmpty)
                  const SizedBox(height: 40)
                else ...[
                  ...hourReminders.map((r) => _buildEventCard(r)),
                  ...hourGoogleEvents.map((e) => _buildGoogleEventCard(e)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(dynamic reminder) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ReminderDetailSheet(
          title: reminder.title,
          description: reminder.description,
          time: reminder.time.format(context),
          date: "${reminder.date.day}/${reminder.date.month}/${reminder.date.year}",
          onDelete: () => ref.read(reminderProvider.notifier).deleteReminder(reminder.id),
        ),
      ),
      child: Container(
        // ... rest of the container code
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpace.medium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reminder.title,
                  style: AppTypography.boldBody.copyWith(
                    color: AppColors.black,
                    fontSize: 15,
                  ),
                ),
                Text(
                  reminder.time.format(context),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (reminder.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reminder.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleEventCard(google_calendar.Event event) {
    final startTime = event.start?.dateTime ?? event.start?.date;
    
    // Convert to local time zone for display
    final timeString = startTime != null 
        ? TimeOfDay.fromDateTime(startTime.toLocal()).format(context) 
        : 'All Day';
    final dateString = startTime != null 
        ? "${startTime.toLocal().day}/${startTime.toLocal().month}/${startTime.toLocal().year}"
        : 'N/A';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ReminderDetailSheet(
          title: event.summary ?? '(No Title)',
          description: event.description ?? '',
          time: timeString,
          date: dateString,
          onDelete: () async {
            await ref.read(googleCalendarServiceProvider).deleteEvent(event.id!);
            // Invalidate the provider instance for the current range to force a refresh
            final CalendarRange range = (
              start: _focusedDate,
              end: _focusedDate.add(const Duration(days: 14)),
            );
            ref.invalidate(googleCalendarEventsProvider(range));
          },
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpace.medium),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBlue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.summary ?? '(No Title)',
                    style: AppTypography.boldBody.copyWith(
                      color: AppColors.darkBlue,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeString,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.google, size: 12, color: AppColors.darkBlue),
                const SizedBox(width: 4),
                Text(
                  'Google Calendar',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkBlue.withOpacity(0.7),
                    fontSize: 10,
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

