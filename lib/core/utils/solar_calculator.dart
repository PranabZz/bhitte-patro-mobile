import 'dart:math';

/// Pure-Dart implementation of the NOAA solar algorithm.
/// Calculates sunrise and sunset times for a given date and location.
/// Returns times in local time (UTC + [utcOffsetHours]).
class SolarCalculator {
  /// Returns sunrise and sunset as [DateTime] in **local time**.
  ///
  /// [date]           – the calendar date (year/month/day used; time ignored)
  /// [latitude]       – decimal degrees, positive = North
  /// [longitude]      – decimal degrees, positive = East
  /// [utcOffsetHours] – e.g. 5.75 for Nepal (UTC+05:45)
  static ({DateTime sunrise, DateTime sunset}) calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double utcOffsetHours,
  }) {
    final jd = _toJulianDay(date.year, date.month, date.day);
    final sunrise = _sunriseUTC(jd, latitude, longitude);
    final sunset = _sunsetUTC(jd, latitude, longitude);

    DateTime toDateTime(double minutesUTC) {
      final totalMinutes = minutesUTC + utcOffsetHours * 60;
      final h = (totalMinutes ~/ 60) % 24;
      final m = (totalMinutes % 60).round();
      return DateTime(date.year, date.month, date.day, h, m);
    }

    return (sunrise: toDateTime(sunrise), sunset: toDateTime(sunset));
  }

  // ── Julian Day ──────────────────────────────────────────────────────────────
  static double _toJulianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  // ── Core NOAA helpers ────────────────────────────────────────────────────────
  static double _deg2rad(double d) => d * pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / pi;

  static double _geomMeanLongSun(double t) {
    double l = 280.46646 + t * (36000.76983 + t * 0.0003032);
    return l % 360;
  }

  static double _geomMeanAnomalySun(double t) {
    return 357.52911 + t * (35999.05029 - 0.0001537 * t);
  }

  static double _eccentricityEarthOrbit(double t) {
    return 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  }

  static double _sunEqOfCenter(double t) {
    final m = _deg2rad(_geomMeanAnomalySun(t));
    return sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        sin(2 * m) * (0.019993 - 0.000101 * t) +
        sin(3 * m) * 0.000289;
  }

  static double _sunTrueLong(double t) {
    return _geomMeanLongSun(t) + _sunEqOfCenter(t);
  }

  static double _sunApparentLong(double t) {
    final o = _sunTrueLong(t) - 0.00569 - 0.00478 * sin(_deg2rad(125.04 - 1934.136 * t));
    return o;
  }

  static double _meanObliquityOfEcliptic(double t) {
    return 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  }

  static double _obliquityCorrection(double t) {
    return _meanObliquityOfEcliptic(t) + 0.00256 * cos(_deg2rad(125.04 - 1934.136 * t));
  }

  static double _sunDeclination(double t) {
    final e = _deg2rad(_obliquityCorrection(t));
    final l = _deg2rad(_sunApparentLong(t));
    return _rad2deg(asin(sin(e) * sin(l)));
  }

  static double _equationOfTime(double t) {
    final e = _eccentricityEarthOrbit(t);
    final eps = _deg2rad(_obliquityCorrection(t));
    final l = _deg2rad(_geomMeanLongSun(t));
    final m = _deg2rad(_geomMeanAnomalySun(t));
    final y = tan(eps / 2) * tan(eps / 2);
    return _rad2deg(
          y * sin(2 * l) -
              2 * e * sin(m) +
              4 * e * y * sin(m) * cos(2 * l) -
              0.5 * y * y * sin(4 * l) -
              1.25 * e * e * sin(2 * m),
        ) *
        4; // minutes
  }

  static double _hourAngleSunrise(double lat, double solarDec) {
    final latRad = _deg2rad(lat);
    final sdRad = _deg2rad(solarDec);
    return _rad2deg(
      acos(cos(_deg2rad(90.833)) / (cos(latRad) * cos(sdRad)) -
          tan(latRad) * tan(sdRad)),
    );
  }

  static double _jCentury(double jd) => (jd - 2451545.0) / 36525.0;

  /// Returns minutes past midnight UTC for sunrise on [jd].
  static double _sunriseUTC(double jd, double lat, double lon) {
    final t = _jCentury(jd);
    final eqTime = _equationOfTime(t);
    final solarDec = _sunDeclination(t);
    final hourAngle = _hourAngleSunrise(lat, solarDec);
    final delta = lon + hourAngle;
    return 720 - (4 * delta) - eqTime;
  }

  /// Returns minutes past midnight UTC for sunset on [jd].
  static double _sunsetUTC(double jd, double lat, double lon) {
    final t = _jCentury(jd);
    final eqTime = _equationOfTime(t);
    final solarDec = _sunDeclination(t);
    final hourAngle = _hourAngleSunrise(lat, solarDec);
    final delta = lon - hourAngle;
    return 720 - (4 * delta) - eqTime;
  }
}
