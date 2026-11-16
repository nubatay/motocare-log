// The state manager for motorcycles. It holds the lists of bikes,
// tells the UI when to show a spinner, and calls the repository
// to make database changes.

import 'package:flutter/foundation.dart';
import '../data/motorcycle_repository.dart';

class MotorcycleProvider extends ChangeNotifier {
  MotorcycleProvider(this._repo);

  final MotorcycleRepository _repo;

  // ---------------------------------------------------------------
  // State variables
  // ---------------------------------------------------------------
  List<Motorcycle> _activeBikes = [];
  List<Motorcycle> _archivedBikes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------
  List<Motorcycle> get activeBikes => List.unmodifiable(_activeBikes);
  List<Motorcycle> get archivedBikes => List.unmodifiable(_archivedBikes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Convenience getter to find the currently active bike.
  /// Returns null if no bike is active.
  Motorcycle? get activeBike {
    try {
      return _activeBikes.firstWhere((bike) => bike.isActive);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------
  // Load Data
  // ---------------------------------------------------------------
  Future<void> loadMotorcycles() async {
    _setLoading(true);
    try {
      // Fetch both lists.
      // We use Future.wait to run them in parallel for speed.
      final results = await Future.wait([
        _repo.fetchMotorcycles(archived: false),
        _repo.fetchMotorcycles(archived: true),
      ]);

      _activeBikes = results[0];
      _archivedBikes = results[1];
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred while loading bikes.';
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Add Bike
  // ---------------------------------------------------------------
  Future<bool> addMotorcycle({
    required String nickname,
    required String model,
    int? year,
    required int currentOdometer,
    required double dailyDistance,
  }) async {
    _setLoading(true);
    try {
      await _repo.addMotorcycle(
        nickname: nickname,
        model: model,
        year: year,
        currentOdometer: currentOdometer,
        dailyDistance: dailyDistance,
      );
      
      // Reload the lists so the new bike appears immediately.
      await loadMotorcycles();
      return true;
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not add motorcycle.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Update Bike
  // ---------------------------------------------------------------
  Future<bool> updateMotorcycle({
    required String id,
    required String nickname,
    required String model,
    int? year,
    required int currentOdometer,
    required double dailyDistance,
  }) async {
    _setLoading(true);
    try {
      await _repo.updateMotorcycle(
        id: id,
        nickname: nickname,
        model: model,
        year: year,
        currentOdometer: currentOdometer,
        dailyDistance: dailyDistance,
      );
      
      await loadMotorcycles();
      return true;
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update motorcycle.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Archive Bike
  // ---------------------------------------------------------------
  Future<bool> archiveMotorcycle(String id) async {
    _setLoading(true);
    try {
      await _repo.archiveMotorcycle(id);
      await loadMotorcycles();
      return true;
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not archive motorcycle.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Delete Bike Permanently
  // ---------------------------------------------------------------
  Future<bool> deleteMotorcycle(String id) async {
    _setLoading(true);
    try {
      await _repo.deleteMotorcycle(id);
      await loadMotorcycles();
      return true;
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete motorcycle.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Switch Active Bike
  // ---------------------------------------------------------------
  Future<bool> switchActiveMotorcycle(String id) async {
    _setLoading(true);
    try {
      await _repo.setActiveMotorcycle(id);
      await loadMotorcycles();
      return true;
    } on MotorcycleFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not switch motorcycle.';
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