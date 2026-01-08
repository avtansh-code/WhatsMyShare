import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the currently authenticated user
class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges => repository.authStateChanges;
}
