import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      _log.debug('Initializing Firebase', tag: LogTags.firebase);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log.info('Firebase initialized', tag: LogTags.firebase);

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
