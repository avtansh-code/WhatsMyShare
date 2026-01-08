import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../repositories/auth_repository.dart';

/// Use case for resetting password via email
class ResetPassword {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  ResetPassword(this.repository);

  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    _log.info(
      'Executing ResetPassword usecase',
      tag: LogTags.auth,
      data: {'email': params.email},
    );

    final result = await repository.resetPassword(email: params.email);

    result.fold(
      (failure) => _log.warning(
        'ResetPassword failed',
        tag: LogTags.auth,
        data: {
          'email': params.email,
          'failure': failure.runtimeType.toString(),
        },
      ),
      (_) => _log.info(
        'ResetPassword email sent',
        tag: LogTags.auth,
        data: {'email': params.email},
      ),
    );

    return result;
  }
}

/// Parameters for password reset
class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({required this.email});

  @override
  List<Object?> get props => [email];
}
