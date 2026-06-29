import 'package:mspay/core/error/failures.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}
