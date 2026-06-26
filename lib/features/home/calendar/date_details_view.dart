import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/sun_times_provider.dart';
import 'package:bhitte_patro/core/providers/weather_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const List<String> _nepaliMonths = [
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

  static const List<String> _weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> _enMonths = [
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

  static const List<String> _tithiNames = [
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

  String _toNepaliNumber(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>;

    final adDate = NepaliDateConverter.convertToAd(
      year,
      month,
      day,
      monthDaysData,
    );
    final todayBs = NepaliDateConverter.convertToBs(
      DateTime.now(),
      monthDaysData,
    );

    final isToday =
        (day == todayBs['day'] &&
        month == todayBs['month'] &&
        year == todayBs['year']);

    final weatherAsync = ref.watch(weatherProvider);
    final sunAsync = ref.watch(sunTimesProvider);

    final dayOfWeek = _weekDays[adDate.weekday % 7];
    final dateTitle = isToday ? "Today" : dayOfWeek.toUpperCase();

    String tithiText = "";
    final tithiList = calendarData['tithi']?['$year']?['$month'];
    if (tithiList is List && day <= tithiList.length) {
      final tithiId = tithiList[day - 1];
      if (tithiId >= 1 && tithiId <= 15) {
        tithiText = _tithiNames[tithiId - 1];
      }
    }

    final holidayList = calendarData['holidays']?['$year']?['$month']?['$day'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Clean Card Layout
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.circular(4), // Flat, sharp design feel
          ),
          child: SizedBox(
            height: 240,
            child: Image.asset(
              'assets/month/$month.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          // child: IntrinsicHeight(
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.stretch,
          //     children: [
          //       // Left Side Frame
          //       SizedBox(
          //         width: 160,
          //         child: Image.asset(
          //           'assets/month/$month.jpg',
          //           fit: BoxFit.cover,
          //           errorBuilder: (context, error, stackTrace) =>
          //               Container(color: Colors.white.withOpacity(0.05)),
          //         ),
          //       ),

          //       // Right Side Information Panel
          //       Expanded(
          //         child: Padding(
          //           padding: const EdgeInsets.all(20.0),
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: [
          //               Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     _toNepaliNumber(day),
          //                     style: AppTypography.boldTitle.copyWith(
          //                       color: Colors.white,
          //                       fontSize: 46,
          //                       fontWeight:
          //                           FontWeight.w300, // Clean typography
          //                       height: 1.0,
          //                     ),
          //                   ),
          //                   const SizedBox(height: 2),
          //                   Text(
          //                     "${_nepaliMonths[month - 1]} ${_toNepaliNumber(year)}",
          //                     style: AppTypography.caption.copyWith(
          //                       color: Colors.white.withOpacity(0.7),
          //                       fontSize: 16,
          //                       fontWeight: FontWeight.w400,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 24),

          //               // Text-driven data rows (No icon pill shapes)
          //               Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   _buildTextRow(
          //                     label: "English Date",
          //                     value:
          //                         "${_enMonths[adDate.month - 1]} ${adDate.day}, ${adDate.year}",
          //                   ),
          //                   if (tithiText.isNotEmpty) ...[
          //                     const SizedBox(height: 6),
          //                     _buildTextRow(label: "Tithi", value: tithiText),
          //                   ],
          //                   if (holidayList != null) ...[
          //                     const SizedBox(height: 6),
          //                     _buildTextRow(
          //                       label: "Holiday",
          //                       value: holidayList is List
          //                           ? holidayList.join(", ")
          //                           : holidayList.toString(),
          //                       isImportant: true,
          //                     ),
          //                   ],
          //                   if (isToday) ...[
          //                     const SizedBox(height: 6),
          //                     weatherAsync.when(
          //                       data: (w) => _buildTextRow(
          //                         label: "Weather",
          //                         value: "${w.temperature}°C",
          //                       ),
          //                       loading: () => _buildTextRow(
          //                         label: "Weather",
          //                         value: "Loading...",
          //                       ),
          //                       error: (_, __) => const SizedBox.shrink(),
          //                     ),
          //                   ],
          //                 ],
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ),

        // Secondary Details block if it is today
        // if (isToday) ...[
        //   const SizedBox(height: 12),
        //   _buildSunMetricsTimeline(sunAsync),
        // ],

        // Next Holiday Block
        // _buildUpcomingHoliday(calendarData, adDate, monthDaysData),
      ],
    );
  }

  Widget _buildTextRow({
    required String label,
    required String value,
    bool isImportant = false,
  }) {
    return RichText(
      text: TextSpan(
        style: AppTypography.caption.copyWith(fontSize: 13),
        children: [
          TextSpan(
            text: "$label: ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: isImportant
                  ? Colors.red.shade300
                  : Colors.white.withOpacity(0.9),
              fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunMetricsTimeline(AsyncValue<dynamic> sunAsync) {
    final String sunrise = sunAsync.when(
      data: (t) => _formatTime(t.sunrise),
      loading: () => '–:–',
      error: (_, __) => '–:–',
    );
    final String sunset = sunAsync.when(
      data: (t) => _formatTime(t.sunset),
      loading: () => '–:–',
      error: (_, __) => '–:–',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                "Sunrise: $sunrise",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Icon(
                Icons.nights_stay_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                "Sunset: $sunset",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Widget _buildUpcomingHoliday(
    Map<String, dynamic> calendarData,
    DateTime currentAd,
    Map<String, dynamic> monthDaysData,
  ) {
    final holidays = calendarData['holidays'] as Map<String, dynamic>?;

    String title = "No upcoming holidays";
    String date = "";
    String remaining = "";

    if (holidays != null) {
      final limit = currentAd.add(const Duration(days: 90));
      bool found = false;

      for (int y = year; y <= year + 1; y++) {
        for (int m = 1; m <= 12; m++) {
          final monthData = holidays['$y']?['$m'];

          if (monthData is Map) {
            final sortedKeys = monthData.keys.toList()
              ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

            for (var d in sortedKeys) {
              final dInt = int.tryParse(d);
              if (dInt == null) continue;

              final ad = NepaliDateConverter.convertToAd(
                y,
                m,
                dInt,
                monthDaysData,
              );

              if (ad.isAfter(currentAd) && ad.isBefore(limit)) {
                final val = monthData[d];
                title = val is List ? val.join(", ") : val.toString();
                date = "${_toNepaliNumber(dInt)} ${_nepaliMonths[m - 1]}";

                final diff = ad.difference(currentAd).inDays;
                remaining = diff == 1 ? "Tomorrow" : "In $diff days";

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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Holiday", style: AppTypography.caption),
              if (remaining.isNotEmpty)
                Text(
                  remaining.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.boldBody.copyWith(
              fontSize: 16,
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              date,
              style: AppTypography.caption.copyWith(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
