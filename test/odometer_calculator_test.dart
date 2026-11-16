import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_log/features/odometer/domain/odometer_calculator.dart';

void main() {
  group('calculateEstimate', () {
    test('calculates correctly for 10 days', () {
      final result = OdometerCalculator.calculateEstimate(
        lastOdometer: 10000,
        lastReadingDate: DateTime(2026, 11, 1),
        dailyDistanceKm: 20.0,
        currentDate: DateTime(2026, 11, 11),
      );
      // 10 days * 20km = 200. 10000 + 200 = 10200.
      expect(result.estimatedKm, 10200);
      expect(result.isStale, false);
    });

    test('marks as stale after 90 days', () {
      final result = OdometerCalculator.calculateEstimate(
        lastOdometer: 10000,
        lastReadingDate: DateTime(2026, 1, 1),
        dailyDistanceKm: 20.0,
        currentDate: DateTime(2026, 4, 5), // 94 days later
      );
      expect(result.estimatedKm, 10000); // Should return last known, not estimate
      expect(result.isStale, true);
    });
  });

  group('calculateDailyDistance', () {
    test('calculates average between two readings', () {
      final readings = [
        OdometerReadingData(valueKm: 1000, date: DateTime(2026, 11, 1)),
        OdometerReadingData(valueKm: 1100, date: DateTime(2026, 11, 6)), // 5 days later
      ];
      // Difference is 100km over 5 days = 20.0
      final result = OdometerCalculator.calculateDailyDistance(readings);
      expect(result, 20.0);
    });

    test('returns null if less than 2 readings', () {
      final readings = [
        OdometerReadingData(valueKm: 1000, date: DateTime(2026, 11, 1)),
      ];
      expect(OdometerCalculator.calculateDailyDistance(readings), isNull);
    });
  });
}