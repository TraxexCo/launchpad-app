import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/services/location_service.dart';

void main() {
  test('distance calculation returns zero for the same point', () {
    final distance = LocationService.distanceKm(
      fromLatitude: 14.5995,
      fromLongitude: 120.9842,
      toLatitude: 14.5995,
      toLongitude: 120.9842,
    );
    expect(distance, closeTo(0, 0.0001));
  });

  test('distance calculation is realistic across Metro Manila', () {
    final distance = LocationService.distanceKm(
      fromLatitude: 14.5995,
      fromLongitude: 120.9842,
      toLatitude: 14.6760,
      toLongitude: 121.0437,
    );
    expect(distance, inInclusiveRange(9, 12));
  });
}
