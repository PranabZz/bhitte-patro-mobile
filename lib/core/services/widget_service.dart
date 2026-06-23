import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';

class WidgetService {
  static const MethodChannel _platform = MethodChannel('group.bhittepatroapp');

  /// Updates the widget data with the current Nepali date, total days in the month,
  /// and the starting weekday of the month, along with the full JSON calendar lists.
  static Future<void> updateWidgetData(Map<String, dynamic> calendarData) async {
    try {
      final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>?;
      if (monthDaysData == null) {
        debugPrint("WidgetService: monthDaysData is null");
        return;
      }

      final now = DateTime.now();
      final todayBs = NepaliDateConverter.convertToBs(now, monthDaysData);

      final year = todayBs['year']!;
      final month = todayBs['month']!;
      final day = todayBs['day']!;

      final months = monthDaysData[year.toString()] as List<dynamic>;
      final daysInMonth = months[month - 1] as int;

      // Calculate the starting weekday of the month
      int daysSinceRef = 0;
      for (int y = 2060; y < year; y++) {
        daysSinceRef += (monthDaysData[y.toString()] as List<dynamic>)
            .reduce((a, b) => a + b) as int;
      }
      for (int m = 0; m < month - 1; m++) {
        daysSinceRef += months[m] as int;
      }

      // Map weekday representation (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
      final flutterStartingWeekday = (DateTime.monday + daysSinceRef) % 7;
      final swiftStartingWeekday = (flutterStartingWeekday + 1) % 7;

      // Base payload fields
      final Map<String, dynamic> platformPayload = {
        "syncAdYear": now.year,
        "syncAdMonth": now.month,
        "syncAdDay": now.day,
        "syncBsYear": year,
        "syncBsMonth": month,
        "syncBsDay": day,
        "daysInMonth": daysInMonth,
        "firstDayWeekday": swiftStartingWeekday,
        "monthDaysData": jsonEncode(monthDaysData),
        "holidays": jsonEncode(calendarData['holidays'] ?? {}),
      };

      // Add surrounding date blocks for off-bounds transitions
      for (int offset = -2; offset <= 5; offset++) {
        if (offset == 0) continue;

        final targetAd = now.add(Duration(days: offset));
        final targetBs = NepaliDateConverter.convertToBs(targetAd, monthDaysData);

        final tYear = targetBs['year']!;
        final tMonth = targetBs['month']!;
        final tDay = targetBs['day']!;

        final tYearData = monthDaysData[tYear.toString()] as List<dynamic>?;
        if (tYearData != null) {
          final tTotalDays = tYearData[tMonth - 1] as int;

          int tDaysSinceRef = 0;
          for (int y = 2060; y < tYear; y++) {
            final yData = monthDaysData[y.toString()] as List<dynamic>?;
            if (yData != null) {
              tDaysSinceRef += yData.fold<int>(
                0,
                (sum, item) => sum + (item as int),
              );
            }
          }
          for (int m = 0; m < tMonth - 1; m++) {
            tDaysSinceRef += tYearData[m] as int;
          }

          final tFlutterWeek = (DateTime.monday + tDaysSinceRef) % 7;
          final tSwiftWeek = (tFlutterWeek + 1) % 7;

          platformPayload["targetBsDay_$offset"] = tDay;
          platformPayload["targetBsMonth_$offset"] = tMonth;
          platformPayload["targetBsYear_$offset"] = tYear;
          platformPayload["targetDaysInMonth_$offset"] = tTotalDays;
          platformPayload["targetFirstWeekday_$offset"] = tSwiftWeek;
        }
      }

      // Invoke platforms directly to sync widget memory buffers
      if (!kIsWeb) {
        if (Platform.isIOS) {
          await _platform.invokeMethod('updateCalendarWidget', platformPayload);
        } else if (Platform.isAndroid) {
          await _platform.invokeMethod('updateAndroidWidget', platformPayload);
        }
      }

      debugPrint("WidgetService: Successfully updated widgets. BS: $year-$month-$day");
    } catch (e) {
      debugPrint("WidgetService: Error updating widget data: $e");
    }
  }
}
