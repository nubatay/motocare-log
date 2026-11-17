// lib/features/services/domain/service_calculator.dart
//
// Pure Dart math for calculating when a service is due.
// No UI or database dependencies.

import '../data/service_repository.dart';

/// Named constants for the "Due Soon" rules.
const int dueSoonKm = 300;
const int dueSoonDays = 14;

enum ServiceStatus {
  noRecord,
  ok,
  dueSoon,
  overdue,
}

class ServiceStatusResult {
  final ServiceStatus status;
  final int? dueKm;
  final DateTime? dueDate;

  const ServiceStatusResult({
    required this.status,
    this.dueKm,
    this.dueDate,
  });
}

class ServiceCalculator {
  /// Calculates the status of a service type based on the latest record,
  /// the current estimated mileage, and today's date.
  static ServiceStatusResult calculateStatus({
    required ServiceRecord? latestRecord,
    required int? intervalKm,
    required int? intervalMonths,
    required int estimatedOdometer,
    DateTime? currentDate,
  }) {
    // 1. If there is no record, we don't guess. The UI will say "Log your first service".
    if (latestRecord == null) {
      return const ServiceStatusResult(status: ServiceStatus.noRecord);
    }

    final today = currentDate ?? DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    int? dueKm;
    DateTime? dueDate;

    // 2. Calculate Due Kilometers
    if (intervalKm != null) {
      dueKm = latestRecord.odometerValue + intervalKm;
    }

    // 3. Calculate Due Date
    if (intervalMonths != null) {
      dueDate = _addMonths(latestRecord.serviceDate, intervalMonths);
    }

    // 4. Determine Overdue
    final isOverdueKm = dueKm != null && estimatedOdometer >= dueKm;
    final isOverdueDate = dueDate != null && !todayMidnight.isBefore(dueDate);

    if (isOverdueKm || isOverdueDate) {
      return ServiceStatusResult(
        status: ServiceStatus.overdue,
        dueKm: dueKm,
        dueDate: dueDate,
      );
    }

    // 5. Determine Due Soon
    final isDueSoonKm = dueKm != null && estimatedOdometer >= (dueKm - dueSoonKm);
    
    // For dates, we check if today is within 14 days of the due date
    final dueSoonThresholdDate = dueDate?.subtract(const Duration(days: dueSoonDays));
    final isDueSoonDate = dueSoonThresholdDate != null && !todayMidnight.isBefore(dueSoonThresholdDate);

    if (isDueSoonKm || isDueSoonDate) {
      return ServiceStatusResult(
        status: ServiceStatus.dueSoon,
        dueKm: dueKm,
        dueDate: dueDate,
      );
    }

    // 6. Otherwise, it's OK
    return ServiceStatusResult(
      status: ServiceStatus.ok,
      dueKm: dueKm,
      dueDate: dueDate,
    );
  }

  /// Pure Dart way to add months to a date.
  /// Handles month overflows (e.g. Jan 31 + 1 month = Feb 28/29).
  static DateTime _addMonths(DateTime date, int months) {
    int year = date.year + (date.month + months - 1) ~/ 12;
    int month = (date.month + months - 1) % 12 + 1;
    
    // Get the last day of the target month
    int daysInTargetMonth = DateTime(year, month + 1, 0).day;
    int day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;
    
    return DateTime(year, month, day);
  }
}