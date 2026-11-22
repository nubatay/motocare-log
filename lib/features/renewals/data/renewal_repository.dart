import 'package:supabase_flutter/supabase_flutter.dart';

class Renewal {
  final String id;
  final String? motorcycleId;
  final String renewalType;
  final DateTime dueDate;

  const Renewal({
    required this.id,
    this.motorcycleId,
    required this.renewalType,
    required this.dueDate,
  });

  factory Renewal.fromJson(Map<String, dynamic> json) {
    return Renewal(
      id: json['id'] as String,
      motorcycleId: json['motorcycle_id'] as String?,
      renewalType: json['renewal_type'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
    );
  }
}

class RenewalFailure implements Exception {
  final String message;
  const RenewalFailure(this.message);

  @override
  String toString() => message;
}

class RenewalRepository {
  RenewalRepository(this._client);
  final SupabaseClient _client;

  Future<List<Renewal>> fetchRenewals() async {
    try {
      final response = await _client
          .from('renewals')
          .select()
          .order('due_date', ascending: true);
      return response.map((json) => Renewal.fromJson(json)).toList();
    } catch (_) {
      throw const RenewalFailure('Could not load renewals.');
    }
  }

  Future<void> addRenewal({
    required String renewalType,
    String? motorcycleId,
    required DateTime dueDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const RenewalFailure('Not logged in.');

      await _client.from('renewals').insert({
        'user_id': userId,
        'motorcycle_id': motorcycleId,
        'renewal_type': renewalType,
        'due_date': dueDate.toIso8601String().split('T').first,
      });
    } catch (_) {
      throw const RenewalFailure('Could not add renewal.');
    }
  }

  Future<void> updateRenewal({
    required String id,
    required String renewalType,
    String? motorcycleId,
    required DateTime dueDate,
  }) async {
    try {
      await _client.from('renewals').update({
        'motorcycle_id': motorcycleId,
        'renewal_type': renewalType,
        'due_date': dueDate.toIso8601String().split('T').first,
      }).eq('id', id);
    } catch (_) {
      throw const RenewalFailure('Could not update renewal.');
    }
  }

  Future<void> deleteRenewal(String id) async {
    try {
      await _client.from('renewals').delete().eq('id', id);
    } catch (_) {
      throw const RenewalFailure('Could not delete renewal.');
    }
  }
}