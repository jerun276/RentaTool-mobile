import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Geo-location wrapper ensuring fail-safe GPS retrieval for Handover logging.
class LocationService {
  // Default coordinates: Colombo, Western Province, Sri Lanka
  static const double defaultLatitude = 6.9271;
  static const double defaultLongitude = 79.8612;
  static const String defaultCity = 'Colombo';

  /// Determines current device position with permission checks and safe fallbacks.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permission was denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Location permission is denied forever.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }

  /// Calculates straight-line distance in kilometers between two points.
  double distanceInKm(double startLat, double startLng, double endLat, double endLng) {
    final meters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return meters / 1000.0;
  }
}
