import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Result<void>> call({
    required String email,
    required String password,
    required String fullName,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}
