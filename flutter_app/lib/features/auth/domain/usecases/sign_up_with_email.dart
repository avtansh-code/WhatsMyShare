import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up with email and password
class SignUpWithEmail {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  SignUpWithEmail(this.repository);

  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    _log.info(
      'Executing SignUpWithEmail usecase',
      tag: LogTags.auth,
      data: {'email': params.email, 'displayName': params.displayName},
    );

    final result = await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );

    result.fold(
      (failure) => _log.warning(
        'SignUpWithEmail failed',
        tag: LogTags.auth,
        data: {'failure': failure.runtimeType.toString()},
      ),
      (user) => _log.info(
        'SignUpWithEmail succeeded',
        tag: LogTags.auth,
        data: {'userId': user.id},
      ),
    );

    return result;
  }
}

/// Parameters for sign up with email
class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}
