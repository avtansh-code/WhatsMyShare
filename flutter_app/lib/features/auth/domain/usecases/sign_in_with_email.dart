import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with email and password
class SignInWithEmail {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  SignInWithEmail(this.repository);

  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    _log.info(
      'Executing SignInWithEmail usecase',
      tag: LogTags.auth,
      data: {'email': params.email},
    );

    final result = await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );

    result.fold(
      (failure) => _log.warning(
        'SignInWithEmail failed',
        tag: LogTags.auth,
        data: {'failure': failure.runtimeType.toString()},
      ),
      (user) => _log.info(
        'SignInWithEmail succeeded',
        tag: LogTags.auth,
        data: {'userId': user.id},
      ),
    );

    return result;
  }
}

/// Parameters for sign in with email
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
