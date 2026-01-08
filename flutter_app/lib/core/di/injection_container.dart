import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ==================== External ====================
  _initExternal();

  // ==================== Core ====================
  _initCore();

  // ==================== Features ====================
  await _initAuthFeature();
}

/// Initialize external dependencies (Firebase, etc.)
void _initExternal() {
  // Firebase Auth
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Firestore
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Google Sign In
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
        scopes: ['email', 'profile'],
      ));
}

/// Initialize core services
void _initCore() {
  // Network info, local storage, etc. can be added here
}

/// Initialize authentication feature
Future<void> _initAuthFeature() async {
  // Data Sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl<FirebaseAuthDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPassword(sl<AuthRepository>()));

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithEmail: sl<SignInWithEmail>(),
      signUpWithEmail: sl<SignUpWithEmail>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signOut: sl<SignOut>(),
      getCurrentUser: sl<GetCurrentUser>(),
      resetPassword: sl<ResetPassword>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
  await initializeDependencies();
}  // BLoC
