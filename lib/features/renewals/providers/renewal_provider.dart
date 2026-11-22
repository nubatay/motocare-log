import 'package:flutter/foundation.dart';
import '../data/renewal_repository.dart';

enum RenewalStatus { ok, dueSoon, overdue }

class RenewalProvider extends ChangeNotifier {
  RenewalProvider(this._repo);
  final RenewalRepository _repo;

  List<Renewal> _renewals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Renewal> get renewals => List.unmodifiable(_renewals);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 30-day rule for renewals
  RenewalStatus getStatus(Renewal renewal) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dueMidnight = DateTime(renewal.dueDate.year, renewal.dueDate.month, renewal.dueDate.day);

    if (todayMidnight.isAfter(dueMidnight)) {
      return RenewalStatus.overdue;
    }
    
    final daysLeft = dueMidnight.difference(todayMidnight).inDays;
    if (daysLeft <= 30) {
      return RenewalStatus.dueSoon;
    }
    
    return RenewalStatus.ok;
  }

  Future<void> loadRenewals() async {
    _setLoading(true);
    try {
      _renewals = await _repo.fetchRenewals();
    } on RenewalFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not load renewals.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRenewal({
    required String renewalType,
    String? motorcycleId,
    required DateTime dueDate,
  }) async {
    _setLoading(true);
    try {
      await _repo.addRenewal(renewalType: renewalType, motorcycleId: motorcycleId, dueDate: dueDate);
      await loadRenewals();
      return true;
    } catch (_) {
      _errorMessage = 'Could not add renewal.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRenewal({
    required String id,
    required String renewalType,
    String? motorcycleId,
    required DateTime dueDate,
  }) async {
    _setLoading(true);
    try {
      await _repo.updateRenewal(id: id, renewalType: renewalType, motorcycleId: motorcycleId, dueDate: dueDate);
      await loadRenewals();
      return true;
    } catch (_) {
      _errorMessage = 'Could not update renewal.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRenewal(String id) async {
    _setLoading(true);
    try {
      await _repo.deleteRenewal(id);
      await loadRenewals();
      return true;
    } catch (_) {
      _errorMessage = 'Could not delete renewal.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}