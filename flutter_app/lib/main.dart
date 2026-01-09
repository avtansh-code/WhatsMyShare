import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/services/logging_service.dart';
import 'firebase_options.dart';

/// Logging service for app startup
final _log = LoggingService();

Future<void> main() async {
  // Set up error handling zone
  await runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();

      _log.info('=== WhatsMyShare App Starting ===', tag: LogTags.app);
      _log.info('Debug mode: $kDebugMode', tag: LogTags.app);

      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        _log.error(
          'Flutter error',
          tag: LogTags.app,
          error: details.exception,
          stackTrace: details.stack,
          data: {
            'library': details.library,
            'context': details.context?.toString(),
          },
        );
        // In debug mode, also print to console
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      // Set preferred orientations (portrait only for mobile)
      _log.debug('Setting preferred orientations', tag: LogTags.app);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI overlay style
      _log.debug('Setting system UI overlay style', tag: LogTags.app);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Initialize Hive for local storage (offline queue)
      _log.debug('Initializing Hive', tag: LogTags.app);
      await Hive.initFlutter();
      _log.debug('Hive initialized', tag: LogTags.app);

      // Initialize Firebase
      // On iOS, Firebase is already configured in AppDelegate.swift
      // to properly handle APNs for phone authentication
      _log.debug('Initializing Firebase', tag: LogTags.firebase);
      if (Platform.isIOS) {
        // Check if Firebase is already initialized (from AppDelegate)
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _log.info('Firebase initialized', tag: LogTags.firebase);

      // Configure Firebase Auth settings for phone authentication
      await _configureFirebaseAuth();

      // Handle first launch - clear stale auth state from iOS Keychain
      // This fixes the issue where Firebase Auth persists across app uninstalls on iOS
      await _handleFirstLaunchAuthCleanup();

      // Initialize dependency injection
      _log.debug('Initializing dependencies', tag: LogTags.app);
      await initializeDependencies();
      _log.info('Dependencies initialized', tag: LogTags.app);

      _log.info(
        '=== App initialization complete, starting UI ===',
        tag: LogTags.app,
      );

      // Run the app
      runApp(const WhatsMyShareApp());
    },
    (error, stackTrace) {
      // Handle uncaught errors
      _log.error(
        'Uncaught error in app',
        tag: LogTags.app,
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

/// Configure Firebase Auth settings for phone authentication
///
/// This sets up the appropriate app verification method based on the platform
/// and environment (simulator vs real device)
Future<void> _configureFirebaseAuth() async {
  try {
    final auth = FirebaseAuth.instance;

    if (Platform.isIOS) {
      // On iOS, we need to configure the app verification settings
      // The APNs token will be set automatically by AppDelegate when available
      _log.info(
        'Configuring Firebase Auth for iOS phone authentication',
        tag: LogTags.auth,
      );

      // Set auth settings - this helps with phone verification
      // When APNs is not available (simulator), Firebase will use reCAPTCHA
      await auth.setSettings(
        // Allow app verification to happen
        appVerificationDisabledForTesting: false,
      );

      _log.debug(
        'Firebase Auth settings configured for iOS',
        tag: LogTags.auth,
      );
    } else if (Platform.isAndroid) {
      _log.info(
        'Configuring Firebase Auth for Android phone authentication',
        tag: LogTags.auth,
      );

      // Android uses SafetyNet/Play Integrity by default
      // No additional configuration needed
      _log.debug('Firebase Auth ready for Android', tag: LogTags.auth);
    }
  } catch (e, stackTrace) {
    _log.error(
      'Error configuring Firebase Auth',
      tag: LogTags.auth,
      error: e,
      stackTrace: stackTrace,
    );
    // Don't rethrow - the app can still try to use phone auth
  }
}

/// Handles first launch auth cleanup to clear stale Firebase Auth state
///
/// On iOS, Firebase Auth stores credentials in the Keychain, which persists
/// across app uninstalls. This function detects if this is a fresh install
/// and signs out any stale user session.
Future<void> _handleFirstLaunchAuthCleanup() async {
  const String hasLaunchedKey = 'has_launched_before';

  try {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunchedBefore = prefs.getBool(hasLaunchedKey) ?? false;

    if (!hasLaunchedBefore) {
      _log.info(
        'First launch detected - clearing stale auth state',
        tag: LogTags.auth,
      );

      // Check if there's a stale user session
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _log.warning(
          'Found stale auth session on first launch, signing out',
          tag: LogTags.auth,
          data: {'uid': currentUser.uid},
        );
        await FirebaseAuth.instance.signOut();
        _log.info('Stale auth session cleared', tag: LogTags.auth);
      }

      // Mark that the app has been launched
      await prefs.setBool(hasLaunchedKey, true);
      _log.debug('First launch flag set', tag: LogTags.app);
    } else {
      _log.debug('Not first launch, skipping auth cleanup', tag: LogTags.app);
    }
  } catch (e, stackTrace) {
    _log.error(
      'Error during first launch auth cleanup',
      tag: LogTags.auth,
      error: e,
      stackTrace: stackTrace,
    );
    // Don't rethrow - we don't want to crash the app if this fails
  }
}
