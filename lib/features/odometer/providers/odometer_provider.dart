// The state manager for odometer readings.
// Calculates the estimated mileage and handles the reading history.

import 'package:flutter/foundation.dart';
import '../data/odometer_repository.dart';
import '../domain/odometer_calculator.dart';

class OdometerProvider extends ChangeNotifier {
  OdometerProvider(this._repo);

  final OdometerRepository _repo;

  // ---------------------------------------------------------------
  // State variables
  // ---------------------------------------------------------------
  List<OdometerReading> _readings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // The calculated mileage estimate (value + isStale flag)
  MileageEstimate? _estimate;

  // ---------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------
  List<OdometerReading> get readings => List.unmodifiable(_readings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MileageEstimate? get estimate => _estimate;

  /// Returns the most recent real reading. Returns null if there are none.
  OdometerReading? get latestReading {
    return _readings.isNotEmpty ? _readings.first : null;
  }

  // ---------------------------------------------------------------
  // Load Data
  // ---------------------------------------------------------------
  Future<void> loadReadings({
    required String motorcycleId,
    required double dailyDistanceKm,
    required int currentOdometerFallback,
  }) async {
    _setLoading(true);
    try {
      _readings = await _repo.fetchReadings(motorcycleId);

      if (_readings.isEmpty) {
        // If there are no readings, the estimate is just the fallback
        // (the current odometer on the motorcycle table).
        _estimate = MileageEstimate(
          estimatedKm: currentOdometerFallback,
          isStale: false,
        );
      } else {
        // Calculate estimate based on the latest reading
        _estimate = OdometerCalculator.calculateEstimate(
          lastOdometer: _readings.first.valueKm,
          lastReadingDate: _readings.first.readingDate,
          dailyDistanceKm: dailyDistanceKm,
        );
      }
    } on OdometerFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred while loading history.';
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Add Reading
  // ---------------------------------------------------------------
  Future<bool> addReading({
    required String motorcycleId,
    required int valueKm,
    required DateTime date,
    required double dailyDistanceKm,
    required int currentOdometerFallback,
  }) async {
    _setLoading(true);
    try {
      await _repo.addReading(
        motorcycleId: motorcycleId,
        valueKm: valueKm,
        date: date,
      );
      
      // Reload data to get the new reading and updated estimate.
      await loadReadings(
        motorcycleId: motorcycleId,
        dailyDistanceKm: dailyDistanceKm,
        currentOdometerFallback: currentOdometerFallback,
      );
      return true;
    } on OdometerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not save reading.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Edit Reading
  // ---------------------------------------------------------------
  Future<bool> updateReading({
    required String id,
    required String motorcycleId,
    required int valueKm,
    required DateTime date,
    required double dailyDistanceKm,
    required int currentOdometerFallback,
  }) async {
    _setLoading(true);
    try {
      await _repo.updateReading(
        id: id,
        motorcycleId: motorcycleId,
        valueKm: valueKm,
        date: date,
      );
      
      await loadReadings(
        motorcycleId: motorcycleId,
        dailyDistanceKm: dailyDistanceKm,
        currentOdometerFallback: currentOdometerFallback,
      );
      return true;
    } on OdometerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update reading.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Delete Reading
  // ---------------------------------------------------------------
  Future<bool> deleteReading({
    required String id,
    required String motorcycleId,
    required double dailyDistanceKm,
    required int currentOdometerFallback,
  }) async {
    _setLoading(true);
    try {
      await _repo.deleteReading(id);
      
      await loadReadings(
        motorcycleId: motorcycleId,
        dailyDistanceKm: dailyDistanceKm,
        currentOdometerFallback: currentOdometerFallback,
      );
      return true;
    } on OdometerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete reading.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Suggest Daily Distance (based on last 90 days of readings)
  // ---------------------------------------------------------------
  double? suggestDailyDistance() {
    if (_readings.length < 2) return null;

    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Filter readings to only those within the last 90 days
    final recentReadings = _readings
        .where((r) => r.readingDate.isAfter(ninetyDaysAgo) || r.readingDate.isAtSameMomentAs(ninetyDaysAgo))
        .map((r) => OdometerReadingData(valueKm: r.valueKm, date: r.readingDate))
        .toList();

    return OdometerCalculator.calculateDailyDistance(recentReadings);
  }

  // ---------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}