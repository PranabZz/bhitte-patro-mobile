import 'dart:async';
import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/providers/selected_date_provider.dart';
import 'package:bhitte_patro/core/providers/weather_provider.dart';
import 'package:bhitte_patro/core/providers/sun_times_provider.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:bhitte_patro/core/services/widget_service.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  int _viewedMonthIndex = 0; // 0-indexed for Baisakh
  int _viewedYear = 2080;

  // Selected state (what is shown in the details panel below the calendar)
  int? _selectedDay;
  int? _selectedMonth; // 1-indexed
  int? _selectedYear;

  bool _isInitialized = false;
  Timer? _revertTimer;
  int _navDirection = 1; // +1 forward, -1 backward, 0 jump

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
    'चैत',
  ];

  final List<String> _weekDays = [
    'आइ',
    'सोम',
    'मंगल',
    'बुध',
    'बिही',
    'शुक्र',
    'शनि',
  ];

  final List<String> _tithiNames = [
    'प्रतिपदा',
    'द्वितीया',
    'तृतीया',
    'चतुर्थी',
    'पञ्चमी',
    'षष्ठी',
    'सप्तमी',
    'अष्टमी',
    'नवमी',
    'दशमी',
    'एकादशी',
    'द्वादशी',
    'त्रयोदशी',
    'चतुर्दशी',
    'पूर्णिमा/औंसी',
  ];

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  String _toNepaliNumber(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join();
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
    final monthDaysData =
        calendarData['monthDaysData'] as Map<String, dynamic>?;
    if (monthDaysData == null) return;

    final todayAd = DateTime.now();
    final todayBs = NepaliDateConverter.convertToBs(todayAd, monthDaysData);

    setState(() {
      _navDirection = 0;
      _viewedYear = todayBs['year']!;
      _viewedMonthIndex = todayBs['month']! - 1;

      _selectedYear = todayBs['year']!;
      _selectedMonth = todayBs['month']!;
      _selectedDay = todayBs['day']!;
    });
    ref
        .read(selectedDateProvider.notifier)
        .setSelectedDate(
          SelectedDate(
            day: _selectedDay!,
            month: _selectedMonth!,
            year: _selectedYear!,
          ),
        );
  }

  void _initializeToday(Map<String, dynamic> calendarData) {
    if (_isInitialized) return;

    final monthDaysData =
        calendarData['monthDaysData'] as Map<String, dynamic>?;
    if (monthDaysData == null) return;

    final todayAd = DateTime.now();
    final todayBs = NepaliDateConverter.convertToBs(todayAd, monthDaysData);

    _isInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetService.updateWidgetData(calendarData);
      setState(() {
        _viewedYear = todayBs['year']!;
        _viewedMonthIndex = todayBs['month']! - 1;
        _selectedYear = todayBs['year']!;
        _selectedMonth = todayBs['month']!;
        _selectedDay = todayBs['day']!;
      });
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
      'Dec',
    ];
    return months[month - 1];
  }

  String _getNepaliWeekdayName(int englishWeekday) {
    const names = {
      DateTime.sunday: 'आइतबार',
      DateTime.monday: 'सोमबार',
      DateTime.tuesday: 'मंगलबार',
      DateTime.wednesday: 'बुधबार',
      DateTime.thursday: 'बिहीबार',
      DateTime.friday: 'शुक्रबार',
      DateTime.saturday: 'शनिबार',
    };
    return names[englishWeekday] ?? '';
  }

  Map<String, String> _getMoonPhaseInfo(DateTime date) {
    final DateTime refNewMoon = DateTime(2000, 1, 6);
    const double synodicMonth = 29.530588853;
    final int diffInDays = date.difference(refNewMoon).inDays;
    final double age = diffInDays % synodicMonth;

    if (age < 1.84 || age > 27.68) {
      return {'name': 'New Moon (औंसी)', 'icon': '🌑'};
    } else if (age < 5.53) {
      return {'name': 'Waxing Crescent', 'icon': '🌒'};
    } else if (age < 9.22) {
      return {'name': 'First Quarter', 'icon': '🌓'};
    } else if (age < 12.91) {
      return {'name': 'Waxing Gibbous', 'icon': '🌔'};
    } else if (age < 16.61) {
      return {'name': 'Full Moon (पूर्णिमा)', 'icon': '🌕'};
    } else if (age < 20.30) {
      return {'name': 'Waning Gibbous', 'icon': '🌖'};
    } else if (age < 23.99) {
      return {'name': 'Third Quarter', 'icon': '🌗'};
    } else {
      return {'name': 'Waning Crescent', 'icon': '🌘'};
    }
  }

  String _formatTime24(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  void _goToPreviousMonth(Map<String, dynamic> calendarData) {
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>;
    setState(() {
      _navDirection = -1;
      if (_viewedMonthIndex > 0) {
        _viewedMonthIndex--;
      } else {
        _viewedMonthIndex = 11;
        _viewedYear--;
      }
      _updateSelectedDayOnMonthChange(monthDaysData);
      _startRevertTimer(calendarData);
    });
  }

  void _goToNextMonth(Map<String, dynamic> calendarData) {
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>;
    setState(() {
      _navDirection = 1;
      if (_viewedMonthIndex < 11) {
        _viewedMonthIndex++;
      } else {
        _viewedMonthIndex = 0;
        _viewedYear++;
      }
      _updateSelectedDayOnMonthChange(monthDaysData);
      _startRevertTimer(calendarData);
    });
  }

  void _updateSelectedDayOnMonthChange(Map<String, dynamic> monthDaysData) {
    if (!monthDaysData.containsKey(_viewedYear.toString())) return;
    final months = monthDaysData[_viewedYear.toString()] as List<dynamic>;
    final daysInNewMonth = months[_viewedMonthIndex] as int;

    if (_selectedDay != null) {
      if (_selectedDay! > daysInNewMonth) {
        _selectedDay = daysInNewMonth;
      }
      _selectedMonth = _viewedMonthIndex + 1;
      _selectedYear = _viewedYear;

      ref
          .read(selectedDateProvider.notifier)
          .setSelectedDate(
            SelectedDate(
              day: _selectedDay!,
              month: _selectedMonth!,
              year: _selectedYear!,
            ),
          );
    }
  }

  String _getViewedEnglishMonthRange(
    Map<String, dynamic> monthDaysData,
    int daysInMonth,
  ) {
    final startAd = NepaliDateConverter.convertToAd(
      _viewedYear,
      _viewedMonthIndex + 1,
      1,
      monthDaysData,
    );
    final endAd = NepaliDateConverter.convertToAd(
      _viewedYear,
      _viewedMonthIndex + 1,
      daysInMonth,
      monthDaysData,
    );

    final startMonthStr = _monthNameEn(startAd.month);
    final endMonthStr = _monthNameEn(endAd.month);

    if (startAd.year == endAd.year) {
      return "$startMonthStr/$endMonthStr ${endAd.year}";
    } else {
      return "$startMonthStr ${startAd.year} / $endMonthStr ${endAd.year}";
    }
  }

  void _showMonthYearBottomSheet(
    BuildContext context,
    Map<String, dynamic> calendarData,
  ) {
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>;
    final years = monthDaysData.keys.map((e) => int.parse(e)).toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int tempYear = _viewedYear;
        int tempMonthIndex = _viewedMonthIndex;

        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpace.medium,
                  right: AppSpace.medium,
                  top: AppSpace.medium,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      AppSpace.medium,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpace.medium),
                      const Text(
                        "Select Month & Year",
                        style: AppTypography.boldSubtitle,
                      ),
                      const SizedBox(height: AppSpace.medium),

                      const Text("Year", style: AppTypography.boldBody),
                      const SizedBox(height: AppSpace.small),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: years.length,
                          itemBuilder: (context, index) {
                            final y = years[index];
                            final isSelected = y == tempYear;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(_toNepaliNumber(y)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setBottomSheetState(() {
                                      tempYear = y;
                                    });
                                  }
                                },
                                selectedColor: AppColors.darkBlue,
                                backgroundColor: AppColors.grey.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpace.medium),
                      const Divider(color: AppColors.grey, thickness: 0.5),
                      const SizedBox(height: AppSpace.medium),

                      const Text("Month", style: AppTypography.boldBody),
                      const SizedBox(height: AppSpace.small),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.5,
                            ),
                        itemBuilder: (context, index) {
                          final isSelected = index == tempMonthIndex;
                          return InkWell(
                            onTap: () {
                              setBottomSheetState(() {
                                tempMonthIndex = index;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.darkBlue
                                    : AppColors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _nepaliMonths[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpace.large),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.medium),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _viewedYear = tempYear;
                                  _viewedMonthIndex = tempMonthIndex;
                                  _updateSelectedDayOnMonthChange(
                                    monthDaysData,
                                  );
                                  _startRevertTimer(calendarData);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkBlue,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Apply",
                                style: AppTypography.boldBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleChevron({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey.withOpacity(0.1),
        border: Border.all(color: AppColors.grey.withOpacity(0.2), width: 0.5),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 16,
          color: onPressed != null
              ? AppColors.black.withOpacity(0.8)
              : AppColors.grey,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  // Sunrise / sunset two-line text block
  Widget _buildSunRow({required String sunrise, required String sunset}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.wb_twilight_rounded,
              size: 14,
              color: Color(0xFFE8920A),
            ),
            const SizedBox(width: 5),
            Text(
              sunrise,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.nights_stay_rounded,
              size: 14,
              color: Color(0xFF6B7FD4),
            ),
            const SizedBox(width: 5),
            Text(
              sunset,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // A labeled detail row: sublabel above, label below
  Widget _buildDetailRow({
    required String label,
    required String sublabel,
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sublabel,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor ?? AppColors.black,
            height: 1.3,
          ),
        ),
      ],
    );
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
          daysSinceRef +=
              (monthDaysData[y.toString()] as List<dynamic>).reduce(
                    (a, b) => a + b,
                  )
                  as int;
        }
        for (int m = 0; m < _viewedMonthIndex; m++) {
          daysSinceRef += months[m] as int;
        }

        final firstDayWeekday = (DateTime.monday + daysSinceRef) % 7;

        final now = DateTime.now();
        final todayBs = NepaliDateConverter.convertToBs(now, monthDaysData);

        // Check if viewed month/year is outside of actual month/year
        final bool isOutsideToday =
            (_viewedYear != todayBs['year'] ||
            (_viewedMonthIndex + 1) != todayBs['month']);

        // Selected state values
        final selDay = _selectedDay ?? 1;
        final selMonth = _selectedMonth ?? (_viewedMonthIndex + 1);
        final selYear = _selectedYear ?? _viewedYear;

        final adDate = NepaliDateConverter.convertToAd(
          selYear,
          selMonth,
          selDay,
          monthDaysData,
        );

        final isTodayReal =
            (selDay == todayBs['day'] &&
            selMonth == todayBs['month'] &&
            selYear == todayBs['year']);

        // Tithi
        String tithiText = "";
        final tithiList = calendarData['tithi']?['$selYear']?['$selMonth'];
        if (tithiList is List && selDay <= tithiList.length) {
          final tithiId = tithiList[selDay - 1];
          if (tithiId >= 1 && tithiId <= 15) {
            tithiText = _tithiNames[tithiId - 1];
          }
        }

        // Holiday
        final holidayList = holidays?['$selYear']?['$selMonth']?['$selDay'];

        // Weather & Sun times
        final weatherAsync = ref.watch(weatherProvider);
        final sunAsync = ref.watch(sunTimesProvider);

        // Moon Phase info
        final moonInfo = _getMoonPhaseInfo(adDate);

        return Column(
          children: [
            // 1. Month Image at the top, full width
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Image.asset(
                'assets/month/$selMonth.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.darkBlue),
              ),
            ),

            // 2. Calendar Card Container
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(AppSpace.medium),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Left Column: Tappable Month/Year & English Range
                        InkWell(
                          onTap: () =>
                              _showMonthYearBottomSheet(context, calendarData),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Animated month + year title
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, anim) {
                                        final offset =
                                            Tween<Offset>(
                                              begin: Offset(
                                                0,
                                                _navDirection * 0.08,
                                              ),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: anim,
                                                curve: Curves.easeOut,
                                              ),
                                            );
                                        return FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: offset,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "${_nepaliMonths[_viewedMonthIndex]} ${_toNepaliNumber(_viewedYear)}",
                                        key: ValueKey(
                                          '$_viewedMonthIndex-$_viewedYear',
                                        ),
                                        style: AppTypography.boldTitle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: AppColors.black,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Animated English range subtitle
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) {
                                    final offset =
                                        Tween<Offset>(
                                          begin: Offset(
                                            0,
                                            _navDirection * 0.08,
                                          ),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOut,
                                          ),
                                        );
                                    return FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: offset,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _getViewedEnglishMonthRange(
                                      monthDaysData,
                                      daysInMonth,
                                    ),
                                    key: ValueKey(
                                      'sub-$_viewedMonthIndex-$_viewedYear',
                                    ),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Right Controls: Conditional "आज" button & Chevrons
                        if (isOutsideToday) ...[
                          ElevatedButton(
                            onPressed: () => _revertToToday(calendarData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlue,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "आज",
                              style: AppTypography.boldBody,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        _buildCircleChevron(
                          icon: Icons.chevron_left,
                          onPressed: () => _goToPreviousMonth(calendarData),
                        ),
                        const SizedBox(width: 6),
                        _buildCircleChevron(
                          icon: Icons.chevron_right,
                          onPressed: () => _goToNextMonth(calendarData),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.large),

                    // Weekdays row
                    Row(
                      children: _weekDays
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Text(day, style: AppTypography.boldBody),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpace.medium),

                    // GridView of Dates (Full Width)
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daysInMonth + firstDayWeekday,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                      itemBuilder: (context, index) {
                        if (index < firstDayWeekday) return const SizedBox();
                        final day = index - firstDayWeekday + 1;

                        final adDate = NepaliDateConverter.convertToAd(
                          _viewedYear,
                          _viewedMonthIndex + 1,
                          day,
                          monthDaysData,
                        );

                        final isToday =
                            (day == todayBs['day'] &&
                            _viewedMonthIndex == todayBs['month']! - 1 &&
                            _viewedYear == todayBs['year']);

                        final isWeekend = (index % 7 == 0 || index % 7 == 6);
                        final holidayList =
                            holidays?['$_viewedYear']?['${_viewedMonthIndex + 1}']?['$day'];
                        final isHoliday = (holidayList != null) || isWeekend;

                        final isSelected =
                            (day == _selectedDay &&
                            _selectedMonth == _viewedMonthIndex + 1 &&
                            _selectedYear == _viewedYear);

                        Color bgColor = Colors.transparent;
                        Color textColor = isHoliday
                            ? AppColors.red
                            : AppColors.black;
                        Border? border;

                        if (isToday) {
                          bgColor = AppColors.red;
                          textColor = AppColors.white;
                        } else if (isSelected) {
                          bgColor = Colors.transparent;
                          textColor = isHoliday
                              ? AppColors.red
                              : AppColors.darkBlue;
                          border = Border.all(color: textColor, width: 2);
                        }

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
                                .setSelectedDate(
                                  SelectedDate(
                                    day: _selectedDay!,
                                    month: _selectedMonth!,
                                    year: _selectedYear!,
                                  ),
                                );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: border,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    _toNepaliNumber(day),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      color: isToday
                                          ? textColor.withOpacity(0.7)
                                          : AppColors.grey,
                                    ),
                                    child: Text(
                                      "${adDate.day}",
                                      style: AppTypography.caption,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpace.medium),
                    const Divider(color: AppColors.grey, thickness: 0.5),
                    const SizedBox(height: AppSpace.medium),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.medium,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── LEFT COLUMN: Date + English date + Sun times ──
                            SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Big Nepali day number
                                  Text(
                                    _toNepaliNumber(selDay),
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w800,
                                      color: isTodayReal
                                          ? AppColors.red
                                          : AppColors.black,
                                      height: 1.0,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Nepali month + year
                                  Text(
                                    "${_nepaliMonths[selMonth - 1]} ${_toNepaliNumber(selYear)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isTodayReal
                                          ? AppColors.red
                                          : AppColors.grey,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // English date
                                  Text(
                                    "${_monthNameEn(adDate.month)} ${adDate.day}, ${adDate.year}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.grey,
                                      fontWeight: FontWeight.w400,
                                      height: 1.3,
                                    ),
                                  ),

                                  const Spacer(),

                                  // Sunrise / Sunset — only meaningful for today
                                  if (isTodayReal)
                                    sunAsync.when(
                                      data: (sun) => _buildSunRow(
                                        sunrise: _formatTime24(sun.sunrise),
                                        sunset: _formatTime24(sun.sunset),
                                      ),
                                      loading: () => _buildSunRow(
                                        sunrise: '--:--',
                                        sunset: '--:--',
                                      ),
                                      error: (_, __) => const SizedBox.shrink(),
                                    ),
                                ],
                              ),
                            ),

                            // ── HAIRLINE DIVIDER ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: VerticalDivider(
                                color: AppColors.grey.withOpacity(0.3),
                                thickness: 0.5,
                                width: 1,
                              ),
                            ),

                            // ── RIGHT COLUMN: Weekday + details ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Weekday — primary headline
                                  Text(
                                    _getNepaliWeekdayName(adDate.weekday),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                      height: 1.1,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Moon phase
                                  _buildDetailRow(
                                    label:
                                        "${moonInfo['icon']}  ${moonInfo['name']}",
                                    sublabel: 'चन्द्र',
                                  ),

                                  const SizedBox(height: 10),

                                  // Weather
                                  weatherAsync.when(
                                    data: (w) => _buildDetailRow(
                                      label: '${w.temperature}°C',
                                      sublabel: 'मौसम',
                                    ),
                                    loading: () => _buildDetailRow(
                                      label: '--°C',
                                      sublabel: 'मौसम',
                                    ),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),

                                  // Holiday (only if present)
                                  if (holidayList != null) ...[
                                    const SizedBox(height: 10),
                                    _buildDetailRow(
                                      label: holidayList is List
                                          ? (holidayList as List).join(', ')
                                          : holidayList.toString(),
                                      sublabel: 'बिदा',
                                      labelColor: AppColors.red,
                                    ),
                                  ],

                                  // Tithi (only if present)
                                  if (tithiText.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _buildDetailRow(
                                      label: tithiText,
                                      sublabel: 'तिथि',
                                    ),
                                  ],

                                  const Spacer(),

                                  // Globe view — minimal text button
                                  GestureDetector(
                                    onTap: () => context.push(RoutePage.globe),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/satellite-4-svgrepo-com.svg',
                                            width: 16,
                                            height: 16,
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.darkBlue,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          const Text(
                                            'Globe View',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.darkBlue,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: AppColors.darkBlue,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}
