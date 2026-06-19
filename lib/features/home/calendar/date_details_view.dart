import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/sun_times_provider.dart';
import 'package:bhitte_patro/core/providers/weather_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DateDetailsView extends ConsumerWidget {
  final int day;
  final int month;
  final int year;
  final Map<String, dynamic> calendarData;

  const DateDetailsView({
    super.key,
    required this.day,
    required this.month,
    required this.year,
    required this.calendarData,
  });

  String _toNepaliNumber(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adDate = NepaliDateConverter.convertToAd(
        year, month, day, calendarData['monthDaysData']);

    final now = DateTime.now();
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>;
    final todayBs = NepaliDateConverter.convertToBs(now, monthDaysData);
    final isToday = (day == todayBs['day'] &&
        month == todayBs['month'] &&
        year == todayBs['year']);

    final weatherAsync = ref.watch(weatherProvider);

    final weekDays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final dayOfWeek = weekDays[adDate.weekday % 7];
    final dateTitle = isToday ? "Today" : dayOfWeek;

    final nepaliMonths = [
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
    final enMonths = [
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

    final tithiList = calendarData['tithi']?['$year']?['$month'];
    final tithiNames = [
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
      'पूर्णिमा/औंसी'
    ];

    String tithiText = "";
    if (tithiList != null && tithiList is List && day <= tithiList.length) {
      final tithiId = tithiList[day - 1];
      if (tithiId >= 1 && tithiId <= 15) tithiText = tithiNames[tithiId - 1];
    }

    final holidayList = calendarData['holidays']?['$year']?['$month']?['$day'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateTitle,
              style: AppTypography.boldSubtitle
                  .copyWith(fontSize: 18, color: Colors.grey.shade800)),
          const SizedBox(height: AppSpace.small),
          // Main Date Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.large),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${_toNepaliNumber(day)} ${nepaliMonths[month - 1]} ${_toNepaliNumber(year)}",
                        style: AppTypography.boldTitle.copyWith(
                          color: Colors.white,
                          fontSize: AppFontSize.xxxLarge,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.medium),
                    if (isToday) _buildSunInfo(ref),
                  ],
                ),
                const SizedBox(height: AppSpace.large),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(
                              "${enMonths[adDate.month - 1]} ${adDate.day}, ${adDate.year}"),
                          if (tithiText.isNotEmpty)
                            _buildDetailChip("Tithi: $tithiText"),
                          if (holidayList != null)
                            _buildDetailChip(
                                holidayList is List
                                    ? holidayList.join(", ")
                                    : holidayList.toString(),
                                isHoliday: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.medium),
                    if (isToday)
                      weatherAsync.when(
                        data: (weather) => _buildSunItem(
                            FontAwesomeIcons.temperatureHalf,
                            "${weather.temperature}°C"),
                        loading: () => _buildSunItem(
                            FontAwesomeIcons.temperatureHalf, "..."),
                        error: (e, s) =>
                            _buildSunItem(FontAwesomeIcons.temperatureHalf, "N/A"),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.large),
          // Upcoming Holiday Section
          _buildUpcomingHoliday(calendarData),
        ],
      ),
    );
  }

  Widget _buildSunInfo(WidgetRef ref) {
    final sunAsync = ref.watch(sunTimesProvider);

    // Format a DateTime to "h:mm AM/PM"
    String fmt(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$hour:$min $period';
    }

    final sunriseLabel = sunAsync.when(
      data: (t) => fmt(t.sunrise),
      loading: () => '–:–',
      error: (e, s) => '–:–',
    );
    final sunsetLabel = sunAsync.when(
      data: (t) => fmt(t.sunset),
      loading: () => '–:–',
      error: (e, s) => '–:–',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSunItem(FontAwesomeIcons.sun, sunriseLabel),
        const SizedBox(height: 8),
        _buildSunItem(FontAwesomeIcons.moon, sunsetLabel),
      ],
    );
  }

  Widget _buildSunItem(dynamic icon, String time) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: Colors.white.withOpacity(0.7), size: 14),
        const SizedBox(width: 6),
        Text(
          time,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String text, {bool isHoliday = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isHoliday ? Colors.red.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHoliday ? Colors.red : Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: isHoliday ? Colors.red : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUpcomingHoliday(Map<String, dynamic> calendarData) {
    final holidays = calendarData['holidays'] as Map<String, dynamic>?;
    String upcomingTitle = "No upcoming holidays";
    String upcomingDate = "";
    String daysRemainingText = "";

    if (holidays != null) {
      DateTime currentAd = NepaliDateConverter.convertToAd(
          year, month, day, calendarData['monthDaysData']);
      DateTime limitAd = currentAd.add(const Duration(days: 90));

      bool found = false;

      for (int y = year; y <= year + 1; y++) {
        for (int m = 1; m <= 12; m++) {
          final monthHolidays = holidays['$y']?['$m'] as Map<String, dynamic>?;
          if (monthHolidays != null) {
            for (var d in monthHolidays.keys) {
              int dInt = int.parse(d);
              DateTime holidayAd = NepaliDateConverter.convertToAd(
                  y, m, dInt, calendarData['monthDaysData']);

              if (holidayAd.isAfter(currentAd) && holidayAd.isBefore(limitAd)) {
                final holidayValue = monthHolidays[d];
                if (holidayValue is List) {
                  upcomingTitle = holidayValue.join(", ");
                } else {
                  upcomingTitle = holidayValue.toString();
                }
                upcomingDate =
                    "${_toNepaliNumber(dInt)} ${['', 'बैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 'पुस', 'माघ', 'फागुन', 'चैत'][m]}";
                
                final daysRemaining = holidayAd.difference(currentAd).inDays;
                daysRemainingText = daysRemaining == 1 ? "Tomorrow" : "In $daysRemaining days";
                
                found = true;
                break;
              }
            }
          }
          if (found) break;
        }
        if (found) break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  upcomingTitle,
                  style: AppTypography.boldBody.copyWith(
                    color: AppColors.black,
                    fontSize: 15,
                  ),
                ),
              ),
              if (daysRemainingText.isNotEmpty)
                Text(
                  daysRemainingText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (upcomingDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              upcomingDate,
              style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

