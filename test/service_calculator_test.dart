import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_log/features/services/data/service_repository.dart';
import 'package:motocare_log/features/services/domain/service_calculator.dart';

void main() {
  final mockRecord = ServiceRecord(
    id: '1',
    motorcycleId: 'bike1',
    serviceTypeId: 'type1',
    odometerReadingId: 'read1',
    serviceDate: DateTime(2026, 1, 1),
    cost: 500.0,
    serviceTypeName: 'Oil Change',
    odometerValue: 10000,
  );

  test('returns noRecord if latestRecord is null', () {
    final result = ServiceCalculator.calculateStatus(
      latestRecord: null,
      intervalKm: 3500,
      intervalMonths: 6,
      estimatedOdometer: 10000,
    );
    expect(result.status, ServiceStatus.noRecord);
  });

  test('returns ok if well within limits', () {
    final result = ServiceCalculator.calculateStatus(
      latestRecord: mockRecord,
      intervalKm: 3500, // Due at 13500
      intervalMonths: 6, // Due Jul 1, 2026
      estimatedOdometer: 11000, // 2500 km driven
      currentDate: DateTime(2026, 3, 1), // 2 months passed
    );
    expect(result.status, ServiceStatus.ok);
    expect(result.dueKm, 13500);
  });

  test('returns dueSoon if within 300km', () {
    final result = ServiceCalculator.calculateStatus(
      latestRecord: mockRecord,
      intervalKm: 3500,
      intervalMonths: 6,
      estimatedOdometer: 13300, // Only 200km left
      currentDate: DateTime(2026, 3, 1),
    );
    expect(result.status, ServiceStatus.dueSoon);
  });

  test('returns overdue if km exceeded', () {
    final result = ServiceCalculator.calculateStatus(
      latestRecord: mockRecord,
      intervalKm: 3500,
      intervalMonths: 6,
      estimatedOdometer: 13600, // Exceeded 3500
      currentDate: DateTime(2026, 3, 1),
    );
    expect(result.status, ServiceStatus.overdue);
  });

  test('returns overdue if date exceeded', () {
    final result = ServiceCalculator.calculateStatus(
      latestRecord: mockRecord,
      intervalKm: 3500,
      intervalMonths: 6,
      estimatedOdometer: 11000, // KM is fine
      currentDate: DateTime(2026, 8, 1), // 7 months passed (Overdue)
    );
    expect(result.status, ServiceStatus.overdue);
  });
}