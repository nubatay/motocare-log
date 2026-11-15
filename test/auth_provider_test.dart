import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_log/features/auth/data/auth_repository.dart';
import 'package:motocare_log/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A fake repository that we control
class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (shouldFail) throw const AuthFailure('Fake error');
    // Do nothing on success
  }

  @override
  Future<void> signUp({required String email, required String password, required String name}) async {}

  @override
  Future<void> signOut() async {}

  // Required by the interface but we don't use it in the fake
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthProvider', () {
    test('login sets isLoading and handles success', () async {
      final fakeRepo = FakeAuthRepository();
      final provider = AuthProvider(fakeRepo);

      expect(provider.isLoading, isFalse);

      final future = provider.login(email: 'a@b.com', password: '12345678');
      
      // Immediately after calling login, it should be loading
      expect(provider.isLoading, isTrue);

      final success = await future; // Wait for it to finish

      expect(success, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('login handles failure', () async {
      final fakeRepo = FakeAuthRepository()..shouldFail = true;
      final provider = AuthProvider(fakeRepo);

      final success = await provider.login(email: 'a@b.com', password: '12345678');

      expect(success, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Fake error'); // Caught the AuthFailure!
    });
  });
}