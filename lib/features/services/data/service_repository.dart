// lib/features/services/data/service_repository.dart

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

  Future<List<ServiceType>> fetchServiceTypes() async {
    try {
      final response = await _client.from('service_types').select().order('name', ascending: true);
      return response.map((json) => ServiceType.fromJson(json)).toList();
    } catch (_) {
      throw const ServiceFailure('Could not load service types.');
    }
  }

  Future<List<ServiceInterval>> fetchServiceIntervals(String motorcycleId) async {
    try {
      final response = await _client.from('service_intervals').select().eq('motorcycle_id', motorcycleId);
      return response.map((json) => ServiceInterval.fromJson(json)).toList();
    } catch (_) {
      throw const ServiceFailure('Could not load service intervals.');
    }
  }

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
      throw const ServiceFailure('Could not save service record.');
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

  Future<void> deleteServiceRecord(String id) async {
    try {
      await _client.from('service_records').delete().eq('id', id);
    } catch (_) {
      throw const ServiceFailure('Could not delete service record.');
    }
  }

  // ---------------------------------------------------------------
  // NEW: Update a specific custom interval
  // ---------------------------------------------------------------
  Future<void> updateServiceInterval({
    required String id,
    required int? km,
    required int? months,
  }) async {
    try {
      await _client.from('service_intervals').update({
        'interval_km': km,
        'interval_months': months,
      }).eq('id', id);
    } catch (_) {
      throw const ServiceFailure('Could not update interval.');
    }
  }

  Future<void> resetServiceIntervals(String motorcycleId) async {
    try {
      // 1. Get the factory defaults
      final defaults = await _client.from('service_types').select();
      final defaultMap = { for (var d in defaults) d['id']: d };
      
      // 2. Get this bike's custom intervals
      final intervals = await _client.from('service_intervals').select().eq('motorcycle_id', motorcycleId);
      
      // 3. Loop and update (there are only 7, so this is fast)
      for (var interval in intervals) {
        final typeId = interval['service_type_id'];
        final defaultType = defaultMap[typeId];
        if (defaultType != null) {
          await _client.from('service_intervals').update({
            'interval_km': defaultType['default_interval_km'],
            'interval_months': defaultType['default_interval_months'],
          }).eq('id', interval['id']);
        }
      }
    } catch (_) {
      throw const ServiceFailure('Could not reset intervals.');
    }
  }
}