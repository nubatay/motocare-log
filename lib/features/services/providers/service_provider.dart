// lib/features/services/providers/service_provider.dart
//
// Combines ServiceTypes, ServiceIntervals, and ServiceRecords to calculate
// the status (OK, Due Soon, Overdue) for every service on a bike.

import 'package:flutter/foundation.dart';
import '../data/service_repository.dart';
import '../domain/service_calculator.dart';

/// A helper class that bundles a ServiceType with its interval, latest record,
/// and calculated status for easy display in the UI.
class ServiceOverview {
  final ServiceType type;
  final int? intervalKm;
  final int? intervalMonths;
  final ServiceRecord? latestRecord;
  final ServiceStatusResult status;

  const ServiceOverview({
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

  // ---------------------------------------------------------------
  // State
  // ---------------------------------------------------------------
  List<ServiceOverview> _overviews = [];
  List<ServiceRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------
  List<ServiceOverview> get overviews => List.unmodifiable(_overviews);
  List<ServiceRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------
  // Load Data
  // ---------------------------------------------------------------
  Future<void> loadData({
    required String motorcycleId,
    required int estimatedOdometer, // Passed from OdometerProvider/UI
  }) async {
    _setLoading(true);
    try {
      // 1. Fetch all needed data in parallel for speed
      final results = await Future.wait([
        _repo.fetchServiceTypes(),
        _repo.fetchServiceIntervals(motorcycleId),
        _repo.fetchServiceRecords(motorcycleId),
      ]);

      final types = results[0] as List<ServiceType>;
      final intervals = results[1] as List<ServiceInterval>;
      _records = results[2] as List<ServiceRecord>;

      final List<ServiceOverview> newOverviews = [];

      // 2. Loop through every ServiceType and calculate its status
      for (final type in types) {
        // Find the custom interval for this bike, or fallback to default
        final interval = intervals.firstWhere(
          (i) => i.serviceTypeId == type.id,
          orElse: () => ServiceInterval(
            id: '',
            motorcycleId: motorcycleId,
            serviceTypeId: type.id,
            intervalKm: type.defaultIntervalKm,
            intervalMonths: type.defaultIntervalMonths,
          ),
        );

        // Find the most recent record for this type
        ServiceRecord? latest;
        try {
          latest = _records.firstWhere((r) => r.serviceTypeId == type.id);
        } catch (_) {
          // No record found. latest remains null.
        }

        // Calculate the status
        final status = ServiceCalculator.calculateStatus(
          latestRecord: latest,
          intervalKm: interval.intervalKm,
          intervalMonths: interval.intervalMonths,
          estimatedOdometer: estimatedOdometer,
        );

        newOverviews.add(ServiceOverview(
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

  // ---------------------------------------------------------------
  // Add Record
  // ---------------------------------------------------------------
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
      
      await loadData(
        motorcycleId: motorcycleId,
        estimatedOdometer: estimatedOdometer,
      );
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

  // ---------------------------------------------------------------
  // Delete Record
  // ---------------------------------------------------------------
  Future<bool> deleteRecord({
    required String id,
    required String motorcycleId,
    required int estimatedOdometer,
  }) async {
    _setLoading(true);
    try {
      await _repo.deleteServiceRecord(id);
      
      await loadData(
        motorcycleId: motorcycleId,
        estimatedOdometer: estimatedOdometer,
      );
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