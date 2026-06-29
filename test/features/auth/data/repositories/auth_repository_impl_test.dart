import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mspay/features/auth/data/models/user_model.dart';
import 'package:mspay/features/auth/data/models/user_profile_model.dart';
import 'package:mspay/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  group('AuthRepositoryImpl Tests', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tFullName = 'Test User';
    const tUserId = 'user123';

    test('signIn returns UserModel on success', () async {
      const tUserModel = UserModel(id: tUserId, email: tEmail);
      when(() => mockRemoteDataSource.signIn(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUserModel);

      final result = await repository.signIn(email: tEmail, password: tPassword);

      expect(result.isSuccess, true);
      expect(result.value, tUserModel);
    });

    test('signIn returns AuthFailure on AuthException', () async {
      when(() => mockRemoteDataSource.signIn(email: tEmail, password: tPassword))
          .thenThrow(const AuthException('Invalid login credentials'));

      final result = await repository.signIn(email: tEmail, password: tPassword);

      expect(result.isFailure, true);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Invalid login credentials');
    });

    test('signIn returns ServerFailure on generic Exception', () async {
      when(() => mockRemoteDataSource.signIn(email: tEmail, password: tPassword))
          .thenThrow(Exception('Unknown network error'));

      final result = await repository.signIn(email: tEmail, password: tPassword);

      expect(result.isFailure, true);
      expect(result.failure, isA<ServerFailure>());
    });

    test('getProfile returns UserProfileModel on success', () async {
      const tProfileModel = UserProfileModel(id: tUserId, fullName: tFullName);
      when(() => mockRemoteDataSource.getProfile(tUserId))
          .thenAnswer((_) async => tProfileModel);

      final result = await repository.getProfile(tUserId);

      expect(result.isSuccess, true);
      expect(result.value, tProfileModel);
    });

    test('signInWithGoogle returns success on success', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenAnswer((_) async => {});

      final result = await repository.signInWithGoogle();

      expect(result.isSuccess, true);
    });

    test('signInWithGoogle returns AuthFailure on AuthException', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenThrow(const AuthException('Google Sign In cancelled'));

      final result = await repository.signInWithGoogle();

      expect(result.isFailure, true);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Google Sign In cancelled');
    });
  });
}
