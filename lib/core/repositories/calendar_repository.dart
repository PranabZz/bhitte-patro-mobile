import 'package:hive/hive.dart';

class CalendarRepository {
  final Box _configBox;
  final Box _calendarBox;

  CalendarRepository(this._configBox, this._calendarBox);

  Future<void> updateCalendar(Map<String, dynamic> data, String version) async {
    await _calendarBox.put('data', data);
    await _configBox.put('version', version);
  }

  Map<String, dynamic>? getCalendarData() {
    return _calendarBox.get('data') as Map<String, dynamic>?;
  }

  String? getVersion() {
    return _configBox.get('version') as String?;
  }
}
