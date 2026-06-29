import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Result<void>> call() {
    return repository.signOut();
  }
}
