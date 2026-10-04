import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Position> determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(
        'Turn on Location Services to scan nearby businesses.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is needed to show nearby businesses.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is blocked. Enable it in your phone settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> nearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
  }) async {
    final rows = await _client.rpc(
      'nearby_businesses',
      params: {
        'user_latitude': latitude,
        'user_longitude': longitude,
        'radius_km': radiusKm,
      },
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> publishBusinessLocation({
    required Position position,
    String? address,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const LocationServiceException('Sign in to update your location.');
    }
    await _client
        .from('business_profiles')
        .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
        })
        .eq('user_id', userId);
  }

  static double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final deltaLat = radians(toLatitude - fromLatitude);
    final deltaLon = radians(toLongitude - fromLongitude);
    final startLat = radians(fromLatitude);
    final endLat = radians(toLatitude);
    final a =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.pow(math.sin(deltaLon / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
