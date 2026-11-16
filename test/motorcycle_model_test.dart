import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_log/features/motorcycles/data/motorcycle_repository.dart';

void main() {
  test('Motorcycle.fromJson parses data correctly', () {
    final json = {
      'id': '123',
      'user_id': 'user-abc',
      'nickname': 'Daily Rider',
      'model': 'Honda Click',
      'year': 2023,
      'current_odometer': 1500,
      'daily_distance_km': 25.5,
      'is_active': true,
      'is_archived': false,
    };

    final bike = Motorcycle.fromJson(json);

    expect(bike.nickname, 'Daily Rider');
    expect(bike.currentOdometer, 1500);
    expect(bike.dailyDistanceKm, 25.5);
    expect(bike.isActive, isTrue);
  });
}