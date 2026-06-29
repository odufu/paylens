import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';
import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  UserEntity? get currentUser => remoteDataSource.currentUser;

  @override
  Stream<UserEntity?> get onAuthStateChanged => remoteDataSource.onAuthStateChanged;

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Result.success(user);
    } on AuthException catch (e) {
      return Result.error(AuthFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.error(AuthFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      await remoteDataSource.signInWithGoogle();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.error(AuthFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserProfileEntity>> getProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getProfile(userId);
      return Result.success(profile);
    } on PostgrestException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateProfileName({
    required String userId,
    required String fullName,
  }) async {
    try {
      await remoteDataSource.updateProfileName(
        userId: userId,
        fullName: fullName,
      );
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      final publicUrl = await remoteDataSource.uploadAvatar(
        userId: userId,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      return Result.success(publicUrl);
    } on StorageException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }
}
