part of 'auth_bloc.dart';

/// Base class for authentication events
abstract class AuthEvent {
  const AuthEvent();

  List<Object?> get props => [];
}

/// Check if user is currently authenticated
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Submit phone number for verification
class AuthPhoneNumberSubmitted extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneNumberSubmitted(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// Submit OTP for verification
class AuthOtpSubmitted extends AuthEvent {
  final String otp;

  const AuthOtpSubmitted(this.otp);

  @override
  List<Object?> get props => [otp];
}

/// Request to resend OTP
class AuthResendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const AuthResendOtpRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// Complete user profile after first sign in
class AuthCompleteProfileRequested extends AuthEvent {
  final String displayName;
  final String? photoUrl;
  final String? defaultCurrency;
  final String? countryCode;

  const AuthCompleteProfileRequested({
    required this.displayName,
    this.photoUrl,
    this.defaultCurrency,
    this.countryCode,
  });

  @override
  List<Object?> get props => [
    displayName,
    photoUrl,
    defaultCurrency,
    countryCode,
  ];
}

/// Request sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User state changed (from auth state stream)
class AuthUserChanged extends AuthEvent {
  final UserEntity? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// User photo was updated
class AuthUserPhotoUpdated extends AuthEvent {
  final String photoUrl;

  const AuthUserPhotoUpdated(this.photoUrl);

  @override
  List<Object?> get props => [photoUrl];
}
