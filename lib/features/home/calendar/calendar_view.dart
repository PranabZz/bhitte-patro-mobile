import 'dart:async';

import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/providers/selected_date_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:bhitte_patro/features/home/calendar/date_details_view.dart';
import 'package:bhitte_patro/shared/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  // Viewed state (what is shown in the grid)
  int _viewedMonthIndex = 0; // 0-indexed for Baisakh
  int _viewedYear = 2080;

  // Selected state (what is shown in DateDetailsView)
  int? _selectedDay;
  int? _selectedMonth; // 1-indexed
  int? _selectedYear;

  bool _isInitialized = false;
  Timer? _revertTimer;

  final ScrollController _pillScrollController = ScrollController();

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

  final List<String> _weekDays = [
    'आइत',
    'सोम',
    'मंगल',
    'बुध',
    'बिही',
    'शुक्र',
    'शनि'
  ];

  String _toNepaliNumber(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join();
  }

  void _scrollToMonth(int index) {
    if (_pillScrollController.hasClients) {
      // Calculate approximate position. 
      // Each item width is MediaQuery.of(context).size.width / 4.5.
      // We want to bring the tapped index to the start of the view.
      final itemWidth = MediaQuery.of(context).size.width / 4.5;
      final separatorWidth = AppSpace.extraSmall; 
      final targetOffset = index * (itemWidth + separatorWidth);

      // Ensure we don't scroll past the max extent
      final maxScroll = _pillScrollController.position.maxScrollExtent;
      final scrollOffset = targetOffset.clamp(0.0, maxScroll);

      _pillScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startRevertTimer(Map<String, dynamic> calendarData) {
    _revertTimer?.cancel();
    _revertTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) {
        _revertToToday(calendarData);
      }
    });
  }

  void _revertToToday(Map<String, dynamic> calendarData) {
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>?;
    if (monthDaysData == null) return;

    final todayAd = DateTime.now();
    final todayBs = NepaliDateConverter.convertToBs(todayAd, monthDaysData);

    setState(() {
      _viewedYear = todayBs['year']!;
      _viewedMonthIndex = todayBs['month']! - 1;

      _selectedYear = todayBs['year']!;
      _selectedMonth = todayBs['month']!;
      _selectedDay = todayBs['day']!;
    });
    _scrollToMonth(_viewedMonthIndex);
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    _pillScrollController.dispose();
    super.dispose();
  }

  void _initializeToday(Map<String, dynamic> calendarData) {
    if (_isInitialized) return;

    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>?;
    if (monthDaysData == null) return;

    final todayAd = DateTime.now();
    final todayBs = NepaliDateConverter.convertToBs(todayAd, monthDaysData);

    setState(() {
      _viewedYear = todayBs['year']!;
      _viewedMonthIndex = todayBs['month']! - 1;

      _selectedYear = todayBs['year']!;
      _selectedMonth = todayBs['month']!;
      _selectedDay = todayBs['day']!;

      _isInitialized = true;
    });
  }

  String _monthNameEn(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider);

    return calendarAsync.when(
      data: (calendarData) {
        _initializeToday(calendarData);

        final monthDaysData =
            calendarData['monthDaysData'] as Map<String, dynamic>?;
        final holidays = calendarData['holidays'] as Map<String, dynamic>?;

        if (monthDaysData == null) {
          return const Center(child: Text("Invalid data"));
        }
        if (!monthDaysData.containsKey(_viewedYear.toString())) {
          return const Center(child: Text("Data not available"));
        }

        final months = monthDaysData[_viewedYear.toString()] as List<dynamic>;
        final daysInMonth = months[_viewedMonthIndex] as int;

        int daysSinceRef = 0;
        for (int y = 2060; y < _viewedYear; y++) {
          daysSinceRef += (monthDaysData[y.toString()] as List<dynamic>)
              .reduce((a, b) => a + b) as int;
        }
        for (int m = 0; m < _viewedMonthIndex; m++) {
          daysSinceRef += months[m] as int;
        }

        final firstDayWeekday = (DateTime.monday + daysSinceRef) % 7;

        final years =
            monthDaysData.keys.map((e) => int.parse(e)).toList()..sort();
        final minYear = years.first;
        final maxYear = years.last;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _revertToToday(calendarData);
          },
          child: Column(
            children: [
              GestureDetector(
                onTap: () {}, // Prevent taps inside from deselecting
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.medium),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_toNepaliNumber(_viewedYear),
                                  style: AppTypography.boldTitle),
                              const SizedBox(height: AppSpace.extraSmall),
                              Text(
                                  "${NepaliDateConverter.convertToAd(_viewedYear, _viewedMonthIndex + 1, 1, monthDaysData).month == NepaliDateConverter.convertToAd(_viewedYear, _viewedMonthIndex + 1, daysInMonth, monthDaysData).month ? '' : '${_monthNameEn(NepaliDateConverter.convertToAd(_viewedYear, _viewedMonthIndex + 1, 1, monthDaysData).month)}/'}${_monthNameEn(NepaliDateConverter.convertToAd(_viewedYear, _viewedMonthIndex + 1, daysInMonth, monthDaysData).month)} ${NepaliDateConverter.convertToAd(_viewedYear, _viewedMonthIndex + 1, daysInMonth, monthDaysData).year}",
                                  style: AppTypography.caption),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _viewedYear > minYear
                                    ? () => setState(() {
                                          _viewedYear--;
                                          _startRevertTimer(calendarData);
                                        })
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton(
                                onPressed: _viewedYear < maxYear
                                    ? () => setState(() {
                                          _viewedYear++;
                                          _startRevertTimer(calendarData);
                                        })
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: AppSpace.large),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          controller: _pillScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _nepaliMonths.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpace.extraSmall),
                          itemBuilder: (context, index) => SizedBox(
                            width: MediaQuery.of(context).size.width / 4.5,
                            child: PillButton(
                              text: _nepaliMonths[index],
                              isSelected: _viewedMonthIndex == index,
                              onPressed: () {
                                setState(() {
                                  _viewedMonthIndex = index;
                                  _startRevertTimer(calendarData);
                                });
                                _scrollToMonth(index);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.large),
                      Row(
                        children: _weekDays
                            .map((day) => Expanded(
                                child: Center(
                                    child: Text(day,
                                        style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)))))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpace.medium),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: daysInMonth + firstDayWeekday,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4),
                        itemBuilder: (context, index) {
                          if (index < firstDayWeekday) return const SizedBox();
                          final day = index - firstDayWeekday + 1;
                          final adDate = NepaliDateConverter.convertToAd(
                              _viewedYear,
                              _viewedMonthIndex + 1,
                              day,
                              monthDaysData);

                          final now = DateTime.now();
                          final todayBs =
                              NepaliDateConverter.convertToBs(now, monthDaysData);
                          final isTodayReal = (day == todayBs['day'] &&
                              _viewedMonthIndex == todayBs['month']! - 1 &&
                              _viewedYear == todayBs['year']);

                          final isWeekend = (index % 7 == 0 || index % 7 == 6);
                          final holidayList = holidays?['$_viewedYear']
                              ?['${_viewedMonthIndex + 1}']?['$day'];
                          final isHoliday = (holidayList != null) || isWeekend;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                                _selectedMonth = _viewedMonthIndex + 1;
                                _selectedYear = _viewedYear;
                                _startRevertTimer(calendarData);
                              });
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .setSelectedDate(SelectedDate(
                                      day: _selectedDay!,
                                      month: _selectedMonth!,
                                      year: _selectedYear!));
                            },
                            child: () {
                              final isSelected = (day == _selectedDay &&
                                  _selectedMonth == _viewedMonthIndex + 1 &&
                                  _selectedYear == _viewedYear);

                              Color bgColor = Colors.transparent;
                              Color textColor =
                                  isHoliday ? AppColors.red : AppColors.black;

                              Border? border;

                              if (isTodayReal) {
                                bgColor = AppColors.red;
                                textColor = Colors.white;
                              } else if (isSelected) {
                                bgColor = Colors.transparent;
                                textColor =
                                    isHoliday ? AppColors.red : AppColors.darkBlue;
                                border = Border.all(color: textColor, width: 2);
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: border,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(_toNepaliNumber(day),
                                          style: AppTypography.boldBody.copyWith(
                                              color: textColor, fontSize: 16)),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Text("${adDate.day}",
                                          style: AppTypography.caption.copyWith(
                                              fontSize: 10,
                                              color: (isTodayReal || isSelected)
                                                  ? textColor.withOpacity(0.7)
                                                  : Colors.grey)),
                                    ),
                                  ],
                                ),
                              );
                            }(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.medium),
              if (_selectedDay != null &&
                  _selectedMonth != null &&
                  _selectedYear != null)
                DateDetailsView(
                    day: _selectedDay!,
                    month: _selectedMonth!,
                    year: _selectedYear!,
                    calendarData: calendarData),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}
