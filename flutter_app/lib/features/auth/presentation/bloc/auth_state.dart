part of 'auth_bloc.dart';

/// Base class for authentication states
abstract class AuthState {
  const AuthState();

  List<Object?> get props => [];
}

/// Initial state before any auth check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Phone verification is in progress
class AuthPhoneVerificationInProgress extends AuthState {
  final String phoneNumber;

  const AuthPhoneVerificationInProgress(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// OTP has been sent to the phone
class AuthOtpSent extends AuthState {
  final String verificationId;

  const AuthOtpSent({required this.verificationId});

  @override
  List<Object?> get props => [verificationId];
}

/// User needs to complete their profile
class AuthNeedsProfileCompletion extends AuthState {
  final UserEntity user;

  const AuthNeedsProfileCompletion(this.user);

  @override
  List<Object?> get props => [user];
}

/// Authentication error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}