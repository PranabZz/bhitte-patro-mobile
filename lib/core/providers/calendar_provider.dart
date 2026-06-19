import 'package:bhitte_patro/core/repositories/calendar_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

final calendarRepositoryProvider = Provider((ref) {
  return CalendarRepository(Hive.box('config_box'), Hive.box('calendar_box'));
});

final calendarProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    // Load from local asset
    final String jsonString = await rootBundle.loadString('assets/calendar.json');
    debugPrint("CalendarProvider: Loaded JSON string length: ${jsonString.length}");
    
    final Map<String, dynamic> data = jsonDecode(jsonString);
    debugPrint("CalendarProvider: Decoded map keys: ${data.keys}");
    
    return data;
  } catch (e) {
    debugPrint("CalendarProvider: Error loading/parsing asset: $e");
    // Fallback to local cache
    final repo = ref.read(calendarRepositoryProvider);
    return repo.getCalendarData() ?? {};
  }
});
