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
import 'package:mspay/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignInWithGoogleUseCase extends Mock implements SignInWithGoogleUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}
class MockUpdateProfileNameUseCase extends Mock implements UpdateProfileNameUseCase {}
class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockSignInUseCase mockSignInUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileNameUseCase mockUpdateProfileNameUseCase;
  late MockUploadAvatarUseCase mockUploadAvatarUseCase;
  late MockAuthRepository mockAuthRepository;
  late AuthProvider provider;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileNameUseCase = MockUpdateProfileNameUseCase();
    mockUploadAvatarUseCase = MockUploadAvatarUseCase();
    mockAuthRepository = MockAuthRepository();

    when(() => mockAuthRepository.currentUser).thenReturn(null);
    when(() => mockAuthRepository.onAuthStateChanged).thenAnswer((_) => const Stream.empty());

    provider = AuthProvider(
      signInUseCase: mockSignInUseCase,
      signInWithGoogleUseCase: mockSignInWithGoogleUseCase,
      signUpUseCase: mockSignUpUseCase,
      signOutUseCase: mockSignOutUseCase,
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileNameUseCase: mockUpdateProfileNameUseCase,
      uploadAvatarUseCase: mockUploadAvatarUseCase,
      authRepository: mockAuthRepository,
    );
  });

  group('AuthProvider Tests', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tFullName = 'Test User';
    const tUserId = 'user123';
    const tUser = UserEntity(id: tUserId, email: tEmail);
    const tProfile = UserProfileEntity(id: tUserId, fullName: tFullName);

    test('Initial values are set correctly', () {
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.user, null);
    });

    test('signIn triggers success state update', () async {
      // Set up mocks
      when(() => mockSignInUseCase(email: tEmail, password: tPassword))
          .thenAnswer((_) async => const Result.success(tUser));
      when(() => mockGetProfileUseCase(tUserId))
          .thenAnswer((_) async => const Result.success(tProfile));

      // Execute sign in
      await provider.signIn(email: tEmail, password: tPassword);

      // Assert state changes
      expect(provider.isAuthenticated, true);
      expect(provider.user, tUser);
      expect(provider.profile, tProfile);
      expect(provider.userFullName, tFullName);
      expect(provider.isLoading, false);
    });

    test('signIn propagates exception on failure', () async {
      when(() => mockSignInUseCase(email: tEmail, password: tPassword))
          .thenAnswer((_) async => const Result.error(AuthFailure('Invalid details')));

      await expectLater(
        provider.signIn(email: tEmail, password: tPassword),
        throwsException,
      );
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
    });

    test('signOut clears authenticated user state', () async {
      // Mock sign out
      when(() => mockSignOutUseCase()).thenAnswer((_) async => const Result.success(null));

      await provider.signOut();

      expect(provider.isAuthenticated, false);
      expect(provider.user, null);
      expect(provider.profile, null);
    });

    test('signInWithGoogle triggers success state', () async {
      when(() => mockSignInWithGoogleUseCase())
          .thenAnswer((_) async => const Result.success(null));

      await provider.signInWithGoogle();

      expect(provider.isLoading, false);
    });

    test('signInWithGoogle propagates exception on failure', () async {
      when(() => mockSignInWithGoogleUseCase())
          .thenAnswer((_) async => const Result.error(AuthFailure('Cancelled')));

      await expectLater(
        provider.signInWithGoogle(),
        throwsException,
      );
      expect(provider.isLoading, false);
    });
  });
}
