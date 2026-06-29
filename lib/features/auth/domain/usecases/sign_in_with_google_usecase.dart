import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  Future<Result<void>> call() {
    return repository.signInWithGoogle();
  }
}
