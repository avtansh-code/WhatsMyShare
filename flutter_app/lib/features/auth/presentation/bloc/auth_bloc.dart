import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for handling phone-based authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final EncryptionService _encryptionService;
  final LoggingService _log;

  StreamSubscription<UserEntity?>? _authStateSubscription;

  // Phone verification state
  String? _verificationId;
  int? _resendToken;

  AuthBloc({
    required AuthRepository authRepository,
    required EncryptionService encryptionService,
    required LoggingService loggingService,
  }) : _authRepository = authRepository,
       _encryptionService = encryptionService,
       _log = loggingService,
       super(AuthInitial()) {
    // Auth check
    on<AuthCheckRequested>(_onAuthCheckRequested);

    // Phone authentication
    on<AuthPhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthResendOtpRequested>(_onResendOtpRequested);

    // Profile completion
    on<AuthCompleteProfileRequested>(_onCompleteProfileRequested);

    // Sign out
    on<AuthSignOutRequested>(_onSignOutRequested);

    // User state changes
    on<AuthUserChanged>(_onUserChanged);
    on<AuthUserPhotoUpdated>(_onUserPhotoUpdated);

    // Internal events for phone verification callbacks
    on<_AuthVerificationCompleted>(_onVerificationCompleted);
    on<_AuthVerificationFailed>(_onVerificationFailed);
    on<_AuthCodeSent>(_onCodeSent);

    _log.info('AuthBloc initialized (phone-only auth)', tag: LogTags.auth);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.debug('Checking auth state...', tag: LogTags.auth);
    emit(AuthLoading());

    try {
      final result = await _authRepository.getCurrentUser();

      await result.fold(
        (failure) async {
          _log.error('Auth check failed', tag: LogTags.auth, error: failure);
          emit(AuthUnauthenticated());
        },
        (user) async {
          if (user != null) {
            _log.info(
              'User authenticated',
              tag: LogTags.auth,
              data: {'userId': user.id, 'hasName': user.displayName != null},
            );

            // Initialize encryption service for the authenticated user
            await _initializeEncryption(user.id);

            // Check if emit is still valid before emitting
            if (emit.isDone) return;

            // Check if profile is complete (has display name)
            if (user.displayName == null || user.displayName!.isEmpty) {
              emit(AuthNeedsProfileCompletion(user));
            } else {
              emit(AuthAuthenticated(user));
            }
          } else {
            _log.info('User not authenticated', tag: LogTags.auth);
            emit(AuthUnauthenticated());
          }
        },
      );
    } catch (e, stackTrace) {
      _log.error(
        'Auth check failed',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      if (!emit.isDone) {
        emit(AuthError(ErrorMessages.genericError));
      }
    }
  }

  Future<void> _onPhoneNumberSubmitted(
    AuthPhoneNumberSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Phone number submitted',
      tag: LogTags.auth,
      data: {'phone': _maskPhone(event.phoneNumber)},
    );
    emit(AuthPhoneVerificationInProgress(event.phoneNumber));

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {
          add(_AuthVerificationCompleted(credential));
        },
        verificationFailed: (exception) {
          add(_AuthVerificationFailed(exception));
        },
        codeSent: (verificationId, resendToken) {
          add(_AuthCodeSent(verificationId, resendToken));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _log.debug('Auto retrieval timeout', tag: LogTags.auth);
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e, stackTrace) {
      _log.error(
        'Phone verification failed',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthError('Failed to send verification code'));
    }
  }

  void _onCodeSent(_AuthCodeSent event, Emitter<AuthState> emit) {
    _log.info('OTP code sent', tag: LogTags.auth);
    _verificationId = event.verificationId;
    _resendToken = event.resendToken;
    emit(AuthOtpSent(verificationId: event.verificationId));
  }

  Future<void> _onVerificationCompleted(
    _AuthVerificationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('Auto verification completed (Android)', tag: LogTags.auth);
    emit(AuthLoading());

    final result = await _authRepository.signInWithAutoRetrievedCredential(
      event.credential,
    );

    await result.fold(
      (failure) async {
        _log.error('Auto sign in failed', tag: LogTags.auth, error: failure);
        emit(AuthError(failure.message));
      },
      (user) async {
        _log.info(
          'Auto sign in successful',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        await _handleSuccessfulSignIn(user, emit);
      },
    );
  }

  void _onVerificationFailed(
    _AuthVerificationFailed event,
    Emitter<AuthState> emit,
  ) {
    _log.error(
      'Phone verification failed',
      tag: LogTags.auth,
      error: event.exception,
    );

    String errorMessage;
    switch (event.exception.code) {
      case 'invalid-phone-number':
        errorMessage = 'Invalid phone number format';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later.';
        break;
      case 'quota-exceeded':
        errorMessage = 'SMS quota exceeded. Please try again later.';
        break;
      default:
        errorMessage = event.exception.message ?? 'Verification failed';
    }

    emit(AuthError(errorMessage));
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('OTP submitted', tag: LogTags.auth);

    if (_verificationId == null) {
      _log.error('No verification ID available', tag: LogTags.auth);
      emit(AuthError('Session expired. Please request a new code.'));
      return;
    }

    emit(AuthLoading());

    final result = await _authRepository.signInWithPhoneCredential(
      verificationId: _verificationId!,
      smsCode: event.otp,
    );

    await result.fold(
      (failure) async {
        _log.warning(
          'OTP verification failed',
          tag: LogTags.auth,
          data: {'error': failure.message},
        );
        emit(AuthError(failure.message));
      },
      (user) async {
        _log.info(
          'OTP verification successful',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        await _handleSuccessfulSignIn(user, emit);
      },
    );
  }

  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Resend OTP requested',
      tag: LogTags.auth,
      data: {'phone': _maskPhone(event.phoneNumber)},
    );

    emit(AuthPhoneVerificationInProgress(event.phoneNumber));

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {
          add(_AuthVerificationCompleted(credential));
        },
        verificationFailed: (exception) {
          add(_AuthVerificationFailed(exception));
        },
        codeSent: (verificationId, resendToken) {
          add(_AuthCodeSent(verificationId, resendToken));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e, stackTrace) {
      _log.error(
        'Resend OTP failed',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthError('Failed to resend verification code'));
    }
  }

  Future<void> _onCompleteProfileRequested(
    AuthCompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Profile completion requested',
      tag: LogTags.auth,
      data: {'displayName': event.displayName},
    );
    emit(AuthLoading());

    final result = await _authRepository.completeProfileSetup(
      displayName: event.displayName,
      photoUrl: event.photoUrl,
      defaultCurrency: event.defaultCurrency,
      countryCode: event.countryCode,
    );

    result.fold(
      (failure) {
        _log.error(
          'Profile completion failed',
          tag: LogTags.auth,
          error: failure,
        );
        emit(AuthError(failure.message));
      },
      (user) {
        _log.info(
          'Profile completed successfully',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('Sign out requested', tag: LogTags.auth);
    emit(AuthLoading());

    final result = await _authRepository.signOut();

    result.fold(
      (failure) {
        _log.error(
          'Sign out failed',
          tag: LogTags.auth,
          data: {'error': failure.message},
        );
        emit(AuthError(ErrorMessages.authSignOutFailed));
      },
      (_) {
        _log.info('Sign out successful', tag: LogTags.auth);
        _verificationId = null;
        _resendToken = null;
        // Clear encryption cache on sign out
        _encryptionService.clearCache();
        _log.debug('Encryption cache cleared', tag: LogTags.auth);
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) async {
    if (event.user != null) {
      _log.debug(
        'Auth state changed: authenticated',
        tag: LogTags.auth,
        data: {'userId': event.user!.id},
      );

      // Initialize encryption service for the authenticated user
      await _initializeEncryption(event.user!.id);

      // Check if emit is still valid before emitting
      if (emit.isDone) return;

      // Check if profile is complete
      if (event.user!.displayName == null || event.user!.displayName!.isEmpty) {
        emit(AuthNeedsProfileCompletion(event.user!));
      } else {
        emit(AuthAuthenticated(event.user!));
      }
    } else {
      _log.debug('Auth state changed: unauthenticated', tag: LogTags.auth);
      // Clear encryption cache when user becomes unauthenticated
      _encryptionService.clearCache();
      emit(AuthUnauthenticated());
    }
  }

  void _onUserPhotoUpdated(
    AuthUserPhotoUpdated event,
    Emitter<AuthState> emit,
  ) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      _log.info(
        'Updating user photo URL in AuthBloc',
        tag: LogTags.auth,
        data: {'photoUrl': event.photoUrl},
      );
      final updatedUser = currentState.user.copyWith(photoUrl: event.photoUrl);
      emit(AuthAuthenticated(updatedUser));
    }
  }

  Future<void> _handleSuccessfulSignIn(UserEntity user, Emitter<AuthState> emit) async {
    // Clear verification state
    _verificationId = null;
    _resendToken = null;

    // Initialize encryption service for the authenticated user
    await _initializeEncryption(user.id);

    // Check if emit is still valid before emitting
    if (emit.isDone) return;

    // Check if profile is complete
    if (user.displayName == null || user.displayName!.isEmpty) {
      emit(AuthNeedsProfileCompletion(user));
    } else {
      emit(AuthAuthenticated(user));
    }
  }

  /// Initialize encryption service for the authenticated user
  Future<void> _initializeEncryption(String userId) async {
    try {
      if (!_encryptionService.isInitialized) {
        _log.info(
          'Initializing encryption service for user',
          tag: LogTags.auth,
          data: {'userId': userId},
        );
        await _encryptionService.initialize(userId);
        _log.info('Encryption service initialized', tag: LogTags.auth);
      } else {
        _log.debug(
          'Encryption service already initialized',
          tag: LogTags.auth,
        );
      }
    } catch (e, stackTrace) {
      _log.error(
        'Failed to initialize encryption service',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't fail authentication if encryption fails to initialize
      // The user can still use the app, but encrypted features may not work
    }
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return '****';
    return '****${phone.substring(phone.length - 4)}';
  }

  @override
  Future<void> close() {
    _log.debug('AuthBloc closing', tag: LogTags.auth);
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Internal events for phone verification callbacks
class _AuthVerificationCompleted extends AuthEvent {
  final firebase_auth.PhoneAuthCredential credential;
  _AuthVerificationCompleted(this.credential);

  @override
  List<Object?> get props => [credential];
}

class _AuthVerificationFailed extends AuthEvent {
  final firebase_auth.FirebaseAuthException exception;
  _AuthVerificationFailed(this.exception);

  @override
  List<Object?> get props => [exception];
}

class _AuthCodeSent extends AuthEvent {
  final String verificationId;
  final int? resendToken;
  _AuthCodeSent(this.verificationId, this.resendToken);

  @override
  List<Object?> get props => [verificationId, resendToken];
}
