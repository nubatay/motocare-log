// lib/features/services/data/service_repository.dart
//
// Handles fetching service types, intervals, and managing service records.
// Uses an RPC to safely save a service record AND its odometer reading
// in a single database transaction.

import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceType {
  final String id;
  final String name;
  final int? defaultIntervalKm;
  final int? defaultIntervalMonths;

  const ServiceType({
    required this.id,
    required this.name,
    this.defaultIntervalKm,
    this.defaultIntervalMonths,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultIntervalKm: json['default_interval_km'] as int?,
      defaultIntervalMonths: json['default_interval_months'] as int?,
    );
  }
}

class ServiceInterval {
  final String id;
  final String motorcycleId;
  final String serviceTypeId;
  final int? intervalKm;
  final int? intervalMonths;

  const ServiceInterval({
    required this.id,
    required this.motorcycleId,
    required this.serviceTypeId,
    this.intervalKm,
    this.intervalMonths,
  });

  factory ServiceInterval.fromJson(Map<String, dynamic> json) {
    return ServiceInterval(
      id: json['id'] as String,
      motorcycleId: json['motorcycle_id'] as String,
      serviceTypeId: json['service_type_id'] as String,
      intervalKm: json['interval_km'] as int?,
      intervalMonths: json['interval_months'] as int?,
    );
  }
}

class ServiceRecord {
  final String id;
  final String motorcycleId;
  final String serviceTypeId;
  final String odometerReadingId;
  final DateTime serviceDate;
  final double cost;
  final String? notes;
  
  // Joined data for easy UI display
  final String serviceTypeName;
  final int odometerValue;

  const ServiceRecord({
    required this.id,
    required this.motorcycleId,
    required this.serviceTypeId,
    required this.odometerReadingId,
    required this.serviceDate,
    required this.cost,
    this.notes,
    required this.serviceTypeName,
    required this.odometerValue,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    // Supabase returns joined tables as nested JSON objects.
    final typeData = json['service_types'] as Map<String, dynamic>;
    final readingData = json['odometer_readings'] as Map<String, dynamic>;

    final rawCost = json['cost'];
    final costDouble = rawCost is num ? rawCost.toDouble() : double.tryParse(rawCost.toString()) ?? 0.0;

    return ServiceRecord(
      id: json['id'] as String,
      motorcycleId: json['motorcycle_id'] as String,
      serviceTypeId: json['service_type_id'] as String,
      odometerReadingId: json['odometer_reading_id'] as String,
      serviceDate: DateTime.parse(json['service_date'] as String),
      cost: costDouble,
      notes: json['notes'] as String?,
      serviceTypeName: typeData['name'] as String,
      odometerValue: (readingData['value_km'] as num).toInt(),
    );
  }
}

class ServiceFailure implements Exception {
  final String message;
  const ServiceFailure(this.message);

  @override
  String toString() => message;
}

class ServiceRepository {
  ServiceRepository(this._client);
  final SupabaseClient _client;

  // ---------------------------------------------------------------
  // Read: Fetch all service types (seeded by the database)
  // ---------------------------------------------------------------
  Future<List<ServiceType>> fetchServiceTypes() async {
    try {
      final response = await _client
          .from('service_types')
          .select()
          .order('name', ascending: true);
      return response.map((json) => ServiceType.fromJson(json)).toList();
    } catch (_) {
      throw const ServiceFailure('Could not load service types.');
    }
  }

  // ---------------------------------------------------------------
  // Read: Fetch custom intervals for a specific bike
  // ---------------------------------------------------------------
  Future<List<ServiceInterval>> fetchServiceIntervals(String motorcycleId) async {
    try {
      final response = await _client
          .from('service_intervals')
          .select()
          .eq('motorcycle_id', motorcycleId);
      return response.map((json) => ServiceInterval.fromJson(json)).toList();
    } catch (_) {
      throw const ServiceFailure('Could not load service intervals.');
    }
  }

  // ---------------------------------------------------------------
  // Read: Fetch service history for a bike (newest first)
  // ---------------------------------------------------------------
  Future<List<ServiceRecord>> fetchServiceRecords(String motorcycleId) async {
    try {
      final response = await _client
          .from('service_records')
          .select('*, service_types(name), odometer_readings(value_km)')
          .eq('motorcycle_id', motorcycleId)
          .order('service_date', ascending: false);

      return response.map((json) => ServiceRecord.fromJson(json)).toList();
    } catch (_) {
      throw const ServiceFailure('Could not load service history.');
    }
  }

  // ---------------------------------------------------------------
  // Create: Add a service record (RPC Transaction)
  // ---------------------------------------------------------------
  Future<void> addServiceRecord({
    required String motorcycleId,
    required String serviceTypeId,
    required int odometerValueKm,
    required DateTime serviceDate,
    required double cost,
    String? notes,
  }) async {
    try {
      await _client.rpc('add_service_record', params: {
        'p_motorcycle_id': motorcycleId,
        'p_service_type_id': serviceTypeId,
        'p_odometer_km': odometerValueKm,
        'p_service_date': serviceDate.toIso8601String().split('T').first,
        'p_cost': cost,
        'p_notes': notes?.trim(),
      });
    } catch (e) {
      throw const ServiceFailure('Could not save service record. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // Delete: Remove a service record
  // Note: The linked odometer reading is protected by the database 
  // and will not be deleted automatically.
  // ---------------------------------------------------------------
  Future<void> deleteServiceRecord(String id) async {
    try {
      await _client.from('service_records').delete().eq('id', id);
    } catch (_) {
      throw const ServiceFailure('Could not delete service record.');
    }
  }

  Future<void> updateServiceRecord({
    required String id,
    required double cost,
    required String? notes,
  }) async {
    try {
      await _client.from('service_records').update({
        'cost': cost,
        'notes': notes?.trim(),
      }).eq('id', id);
    } catch (_) {
      throw const ServiceFailure('Could not update service record.');
    }
  }
}