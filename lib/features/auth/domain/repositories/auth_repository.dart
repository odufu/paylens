import 'dart:typed_data';
import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';
import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> signInWithGoogle();

  Future<Result<UserProfileEntity>> getProfile(String userId);

  Future<Result<void>> updateProfileName({
    required String userId,
    required String fullName,
  });

  Future<Result<String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  });

  Stream<UserEntity?> get onAuthStateChanged;

  UserEntity? get currentUser;
}
