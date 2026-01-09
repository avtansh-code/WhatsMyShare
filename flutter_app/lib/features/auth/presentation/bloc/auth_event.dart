part of 'auth_bloc.dart';

/// Base class for auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is authenticated
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign in with email and password
class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Sign up with email and password
class AuthSignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in with Google
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Request password reset email
class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Auth state changed (from stream)
class AuthUserChanged extends AuthEvent {
  final UserEntity? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// User photo URL updated (sync from ProfileBloc)
class AuthUserPhotoUpdated extends AuthEvent {
  final String? photoUrl;

  const AuthUserPhotoUpdated({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}
