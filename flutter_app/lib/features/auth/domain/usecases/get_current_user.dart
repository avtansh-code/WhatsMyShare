import '../../../../core/services/logging_service.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUser {
  final AuthRepository repository;
  final LoggingService _log = LoggingService();

  GetCurrentUser(this.repository);

  /// Get auth state changes stream
  Stream<UserEntity?> get authStateChanges {
    _log.debug('Getting authStateChanges stream', tag: LogTags.auth);
    return repository.authStateChanges;
  }

  /// Get current user (one-time check)
  Future<UserEntity?> call() async {
    _log.debug('Executing GetCurrentUser usecase', tag: LogTags.auth);

    final user = await repository.getCurrentUser();

    _log.debug(
      'GetCurrentUser completed',
      tag: LogTags.auth,
      data: {'hasUser': user != null, 'userId': user?.id},
    );

    return user;
  }
}
