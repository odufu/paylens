import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';
import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';
import 'package:mspay/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/update_profile_name_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInUseCase signInUseCase;
  late SignInWithGoogleUseCase signInWithGoogleUseCase;
  late SignUpUseCase signUpUseCase;
  late SignOutUseCase signOutUseCase;
  late GetProfileUseCase getProfileUseCase;
  late UpdateProfileNameUseCase updateProfileNameUseCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    signInUseCase = SignInUseCase(mockRepository);
    signInWithGoogleUseCase = SignInWithGoogleUseCase(mockRepository);
    signUpUseCase = SignUpUseCase(mockRepository);
    signOutUseCase = SignOutUseCase(mockRepository);
    getProfileUseCase = GetProfileUseCase(mockRepository);
    updateProfileNameUseCase = UpdateProfileNameUseCase(mockRepository);
  });

  group('Auth UseCases Tests', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tFullName = 'Test User';
    const tUserId = 'user123';

    test('SignInUseCase calls signIn on repository', () async {
      const tUser = UserEntity(id: tUserId, email: tEmail);
      when(() => mockRepository.signIn(email: tEmail, password: tPassword))
          .thenAnswer((_) async => const Result.success(tUser));

      final result = await signInUseCase(email: tEmail, password: tPassword);

      expect(result.isSuccess, true);
      expect(result.value, tUser);
      verify(() => mockRepository.signIn(email: tEmail, password: tPassword)).called(1);
    });

    test('SignUpUseCase calls signUp on repository', () async {
      when(() => mockRepository.signUp(email: tEmail, password: tPassword, fullName: tFullName))
          .thenAnswer((_) async => const Result.success(null));

      final result = await signUpUseCase(email: tEmail, password: tPassword, fullName: tFullName);

      expect(result.isSuccess, true);
      verify(() => mockRepository.signUp(email: tEmail, password: tPassword, fullName: tFullName)).called(1);
    });

    test('SignOutUseCase calls signOut on repository', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async => const Result.success(null));

      final result = await signOutUseCase();

      expect(result.isSuccess, true);
      verify(() => mockRepository.signOut()).called(1);
    });

    test('GetProfileUseCase calls getProfile on repository', () async {
      const tProfile = UserProfileEntity(id: tUserId, fullName: tFullName);
      when(() => mockRepository.getProfile(tUserId))
          .thenAnswer((_) async => const Result.success(tProfile));

      final result = await getProfileUseCase(tUserId);

      expect(result.isSuccess, true);
      expect(result.value, tProfile);
      verify(() => mockRepository.getProfile(tUserId)).called(1);
    });

    test('UpdateProfileNameUseCase calls updateProfileName on repository', () async {
      when(() => mockRepository.updateProfileName(userId: tUserId, fullName: tFullName))
          .thenAnswer((_) async => const Result.success(null));

      final result = await updateProfileNameUseCase(userId: tUserId, fullName: tFullName);

      expect(result.isSuccess, true);
      verify(() => mockRepository.updateProfileName(userId: tUserId, fullName: tFullName)).called(1);
    });

    test('SignInWithGoogleUseCase calls signInWithGoogle on repository', () async {
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Result.success(null));

      final result = await signInWithGoogleUseCase();

      expect(result.isSuccess, true);
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });
}
