// Handles all Supabase database calls for the `motorcycles` table.
// It returns clean Dart objects (Motorcycle) to the rest of the app.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// A simple data model representing a row in the `motorcycles` table.
class Motorcycle {
  final String id;
  final String userId;
  final String nickname;
  final String model;
  final int? year;
  final int currentOdometer;
  final double dailyDistanceKm;
  final bool isActive;
  final bool isArchived;

  const Motorcycle({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.model,
    this.year,
    required this.currentOdometer,
    required this.dailyDistanceKm,
    required this.isActive,
    required this.isArchived,
  });

  /// Factory method to safely convert a JSON map from Supabase
  /// into a Motorcycle object.
  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    final rawOdo = json['current_odometer'];
    final odo = rawOdo is num ? rawOdo.toInt() : int.tryParse(rawOdo?.toString() ?? '0') ?? 0;

    final rawDist = json['daily_distance_km'];
    final dist = rawDist is num ? rawDist.toDouble() : double.tryParse(rawDist?.toString() ?? '0') ?? 0.0;
    return Motorcycle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      model: json['model'] as String,
      year: json['year'] as int?,
      currentOdometer: odo,
      dailyDistanceKm: dist,
      isActive: json['is_active'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }
}

/// A friendly error for database failures.
class MotorcycleFailure implements Exception {
  final String message;
  const MotorcycleFailure(this.message);

  @override
  String toString() => message;
}

class MotorcycleRepository {
  MotorcycleRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------
  // Read: Fetch motorcycles
  // If archived is false, returns active/main bikes.
  // If archived is true, returns the archived bikes.
  // ---------------------------------------------------------------
    Future<List<Motorcycle>> fetchMotorcycles({bool archived = false}) async {
    try {
      // We order by nickname alphabetically.
      final list = await _client
          .from('motorcycles')
          .select()
          .eq('is_archived', archived)
          .order('nickname', ascending: true);

      return list.map((json) => Motorcycle.fromJson(json)).toList();
    } catch (_) {
      throw const MotorcycleFailure(
        'Could not load motorcycles. Check your internet connection.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Create: Add a new motorcycle
  // ---------------------------------------------------------------
    Future<void> addMotorcycle({
    required String nickname,
    required String model,
    int? year,
    required int currentOdometer,
    required double dailyDistance,
  }) async {
    try {
      // 1. Get the current user's ID.
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const MotorcycleFailure('You must be logged in to add a bike.');
      }

      // 2. Insert with user_id explicitly passed.
      await _client.from('motorcycles').insert({
        'user_id': userId, // <--- THIS WAS MISSING
        'nickname': nickname.trim(),
        'model': model.trim(),
        'year': year,
        'current_odometer': currentOdometer,
        'daily_distance_km': dailyDistance,
        'is_active': false,
        'is_archived': false,
      });
    } catch (e) {
      // 3. Print the exact error to the terminal so we can see it!
      debugPrint('ADD MOTORCYCLE ERROR: $e');
      throw const MotorcycleFailure(
        'Could not add motorcycle. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Update: Edit an existing motorcycle
  // ---------------------------------------------------------------
  Future<void> updateMotorcycle({
    required String id,
    required String nickname,
    required String model,
    int? year,
    required int currentOdometer,
    required double dailyDistance,
  }) async {
    try {
      await _client.from('motorcycles').update({
        'nickname': nickname.trim(),
        'model': model.trim(),
        'year': year,
        'current_odometer': currentOdometer,
        'daily_distance_km': dailyDistance,
      }).eq('id', id); // RLS ensures we only update our own.
    } catch (_) {
      throw const MotorcycleFailure(
        'Could not update motorcycle. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Archive: Hide from main list but keep history
  // ---------------------------------------------------------------
  Future<void> archiveMotorcycle(String id) async {
    try {
      await _client
          .from('motorcycles')
          .update({'is_archived': true, 'is_active': false}).eq('id', id);
    } catch (_) {
      throw const MotorcycleFailure(
        'Could not archive motorcycle. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Delete: Permanently remove (cascades to all history)
  // ---------------------------------------------------------------
  Future<void> deleteMotorcycle(String id) async {
    try {
      await _client.from('motorcycles').delete().eq('id', id);
    } catch (_) {
      throw const MotorcycleFailure(
        'Could not delete motorcycle. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Switch Active Motorcycle
  // We use an RPC (Remote Procedure Call) for this because it requires
  // MULTIPLE database writes (turn old one off, then new one on).
  // If we did this in Dart, a network failure between the two calls
  // would leave the user with NO active motorcycle or TWO active ones.
  // ---------------------------------------------------------------
  Future<void> setActiveMotorcycle(String id) async {
    try {
      await _client.rpc('switch_active_motorcycle', params: {
        'target_id': id,
      });
    } catch (_) {
      throw const MotorcycleFailure(
        'Could not switch active motorcycle. Please try again.',
      );
    }
  }
}