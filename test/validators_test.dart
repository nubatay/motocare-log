// test/validators_test.dart
//
// Unit tests for lib/core/validators.dart.
// Each group() tests one validator. Each test() checks one scenario.
// Pattern: expect(Validators.x(badInput), isNotNull)  → "rejected".
//          expect(Validators.x(goodInput), isNull)    → "accepted".

import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_log/core/validators.dart';

void main() {
  group('name', () {
    test('accepts a normal name', () {
      expect(Validators.name('Ali'), isNull);
    });

    test('rejects empty and whitespace-only', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('   '), isNotNull);
      expect(Validators.name(null), isNotNull);
    });

    test('rejects names longer than 80 characters', () {
      expect(Validators.name('a' * 81), isNotNull);
      expect(Validators.name('a' * 80), isNull);
    });
  });

  group('email', () {
    test('accepts typical addresses', () {
      expect(Validators.email('ali@example.com'), isNull);
      expect(Validators.email('a.b+c@sub.example.co'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(Validators.email('  ali@example.com  '), isNull);
    });

    test('rejects obvious mistakes', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ali@'), isNotNull);
      expect(Validators.email('ali.example.com'), isNotNull);
      expect(Validators.email('ali @example.com'), isNotNull);
      expect(Validators.email('ali@example'), isNotNull); // no TLD
    });

    test('rejects too-long addresses', () {
      // 245 chars local part + "@a.com" = 251; over 254 when padded.
      final tooLong = '${'a' * 250}@example.com';
      expect(Validators.email(tooLong), isNotNull);
    });
  });

  group('password', () {
    test('accepts 8 chars with letter + digit', () {
      expect(Validators.password('abc12345'), isNull);
    });

    test('rejects too short', () {
      expect(Validators.password('abc1234'), isNotNull); // 7 chars
    });

    test('rejects too long (bcrypt cap = 72)', () {
    expect(Validators.password('a1${'x' * 70}'), isNull);     // 72 chars: OK
    expect(Validators.password('a1${'x' * 71}'), isNotNull);  // 73 chars: fail
    });

    test('requires at least one letter and one digit', () {
      expect(Validators.password('abcdefgh'), isNotNull);  // no digit
      expect(Validators.password('12345678'), isNotNull);  // no letter
      expect(Validators.password('!@#\$%^&*'), isNotNull); // neither
    });

    test('does NOT trim (spaces are meaningful in passwords)', () {
      // Same length as above but includes a trailing space; must still pass.
      expect(Validators.password('abc1234 '), isNull);
      // And " abc1234" must NOT be silently equal to "abc1234".
      expect(Validators.password(' abc1234'), isNull); // 8 chars, allowed
    });
  });

  group('confirmPassword', () {
    test('accepts identical strings', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
    });

    test('rejects mismatch and empty', () {
      expect(Validators.confirmPassword('abc12345', 'abc12346'), isNotNull);
      expect(Validators.confirmPassword('', 'abc12345'), isNotNull);
    });
  });

  group('nickname', () {
    test('accepts short nickname', () {
      expect(Validators.nickname('My Bike'), isNull);
    });

    test('rejects empty and too long', () {
      expect(Validators.nickname(''), isNotNull);
      expect(Validators.nickname('n' * 41), isNotNull);
      expect(Validators.nickname('n' * 40), isNull);
    });
  });

  group('model', () {
    test('accepts typical model', () {
      expect(Validators.model('Yamaha NMAX'), isNull);
    });

    test('rejects empty and too long', () {
      expect(Validators.model('  '), isNotNull);
      expect(Validators.model('m' * 61), isNotNull);
    });
  });

  group('year', () {
    test('empty is allowed (optional field)', () {
      expect(Validators.year(''), isNull);
      expect(Validators.year(null), isNull);
    });

    test('accepts 1950 and currentYear+1', () {
      expect(Validators.year('1950'), isNull);
      expect(Validators.year('${DateTime.now().year + 1}'), isNull);
    });

    test('rejects non-numeric, too low, too high', () {
      expect(Validators.year('abc'), isNotNull);
      expect(Validators.year('1949'), isNotNull);
      expect(Validators.year('${DateTime.now().year + 2}'), isNotNull);
    });
  });

  group('odometer', () {
    test('accepts whole numbers including zero', () {
      expect(Validators.odometer('0'), isNull);
      expect(Validators.odometer('12345'), isNull);
    });

    test('rejects decimals and non-numeric', () {
      expect(Validators.odometer('12.5'), isNotNull);
      expect(Validators.odometer('12abc'), isNotNull);
    });

    test('rejects empty and negative', () {
      expect(Validators.odometer(''), isNotNull);
      expect(Validators.odometer('-1'), isNotNull);
    });

    test('rejects over 2,000,000', () {
      expect(Validators.odometer('2000001'), isNotNull);
    });
  });

  group('dailyDistance', () {
    test('empty is allowed', () {
      expect(Validators.dailyDistance(''), isNull);
    });

    test('accepts 0 and one decimal place', () {
      expect(Validators.dailyDistance('0'), isNull);
      expect(Validators.dailyDistance('25.5'), isNull);
    });

    test('rejects two decimal places', () {
      expect(Validators.dailyDistance('25.55'), isNotNull);
    });

    test('rejects negative and too large', () {
      expect(Validators.dailyDistance('-1'), isNotNull);
      expect(Validators.dailyDistance('2000.1'), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.dailyDistance('abc'), isNotNull);
    });
  });

  group('cost', () {
    test('empty is allowed', () {
      expect(Validators.cost(''), isNull);
    });

    test('accepts integer and two decimals', () {
      expect(Validators.cost('250'), isNull);
      expect(Validators.cost('250.50'), isNull);
    });

    test('rejects three decimals', () {
      expect(Validators.cost('250.555'), isNotNull);
    });

    test('rejects negative and too large', () {
      expect(Validators.cost('-1'), isNotNull);
      expect(Validators.cost('1000001'), isNotNull);
    });
  });

  group('notes', () {
    test('empty is allowed', () {
      expect(Validators.notes(''), isNull);
      expect(Validators.notes(null), isNull);
    });

    test('rejects over 1000 characters', () {
      expect(Validators.notes('n' * 1001), isNotNull);
      expect(Validators.notes('n' * 1000), isNull);
    });
  });

  group('dateInPastOrToday', () {
    test('today and yesterday are accepted', () {
      final now = DateTime.now();
      expect(Validators.dateInPastOrToday(now), isNull);
      expect(
        Validators.dateInPastOrToday(now.subtract(const Duration(days: 1))),
        isNull,
      );
    });

    test('tomorrow is rejected', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(Validators.dateInPastOrToday(tomorrow), isNotNull);
    });

    test('null and pre-1900 are rejected', () {
      expect(Validators.dateInPastOrToday(null), isNotNull);
      expect(Validators.dateInPastOrToday(DateTime(1850)), isNotNull);
    });
  });

  group('dateReasonable', () {
    test('accepts 1900 and 2100 boundaries', () {
      expect(Validators.dateReasonable(DateTime(1900)), isNull);
      expect(Validators.dateReasonable(DateTime(2100)), isNull);
    });

    test('rejects out-of-range and null', () {
      expect(Validators.dateReasonable(DateTime(1899)), isNotNull);
      expect(Validators.dateReasonable(DateTime(2101)), isNotNull);
      expect(Validators.dateReasonable(null), isNotNull);
    });
  });
}