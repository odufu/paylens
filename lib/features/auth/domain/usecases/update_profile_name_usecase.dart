import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileNameUseCase {
  final AuthRepository repository;

  UpdateProfileNameUseCase(this.repository);

  Future<Result<void>> call({
    required String userId,
    required String fullName,
  }) {
    return repository.updateProfileName(
      userId: userId,
      fullName: fullName,
    );
  }
}
