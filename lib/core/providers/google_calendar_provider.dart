import 'package:bhitte_patro/core/providers/auth_provider.dart';
import 'package:bhitte_patro/core/services/google_calendar_service.dart';
import 'package:bhitte_patro/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

final googleCalendarServiceProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  return GoogleCalendarService(authService);
});

typedef CalendarRange = ({DateTime start, DateTime end});

final googleCalendarEventsProvider = FutureProvider.family<List<calendar.Event>, CalendarRange>((ref, range) async {
  final service = ref.watch(googleCalendarServiceProvider);
  final logger = AppLogger();
  
  logger.d("🚀 googleCalendarEventsProvider: Triggered for range ${range.start} to ${range.end}");
  
  try {
    final events = await service.getEvents(range.start, range.end);
    logger.i("✅ googleCalendarEventsProvider: Completed with ${events.length} events.");
    return events;
  } catch (e) {
    logger.e("❌ googleCalendarEventsProvider: Failed", e);
    rethrow;
  }
});