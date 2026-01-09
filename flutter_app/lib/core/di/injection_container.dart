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
import '../../features/expenses/data/datasources/expense_chat_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../features/expenses/presentation/bloc/chat_bloc.dart';
import '../../features/settlements/data/datasources/settlement_datasource.dart';
import '../../features/settlements/data/repositories/settlement_repository_impl.dart';
import '../../features/settlements/domain/repositories/settlement_repository.dart';
import '../../features/settlements/presentation/bloc/settlement_bloc.dart';
import '../../features/notifications/data/datasources/notification_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../services/audio_service.dart';
import '../services/encryption_service.dart';
import '../services/logging_service.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_queue_manager.dart';
import '../services/sync_service.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Logging helper for DI initialization
final _log = LoggingService();

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  _log.info('Initializing dependencies', tag: LogTags.app);

  // ==================== External ====================
  _initExternal();
  _log.debug('External dependencies initialized', tag: LogTags.app);

  // ==================== Core ====================
  _initCore();
  _log.debug('Core services initialized', tag: LogTags.app);

  // ==================== Features ====================
  await _initAuthFeature();
  _log.debug('Auth feature initialized', tag: LogTags.app);

  await _initGroupFeature();
  _log.debug('Group feature initialized', tag: LogTags.app);

  await _initExpenseFeature();
  _log.debug('Expense feature initialized', tag: LogTags.app);

  await _initSettlementFeature();
  _log.debug('Settlement feature initialized', tag: LogTags.app);

  await _initNotificationFeature();
  _log.debug('Notification feature initialized', tag: LogTags.app);

  _log.info('All dependencies initialized successfully', tag: LogTags.app);
}

/// Initialize external dependencies (Firebase, etc.)
void _initExternal() {
  _log.debug('Registering external dependencies', tag: LogTags.app);

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
  _log.debug('Registering core services', tag: LogTags.app);

  // Logging Service (singleton - same instance throughout app)
  sl.registerLazySingleton<LoggingService>(() => LoggingService());

  // Analytics Service (singleton)
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Connectivity Service (singleton - using concrete implementation)
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // Sync Service (singleton - uses default Firebase instances internally)
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Offline Queue Manager (singleton - depends on connectivity and sync service)
  sl.registerLazySingleton<OfflineQueueManager>(
    () => OfflineQueueManagerImpl(
      connectivityService: sl<ConnectivityService>(),
      operationExecutor: sl<SyncService>().executeOperation,
    ),
  );

  // Audio Service (factory - new instance for each use case)
  sl.registerFactory<AudioService>(() => AudioService());

  // Encryption Service (singleton - uses same key for all encryption)
  sl.registerLazySingleton<EncryptionService>(() => EncryptionService());
}

/// Initialize authentication feature
Future<void> _initAuthFeature() async {
  _log.debug('Initializing auth feature', tag: LogTags.auth);

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
      encryptionService: sl<EncryptionService>(),
    ),
  );
}

/// Initialize profile feature
Future<void> _initProfileFeature() async {
  _log.debug('Initializing profile feature', tag: LogTags.profile);

  // Data Sources
  sl.registerLazySingleton<UserProfileDataSource>(
    () => UserProfileDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
      auth: sl<FirebaseAuth>(),
      encryptionService: sl<EncryptionService>(),
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
  _log.debug('Initializing groups feature', tag: LogTags.groups);

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
  _log.debug('Initializing expenses feature', tag: LogTags.expenses);

  // Data Sources
  sl.registerLazySingleton<ExpenseDatasource>(
    () => FirebaseExpenseDatasource(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      storage: sl<FirebaseStorage>(),
      encryptionService: sl<EncryptionService>(),
    ),
  );

  // Expense Chat Data Source
  sl.registerLazySingleton<ExpenseChatDataSource>(
    () => ExpenseChatDataSource(
      firestore: sl<FirebaseFirestore>(),
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

  // Chat BLoC
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(
      chatDataSource: sl<ExpenseChatDataSource>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}

/// Initialize settlements feature
Future<void> _initSettlementFeature() async {
  _log.debug('Initializing settlements feature', tag: LogTags.settlements);

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

/// Initialize notifications feature
Future<void> _initNotificationFeature() async {
  _log.debug('Initializing notifications feature', tag: LogTags.notifications);

  // Data Sources
  sl.registerLazySingleton<NotificationDataSource>(
    () => NotificationDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      dataSource: sl<NotificationDataSource>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // BLoC
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(repository: sl<NotificationRepository>()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  _log.warning('Resetting all dependencies', tag: LogTags.app);
  await sl.reset();
  await initializeDependencies();
  _log.info('Dependencies reset complete', tag: LogTags.app);
}
