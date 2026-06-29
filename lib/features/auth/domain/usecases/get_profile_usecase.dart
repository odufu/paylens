import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  Future<Result<UserProfileEntity>> call(String userId) {
    return repository.getProfile(userId);
  }
}
