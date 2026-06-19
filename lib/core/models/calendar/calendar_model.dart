import 'package:hive/hive.dart';

part 'calendar_model.g.dart';

@HiveType(typeId: 0)
class CalendarData extends HiveObject {
  @HiveField(0)
  final Map<String, dynamic> monthDaysData;

  @HiveField(1)
  final Map<String, dynamic> tithi;

  @HiveField(2)
  final Map<String, dynamic> holidays;

  CalendarData({
    required this.monthDaysData,
    required this.tithi,
    required this.holidays,
  });

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    return CalendarData(
      monthDaysData: json['monthDaysData'] as Map<String, dynamic>,
      tithi: json['tithi'] as Map<String, dynamic>,
      holidays: json['holidays'] as Map<String, dynamic>,
    );
  }
}

@HiveType(typeId: 1)
class VersionInfo extends HiveObject {
  @HiveField(0)
  final String version;

  VersionInfo({required this.version});

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(version: json['version'] as String);
  }
}
