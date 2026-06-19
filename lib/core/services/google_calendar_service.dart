import 'package:bhitte_patro/core/services/auth_service.dart';
import 'package:bhitte_patro/core/utils/logger.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarService {
  final AuthService _authService;
  final _logger = AppLogger();

  GoogleCalendarService(this._authService);

  Future<List<calendar.Event>> getEvents(DateTime start, DateTime end) async {
    try {
      final timeMin = start.toUtc();
      final timeMax = end.toUtc();
      
      _logger.i("📅 GoogleCalendarService: Starting fetch request.");
      _logger.d("   Range: ${timeMin.toIso8601String()} to ${timeMax.toIso8601String()}");
      
      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        _logger.w("❌ GoogleCalendarService: Failed to get authenticated client. User might not be logged in or authorized.");
        return [];
      }

      final calendarApi = calendar.CalendarApi(client);
      _logger.d("📡 GoogleCalendarService: Calling Google Calendar API v3 (events.list)...");
      
      final events = await calendarApi.events.list(
        'primary',
        timeMin: timeMin,
        timeMax: timeMax,
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      final items = events.items ?? [];
      _logger.i("✅ GoogleCalendarService: API call successful. Found ${items.length} events.");
      
      for (var i = 0; i < items.length; i++) {
        final event = items[i];
        _logger.d("   [$i] Event: ${event.summary} | Start: ${event.start?.dateTime ?? event.start?.date}");
      }

      return items;
    } catch (e, stackTrace) {
      _logger.e("🚨 GoogleCalendarService: Critical error during fetch", e, stackTrace);
      rethrow;
    }
  }

  Future<void> createEvent(String title, String description, DateTime startTime, DateTime endTime) async {
    // ... existing implementation
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      _logger.i("🗑️ GoogleCalendarService: Deleting event '$eventId'...");
      
      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        _logger.w("❌ GoogleCalendarService: Failed to get authenticated client to delete event.");
        return;
      }

      final calendarApi = calendar.CalendarApi(client);
      await calendarApi.events.delete('primary', eventId);
      _logger.i("✅ GoogleCalendarService: Event deleted successfully.");
    } catch (e, stackTrace) {
      _logger.e("🚨 GoogleCalendarService: Critical error during deletion", e, stackTrace);
      rethrow;
    }
  }
}
