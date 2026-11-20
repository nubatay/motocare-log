// lib/features/services/providers/service_provider.dart
//
// Combines ServiceTypes, ServiceIntervals, and ServiceRecords to calculate
// the status (OK, Due Soon, Overdue) for every service on a bike.

import 'package:flutter/foundation.dart';
import '../data/service_repository.dart';
import '../domain/service_calculator.dart';

class ServiceOverview {
  final String intervalId; // <-- NEW: Needed for editing
  final ServiceType type;
  final int? intervalKm;
  final int? intervalMonths;
  final ServiceRecord? latestRecord;
  final ServiceStatusResult status;

  const ServiceOverview({
    required this.intervalId,
    required this.type,
    this.intervalKm,
    this.intervalMonths,
    this.latestRecord,
    required this.status,
  });
}

class ServiceProvider extends ChangeNotifier {
  ServiceProvider(this._repo);

  final ServiceRepository _repo;

  List<ServiceOverview> _overviews = [];
  List<ServiceRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceOverview> get overviews => List.unmodifiable(_overviews);
  List<ServiceRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData({
    required String motorcycleId,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repo.fetchServiceTypes(),
        _repo.fetchServiceIntervals(motorcycleId),
        _repo.fetchServiceRecords(motorcycleId),
      ]);

      final types = results[0] as List<ServiceType>;
      final intervals = results[1] as List<ServiceInterval>;
      _records = results[2] as List<ServiceRecord>;

      final List<ServiceOverview> newOverviews = [];

      for (final type in types) {
        final interval = intervals.firstWhere(
          (i) => i.serviceTypeId == type.id,
          orElse: () => ServiceInterval(
            id: '', // Empty ID means this interval doesn't exist in DB
            motorcycleId: motorcycleId,
            serviceTypeId: type.id,
            intervalKm: type.defaultIntervalKm,
            intervalMonths: type.defaultIntervalMonths,
          ),
        );

        ServiceRecord? latest;
        try {
          latest = _records.firstWhere((r) => r.serviceTypeId == type.id);
        } catch (_) {}

        final status = ServiceCalculator.calculateStatus(
          latestRecord: latest,
          intervalKm: interval.intervalKm,
          intervalMonths: interval.intervalMonths,
          estimatedOdometer: estimatedOdometer,
        );

        newOverviews.add(ServiceOverview(
          intervalId: interval.id, // <-- Pass the ID
          type: type,
          intervalKm: interval.intervalKm,
          intervalMonths: interval.intervalMonths,
          latestRecord: latest,
          status: status,
        ));
      }

      _overviews = newOverviews;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred while loading services.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRecord({
    required String motorcycleId,
    required String serviceTypeId,
    required int odometerKm,
    required DateTime serviceDate,
    required double cost,
    String? notes,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      await _repo.addServiceRecord(
        motorcycleId: motorcycleId,
        serviceTypeId: serviceTypeId,
        odometerValueKm: odometerKm,
        serviceDate: serviceDate,
        cost: cost,
        notes: notes,
      );
      await loadData(motorcycleId: motorcycleId, estimatedOdometer: estimatedOdometer);
      return true;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not save service record.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRecord({
    required String id,
    required double cost,
    required String? notes,
    required String motorcycleId,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      await _repo.updateServiceRecord(id: id, cost: cost, notes: notes);
      await loadData(motorcycleId: motorcycleId, estimatedOdometer: estimatedOdometer);
      return true;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update service record.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord({
    required String id,
    required String motorcycleId,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      await _repo.deleteServiceRecord(id);
      await loadData(motorcycleId: motorcycleId, estimatedOdometer: estimatedOdometer);
      return true;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete service record.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // NEW: Update Interval
  // ---------------------------------------------------------------
  Future<bool> updateInterval({
    required String id,
    required String motorcycleId,
    required int estimatedOdometer,
    required int? km,
    required int? months,
  }) async {
    _setLoading(true);
    try {
      await _repo.updateServiceInterval(id: id, km: km, months: months);
      
      // Reload data so the "Due Soon" badges update immediately!
      await loadData(motorcycleId: motorcycleId, estimatedOdometer: estimatedOdometer);
      return true;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update interval.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetIntervals({
    required String motorcycleId,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      await _repo.resetServiceIntervals(motorcycleId);
      await loadData(motorcycleId: motorcycleId, estimatedOdometer: estimatedOdometer);
      return true;
    } on ServiceFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}