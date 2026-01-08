import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import '../../features/profile/data/datasources/user_profile_datasource.dart';
import '../../features/profile/data/repositories/user_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/groups/data/datasources/group_datasource.dart';
import '../../features/groups/data/repositories/group_repository_impl.dart';
import '../../features/groups/domain/repositories/group_repository.dart';
import '../../features/groups/presentation/bloc/group_bloc.dart';
import '../../features/expenses/data/datasources/expense_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../features/settlements/data/datasources/settlement_datasource.dart';
import '../../features/settlements/data/repositories/settlement_repository_impl.dart';
import '../../features/settlements/domain/repositories/settlement_repository.dart';
import '../../features/settlements/presentation/bloc/settlement_bloc.dart';

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
  await _initGroupFeature();
  await _initExpenseFeature();
  await _initSettlementFeature();
}

/// Initialize external dependencies (Firebase, etc.)
void _initExternal() {
  // Firebase Auth
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Firestore
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Firebase Storage
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Google Sign In
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(scopes: ['email', 'profile']),
  );
}

/// Initialize core services
void _initCore() {
  // Network info, local storage, etc. can be added here
}

/// Initialize authentication feature
Future<void> _initAuthFeature() async {
  await _initProfileFeature();

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

/// Initialize profile feature
Future<void> _initProfileFeature() async {
  // Data Sources
  sl.registerLazySingleton<UserProfileDataSource>(
    () => UserProfileDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(dataSource: sl<UserProfileDataSource>()),
  );

  // BLoC
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(repository: sl<UserProfileRepository>()),
  );
}

/// Initialize groups feature
Future<void> _initGroupFeature() async {
  // Data Sources
  sl.registerLazySingleton<GroupDataSource>(
    () => GroupDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(dataSource: sl<GroupDataSource>()),
  );

  // BLoC
  sl.registerFactory<GroupBloc>(
    () => GroupBloc(groupRepository: sl<GroupRepository>()),
  );
}

/// Initialize expenses feature
Future<void> _initExpenseFeature() async {
  // Data Sources
  sl.registerLazySingleton<ExpenseDatasource>(
    () => FirebaseExpenseDatasource(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      storage: sl<FirebaseStorage>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(datasource: sl<ExpenseDatasource>()),
  );

  // BLoC
  sl.registerFactory<ExpenseBloc>(
    () => ExpenseBloc(expenseRepository: sl<ExpenseRepository>()),
  );
}

/// Initialize settlements feature
Future<void> _initSettlementFeature() async {
  // Data Sources
  sl.registerLazySingleton<SettlementDataSource>(
    () => SettlementDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<SettlementRepository>(
    () => SettlementRepositoryImpl(dataSource: sl<SettlementDataSource>()),
  );

  // BLoC
  sl.registerFactory<SettlementBloc>(
    () => SettlementBloc(repository: sl<SettlementRepository>()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
  await initializeDependencies();
}
