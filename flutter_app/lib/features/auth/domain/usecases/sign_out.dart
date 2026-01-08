import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/logging_service.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOut {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  SignOut(this.repository);

  Future<Either<Failure, void>> call() async {
    _log.info('Executing SignOut usecase', tag: LogTags.auth);

    final result = await repository.signOut();

    result.fold(
      (failure) => _log.warning(
        'SignOut failed',
        tag: LogTags.auth,
        data: {'failure': failure.runtimeType.toString()},
      ),
      (_) => _log.info('SignOut succeeded', tag: LogTags.auth),
    );

    return result;
  }
}
