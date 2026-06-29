import 'dart:typed_data';
import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class UploadAvatarUseCase {
  final AuthRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<Result<String>> call({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    return repository.uploadAvatar(
      userId: userId,
      bytes: bytes,
      fileExtension: fileExtension,
    );
  }
}
