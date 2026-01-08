import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

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

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required SignInWithEmail signInWithEmail,
    required SignUpWithEmail signUpWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required ResetPassword resetPassword,
  })  : _signInWithEmail = signInWithEmail,
        _signUpWithEmail = signUpWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _resetPassword = resetPassword,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUserChanged>(_onUserChanged);

    // Listen to auth state changes
    _authStateSubscription = _getCurrentUser.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = await _getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signInWithEmail(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signUpWithEmail(
      SignUpParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _resetPassword(
      ResetPasswordParams(email: event.email),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent(event.email)),
    );
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}