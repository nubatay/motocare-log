// lib/core/validators.dart
//
// Central home for every input rule in MotoCare Log.
// Why one file? If a rule changes (say password length), we edit ONE place.
// The UI uses these for instant feedback. The database enforces the real rules.

/// Reusable validators.
///
/// Every method returns `null` when the value is valid,
/// or a short error message (String) when it is not.
/// That matches Flutter's `TextFormField.validator` signature exactly,
/// so we can plug them in directly on any form field.
class Validators {
  // Private constructor: this class is only a "namespace" of functions.
  // It is never instantiated with `new Validators()`.
  Validators._();

  // ---------------------------------------------------------------
  // Named constants — no magic numbers scattered through the code.
  // ---------------------------------------------------------------
  static const int nameMax = 80;

  static const int emailMax = 254; // RFC 5321 max length.

  static const int passwordMin = 8;
  static const int passwordMax = 72; // bcrypt truncates past 72 bytes.

  static const int nicknameMax = 40;
  static const int modelMax = 60;

  static const int yearMin = 1950;
  // `static final` runs once, when the class is first used.
  // So if the app stays open across New Year's Eve, yearMax stays 2027
  // for that session — acceptable for a school project.
  static final int yearMax = DateTime.now().year + 1;

  static const int odometerMax = 2000000; // 2 million km: plausible cap.
  static const double dailyDistanceMax = 2000.0;
  static const double costMax = 1000000.0;
  static const int notesMax = 1000;

  // ---------------------------------------------------------------
  // Name (profiles.name)
  // ---------------------------------------------------------------
  static String? name(String? value) {
    final v = value?.trim() ?? ''; // ?? '' handles null with an empty string.
    if (v.isEmpty) return 'Please enter your name.';
    if (v.length > nameMax) {
      return 'Name must be at most $nameMax characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Email
  // A short regex. Not perfect (email is famously hard to validate),
  // but it catches the common typos. Supabase Auth is the real gate.
  // ---------------------------------------------------------------
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email.';
    if (v.length > emailMax) return 'Email is too long.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  // ---------------------------------------------------------------
  // Password
  // Rule: 8–72 chars, at least one letter and at least one digit.
  // NOTE: we do NOT trim passwords — spaces are valid characters,
  // and trimming would silently change what the user typed.
  // ---------------------------------------------------------------
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password.';
    if (v.length < passwordMin) {
      return 'Password must be at least $passwordMin characters.';
    }
    if (v.length > passwordMax) {
      return 'Password must be at most $passwordMax characters.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'[0-9]').hasMatch(v);
    if (!hasLetter || !hasDigit) {
      return 'Password must contain at least one letter and one number.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Confirm password (Register screen only)
  // ---------------------------------------------------------------
  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please confirm your password.';
    if (v != original) return 'Passwords do not match.';
    return null;
  }

  // ---------------------------------------------------------------
  // Motorcycle nickname (motorcycles.nickname)
  // ---------------------------------------------------------------
  static String? nickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter a nickname.';
    if (v.length > nicknameMax) {
      return 'Nickname must be at most $nicknameMax characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Motorcycle model (motorcycles.model)
  // ---------------------------------------------------------------
  static String? model(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter the model.';
    if (v.length > modelMax) {
      return 'Model must be at most $modelMax characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Year (motorcycles.year). Nullable in the database.
  // ---------------------------------------------------------------
  static String? year(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional: empty is valid.
    final n = int.tryParse(v);
    if (n == null) return 'Year must be a whole number.';
    if (n < yearMin || n > yearMax) {
      return 'Year must be between $yearMin and $yearMax.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Odometer (motorcycles.current_odometer and odometer_readings.value_km).
  // Must be a WHOLE number (int), not a decimal.
  // ---------------------------------------------------------------
  static String? odometer(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter the odometer value.';
    final n = int.tryParse(v);
    if (n == null) return 'Odometer must be a whole number.';
    if (n < 0) return 'Odometer cannot be negative.';
    if (n > odometerMax) {
      return 'Odometer seems too large (max $odometerMax).';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Daily distance in km (motorcycles.daily_distance_km).
  // numeric(6,1) in the DB → at most one decimal place.
  // ---------------------------------------------------------------
  static String? dailyDistance(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional; DB default is 0.
    final d = double.tryParse(v);
    if (d == null) return 'Enter a number (e.g. 25.5).';
    if (d < 0) return 'Daily distance cannot be negative.';
    if (d > dailyDistanceMax) {
      return 'Daily distance seems too large (max $dailyDistanceMax).';
    }
    if (!RegExp(r'^\d+(\.\d)?$').hasMatch(v)) {
      return 'Use at most one decimal place.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Cost (service_records.cost). numeric(10,2) → at most 2 decimals.
  // ---------------------------------------------------------------
  static String? cost(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // Optional; DB default is 0.
    final d = double.tryParse(v);
    if (d == null) return 'Enter a number (e.g. 250.00).';
    if (d < 0) return 'Cost cannot be negative.';
    if (d > costMax) return 'Cost seems too large (max $costMax).';
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v)) {
      return 'Use at most two decimal places.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Notes (service_records.notes). Optional, capped length.
  // ---------------------------------------------------------------
  static String? notes(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > notesMax) {
      return 'Notes must be at most $notesMax characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Dates (used later for reading_date, service_date).
  // Keep it simple: never in the future, never before 1900.
  // ---------------------------------------------------------------
  static String? dateInPastOrToday(DateTime? value) {
    if (value == null) return 'Please choose a date.';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(value.year, value.month, value.day);
    if (d.isBefore(DateTime(1900))) return 'Date is too far in the past.';
    if (d.isAfter(today)) return 'Date cannot be in the future.';
    return null;
  }

  // A permissive range for due_date (renewals) which CAN be in the future.
  static String? dateReasonable(DateTime? value) {
    if (value == null) return 'Please choose a date.';
    if (value.year < 1900 || value.year > 2100) {
      return 'Date is out of the expected range.';
    }
    return null;
  }
}