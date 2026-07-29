import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;
  LocationResult(this.latitude, this.longitude, {this.address});
}

/// Thin wrapper around geolocator: handles permission requests and gives a
/// simple success/failure result instead of throwing raw exceptions the UI
/// would need to interpret.
class LocationService {
  /// Returns the device's current GPS position, or null if location
  /// services are off or permission was denied. Callers should show a
  /// friendly message rather than assume this always succeeds.
  static Future<LocationResult?> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      // High-accuracy GPS fix timed out (common indoors/first use) — try
      // once more with a lower accuracy target, which resolves much faster
      // using network/cell location instead of waiting for a GPS lock.
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        return null;
      }
    }
    final address = await reverseGeocode(position.latitude, position.longitude);
    return LocationResult(position.latitude, position.longitude, address: address);
  }

  /// Converts GPS coordinates into a human-readable address, e.g.
  /// "12 MG Road, Bengaluru, Karnataka". Returns null if it can't resolve
  /// one (e.g. no network, remote area) — callers should fall back to
  /// letting the person type their address manually in that case.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality, p.administrativeArea, p.postalCode]
          .where((s) => s != null && s.trim().isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Straight-line distance in kilometers between two points.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}
