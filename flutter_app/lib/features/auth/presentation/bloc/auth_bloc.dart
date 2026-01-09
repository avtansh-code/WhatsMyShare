import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/reset_password.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for handling authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail _signInWithEmail;
  final SignUpWithEmail _signUpWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final ResetPassword _resetPassword;
  final EncryptionService _encryptionService;
  final LoggingService _log = LoggingService();

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required SignInWithEmail signInWithEmail,
    required SignUpWithEmail signUpWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required ResetPassword resetPassword,
    required EncryptionService encryptionService,
  }) : _signInWithEmail = signInWithEmail,
       _signUpWithEmail = signUpWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _resetPassword = resetPassword,
       _encryptionService = encryptionService,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthUserPhotoUpdated>(_onUserPhotoUpdated);

    _log.info('AuthBloc initialized', tag: LogTags.auth);

    // Listen to auth state changes
    _authStateSubscription = _getCurrentUser.authStateChanges.listen((user) {
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
      final user = await _getCurrentUser();
      if (user != null) {
        _log.info(
          'User authenticated',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        // Initialize encryption service for the authenticated user
        await _initializeEncryption(user.id);
        emit(AuthAuthenticated(user));
      } else {
        _log.info('User not authenticated', tag: LogTags.auth);
        emit(AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      _log.error(
        'Auth check failed',
        tag: LogTags.auth,
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthError(ErrorMessages.genericError));
    }
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Sign in with email requested',
      tag: LogTags.auth,
      data: {'email': event.email},
    );
    emit(AuthLoading());

    final result = await _signInWithEmail(
      SignInParams(email: event.email, password: event.password),
    );

    await result.fold(
      (failure) async {
        _log.warning(
          'Sign in failed',
          tag: LogTags.auth,
          data: {'email': event.email, 'error': failure.message},
        );
        final errorMessage = ErrorMessages.fromFailure(failure);
        emit(AuthError(errorMessage));
      },
      (user) async {
        _log.info(
          'Sign in successful',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        // Initialize encryption service for the authenticated user
        await _initializeEncryption(user.id);
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Sign up with email requested',
      tag: LogTags.auth,
      data: {'email': event.email},
    );
    emit(AuthLoading());

    final result = await _signUpWithEmail(
      SignUpParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );

    await result.fold(
      (failure) async {
        _log.warning(
          'Sign up failed',
          tag: LogTags.auth,
          data: {'email': event.email, 'error': failure.message},
        );
        final errorMessage = ErrorMessages.fromFailure(failure);
        emit(AuthError(errorMessage));
      },
      (user) async {
        _log.info(
          'Sign up successful',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        // Initialize encryption service for the authenticated user
        await _initializeEncryption(user.id);
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('Sign in with Google requested', tag: LogTags.auth);
    emit(AuthLoading());

    final result = await _signInWithGoogle();

    await result.fold(
      (failure) async {
        _log.warning(
          'Google sign in failed',
          tag: LogTags.auth,
          data: {'error': failure.message},
        );
        final errorMessage = failure.message.contains('cancelled')
            ? ErrorMessages.authGoogleSignInCancelled
            : ErrorMessages.authGoogleSignInFailed;
        emit(AuthError(errorMessage));
      },
      (user) async {
        _log.info(
          'Google sign in successful',
          tag: LogTags.auth,
          data: {'userId': user.id},
        );
        // Initialize encryption service for the authenticated user
        await _initializeEncryption(user.id);
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

    final result = await _signOut();

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
        // Clear encryption cache on sign out
        _encryptionService.clearCache();
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info(
      'Password reset requested',
      tag: LogTags.auth,
      data: {'email': event.email},
    );
    emit(AuthLoading());

    final result = await _resetPassword(
      ResetPasswordParams(email: event.email),
    );

    result.fold(
      (failure) {
        _log.warning(
          'Password reset failed',
          tag: LogTags.auth,
          data: {'email': event.email, 'error': failure.message},
        );
        emit(AuthError(ErrorMessages.authResetPasswordFailed));
      },
      (_) {
        _log.info(
          'Password reset email sent',
          tag: LogTags.auth,
          data: {'email': event.email},
        );
        emit(AuthPasswordResetSent(event.email));
      },
    );
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      _log.debug(
        'Auth state changed: authenticated',
        tag: LogTags.auth,
        data: {'userId': event.user!.id},
      );
      // Initialize encryption service for the authenticated user
      await _initializeEncryption(event.user!.id);
      emit(AuthAuthenticated(event.user!));
    } else {
      _log.debug('Auth state changed: unauthenticated', tag: LogTags.auth);
      // Clear encryption cache on sign out
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

  /// Initialize encryption service for a user
  Future<void> _initializeEncryption(String userId) async {
    if (!_encryptionService.isInitialized) {
      _log.debug(
        'Initializing encryption service',
        tag: LogTags.auth,
        data: {'userId': userId},
      );
      try {
        await _encryptionService.initialize(userId);
        _log.info(
          'Encryption service initialized',
          tag: LogTags.auth,
          data: {'userId': userId},
        );
      } catch (e, stackTrace) {
        _log.error(
          'Failed to initialize encryption service',
          tag: LogTags.auth,
          error: e,
          stackTrace: stackTrace,
        );
        // Don't throw - encryption failure shouldn't block auth
        // Features using encryption will handle the error gracefully
      }
    }
  }

  @override
  Future<void> close() {
    _log.debug('AuthBloc closing', tag: LogTags.auth);
    _authStateSubscription?.cancel();
    return super.close();
  }
}
