abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class Result<T> {
  final T? value;
  final Failure? failure;

  const Result.success(T val)
      : value = val,
        failure = null;

  const Result.error(Failure fail)
      : value = null,
        failure = fail;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;
}
