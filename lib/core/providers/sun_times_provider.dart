import 'package:bhitte_patro/core/utils/solar_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Holds the calculated sunrise and sunset times for today.
class SunTimes {
  final DateTime sunrise;
  final DateTime sunset;
  const SunTimes({required this.sunrise, required this.sunset});
}

/// Fetches the device's current location (with permission) and returns the
/// [SunTimes] for today using the pure-Dart NOAA solar calculator.
///
/// Falls back to Kathmandu coordinates (27.7172° N, 85.3240° E) if the
/// location permission is denied or unavailable.
final sunTimesProvider = FutureProvider<SunTimes>((ref) async {
  const double fallbackLat = 27.7172;
  const double fallbackLon = 85.3240;
  const double nepaliUtcOffset = 5.75; // UTC +05:45

  double lat = fallbackLat;
  double lon = fallbackLon;

  try {
    // Check / request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // city-level is enough for sun times
          timeLimit: Duration(seconds: 10),
        ),
      );
      lat = position.latitude;
      lon = position.longitude;
    }
  } catch (_) {
    // Silently fall back to Kathmandu on any error
  }

  // Nepal is UTC+05:45 = 5.75 hours; derive from device timezone if possible
  final offsetSeconds = DateTime.now().timeZoneOffset.inSeconds;
  final utcOffset = offsetSeconds / 3600.0;

  final result = SolarCalculator.calculate(
    date: DateTime.now(),
    latitude: lat,
    longitude: lon,
    utcOffsetHours: utcOffset != 0 ? utcOffset : nepaliUtcOffset,
  );

  return SunTimes(sunrise: result.sunrise, sunset: result.sunset);
});
