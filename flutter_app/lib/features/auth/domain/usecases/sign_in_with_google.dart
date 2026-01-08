import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with Google
class SignInWithGoogle {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  SignInWithGoogle(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    _log.info('Executing SignInWithGoogle usecase', tag: LogTags.auth);

    final result = await repository.signInWithGoogle();

    result.fold(
      (failure) => _log.warning(
        'SignInWithGoogle failed',
        tag: LogTags.auth,
        data: {'failure': failure.runtimeType.toString()},
      ),
      (user) => _log.info(
        'SignInWithGoogle succeeded',
        tag: LogTags.auth,
        data: {'userId': user.id, 'email': user.email},
      ),
    );

    return result;
  }
}
