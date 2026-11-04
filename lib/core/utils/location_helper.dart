import 'dart:math' as math;

class LocationHelper {
  /// Calculates Haversine distance in kilometers between two GPS coordinates
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Formats distance into a clean user-friendly label (e.g. "450 m away" or "2.3 km away")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final int meters = (distanceKm * 1000).round();
      return '$meters m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km away';
    }
  }

  /// Estimates walking or short transit travel time in minutes
  static String estimateTravelTime(double distanceKm) {
    // Average walking speed ~ 4.5 km/h
    final int walkingMinutes = ((distanceKm / 4.5) * 60).round();
    if (walkingMinutes < 2) {
      return '1-2 mins walk';
    } else if (walkingMinutes <= 20) {
      return '$walkingMinutes mins walk';
    } else {
      // Bike/cab estimate ~ 20 km/h in city traffic
      final int drivingMinutes = ((distanceKm / 20.0) * 60).round();
      return '${math.max(5, drivingMinutes)} mins by cab/bike';
    }
  }

  /// Generates direct Google Maps Navigation URL for one-tap turn-by-turn navigation
  static String getGoogleMapsNavigationUrl({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
  }) {
    final query = Uri.encodeComponent(
      destinationLabel != null && destinationLabel.isNotEmpty
          ? '$destinationLat,$destinationLng ($destinationLabel)'
          : '$destinationLat,$destinationLng',
    );
    return 'https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=walking';
  }
}
