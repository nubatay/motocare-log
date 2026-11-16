// Pure Dart functions for calculating mileage. 
// No UI, no database, no Flutter dependencies. Just math.

/// A simple result object holding both the estimated value and a flag
/// indicating whether the estimate is considered "stale" (too old to trust).
class MileageEstimate {
  final int estimatedKm;
  final bool isStale;

  const MileageEstimate({
    required this.estimatedKm,
    required this.isStale,
  });
}

class OdometerCalculator {
  // Business rule: If there has been no real reading for 90 days,
  // stop trusting the estimate.
  static const int staleAfterDays = 90;

  // Business rule: Daily distance cannot exceed 2000km (sanity check).
  static const double maxDailyDistance = 2000.0;

  /// Calculates the estimated mileage based on the last reading,
  /// the daily distance, and how many days have passed.
  ///
  /// [lastOdometer] The last real odometer reading (e.g., 15000).
  /// [lastReadingDate] The date that reading was taken.
  /// [dailyDistanceKm] The rider's estimated daily distance (e.g., 25.5).
  /// [currentDate] The current date (defaults to DateTime.now()).
  static MileageEstimate calculateEstimate({
    required int lastOdometer,
    required DateTime lastReadingDate,
    required double dailyDistanceKm,
    DateTime? currentDate,
  }) {
    final today = currentDate ?? DateTime.now();
    
    // Calculate the difference in days. 
    // We normalize both dates to midnight to avoid partial-day issues.
    final lastDateMidnight = DateTime(lastReadingDate.year, lastReadingDate.month, lastReadingDate.day);
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    final daysSince = todayMidnight.difference(lastDateMidnight).inDays;

    // If the reading was in the future (somehow), or today, 0 days have passed.
    final safeDays = daysSince < 0 ? 0 : daysSince;

    // If it's older than 90 days, the estimate is stale.
    final stale = safeDays > staleAfterDays;

    // If stale, or if we don't know the daily distance, just return the last known value.
    if (stale || dailyDistanceKm <= 0) {
      return MileageEstimate(
        estimatedKm: lastOdometer,
        isStale: stale,
      );
    }

    // Estimate = last reading + (daily distance * days passed)
    final estimated = lastOdometer + (dailyDistanceKm * safeDays);

    return MileageEstimate(
      estimatedKm: estimated.round(),
      isStale: false,
    );
  }

  /// Recalculates the average daily distance based on recent readings.
  /// 
  /// [readings] A list of real odometer readings. It must contain at least 2 items.
  /// The list should be sorted by date, but this method sorts it just to be safe.
  /// 
  /// Returns the calculated daily distance, or null if there isn't enough data.
  static double? calculateDailyDistance(List<OdometerReadingData> readings) {
    if (readings.length < 2) return null;

    // Sort readings by date (oldest first)
    final sorted = List<OdometerReadingData>.from(readings)
      ..sort((a, b) => a.date.compareTo(b.date));

    final earliest = sorted.first;
    final latest = sorted.last;

    // Difference in days
    final days = latest.date.difference(earliest.date).inDays;

    // If both readings are on the same day, we can't calculate a daily average.
    if (days <= 0) return null;

    // Difference in kilometers
    final kmDifference = latest.valueKm - earliest.valueKm;

    // If the latest reading is somehow lower than the earliest, data is corrupt.
    if (kmDifference < 0) return null;

    final avg = kmDifference / days;

    // Cap it at the maximum sane distance to prevent crazy estimates.
    return avg > maxDailyDistance ? maxDailyDistance : avg;
  }
}

/// A lightweight data class to hold the two things needed for the daily distance math.
class OdometerReadingData {
  final int valueKm;
  final DateTime date;

  const OdometerReadingData({
    required this.valueKm,
    required this.date,
  });
}