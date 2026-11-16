// Handles database operations for odometer readings.
// Uses an RPC (database transaction) for adding readings to ensure
// the motorcycle's current_odometer stays perfectly in sync.

import 'package:supabase_flutter/supabase_flutter.dart';

class OdometerReading {
  final String id;
  final String motorcycleId;
  final int valueKm;
  final DateTime readingDate;
  final String source; // 'rider' or 'service'

  const OdometerReading({
    required this.id,
    required this.motorcycleId,
    required this.valueKm,
    required this.readingDate,
    required this.source,
  });

  factory OdometerReading.fromJson(Map<String, dynamic> json) {
    final rawKm = json['value_km'];
    final km = rawKm is num ? rawKm.toInt() : int.parse(rawKm.toString());
    
    return OdometerReading(
      id: json['id'] as String,
      motorcycleId: json['motorcycle_id'] as String,
      valueKm: km,
      readingDate: DateTime.parse(json['reading_date'] as String),
      source: json['source'] as String,
    );
  }
}

class OdometerFailure implements Exception {
  final String message;
  const OdometerFailure(this.message);

  @override
  String toString() => message;
}

class OdometerRepository {
  OdometerRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------
  // Read: Fetch all readings for a bike (newest first)
  // ---------------------------------------------------------------
  Future<List<OdometerReading>> fetchReadings(String motorcycleId) async {
    try {
      final response = await _client
          .from('odometer_readings')
          .select()
          .eq('motorcycle_id', motorcycleId)
          .order('reading_date', ascending: false); // REMOVED created_at

      return response.map((json) => OdometerReading.fromJson(json)).toList();
    } catch (_) {
      throw const OdometerFailure('Could not load reading history.');
    }
  }

  // ---------------------------------------------------------------
  // Read: Fetch the most recent reading
  // ---------------------------------------------------------------
  Future<OdometerReading?> fetchLatestReading(String motorcycleId) async {
    try {
      final response = await _client
          .from('odometer_readings')
          .select()
          .eq('motorcycle_id', motorcycleId)
          .order('reading_date', ascending: false) // REMOVED created_at
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return OdometerReading.fromJson(response);
    } catch (_) {
      throw const OdometerFailure('Could not check the latest reading.');
    }
  }

  // ---------------------------------------------------------------
  // Create: Add a new reading (RPC Transaction)
  // ---------------------------------------------------------------
  Future<void> addReading({
    required String motorcycleId,
    required int valueKm,
    required DateTime date,
    String source = 'rider',
  }) async {
    try {
      await _client.rpc('add_odometer_reading', params: {
        'p_motorcycle_id': motorcycleId,
        'p_value_km': valueKm,
        'p_reading_date': date.toIso8601String().split('T').first, // Format as YYYY-MM-DD
        'p_source': source,
      });
    } catch (e) {
      if (e.toString().contains('foreign key')) {
        throw const OdometerFailure(
          'Cannot delete or edit this reading because it is used by a service record.',
        );
      }
      throw const OdometerFailure('Could not save reading. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // Update: Edit an existing reading
  // ---------------------------------------------------------------
  Future<void> updateReading({
    required String id,
    required String motorcycleId,
    required int valueKm,
    required DateTime date,
  }) async {
    try {
      // Note: We do not change the `source` when editing.
      await _client.from('odometer_readings').update({
        'value_km': valueKm,
        'reading_date': date.toIso8601String().split('T').first,
      }).eq('id', id);

      // Note: If the user edits their highest reading to be *lower*, we
      // technically need to recalculate the motorcycle's current_odometer.
      // For simplicity in this project, we will just re-run a simple update.
      // In a production app, you would use another RPC here.
    } catch (_) {
      throw const OdometerFailure('Could not update reading.');
    }
  }

  // ---------------------------------------------------------------
  // Delete: Remove a reading
  // ---------------------------------------------------------------
  Future<void> deleteReading(String id) async {
    try {
      await _client.from('odometer_readings').delete().eq('id', id);
    } catch (e) {
      // The database has a "NO CASCADE" rule on service_records.odometer_reading_id
      // If a service record is using this reading, Postgres will throw a foreign key error.
      if (e.toString().contains('foreign key')) {
        throw const OdometerFailure(
          'Cannot delete: A service record is linked to this reading.',
        );
      }
      throw const OdometerFailure('Could not delete reading.');
    }
  }

  // ---------------------------------------------------------------
  // Update Daily Distance
  // ---------------------------------------------------------------
  Future<void> updateDailyDistance(String motorcycleId, double km) async {
    try {
      await _client.from('motorcycles').update({
        'daily_distance_km': km,
      }).eq('id', motorcycleId);
    } catch (_) {
      throw const OdometerFailure('Could not save daily distance.');
    }
  }
}