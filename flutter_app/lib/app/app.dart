import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/theme_config.dart';
import '../core/di/injection_container.dart';
import '../core/services/logging_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'routes.dart';

/// Main application widget
class WhatsMyShareApp extends StatefulWidget {
  const WhatsMyShareApp({super.key});

  @override
  State<WhatsMyShareApp> createState() => _WhatsMyShareAppState();
}

class _WhatsMyShareAppState extends State<WhatsMyShareApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  late final AuthBloc _authBloc;
  final LoggingService _log = LoggingService();

  @override
  void initState() {
    super.initState();
    _log.info('WhatsMyShareApp initializing', tag: LogTags.ui);
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize AuthBloc and trigger auth check
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    
    _router = AppRouter.createRouter();
    _log.info('Router created successfully', tag: LogTags.ui);
  }

  @override
  void dispose() {
    _log.info('WhatsMyShareApp disposing', tag: LogTags.ui);
    _authBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info(
      'App lifecycle state changed',
      tag: LogTags.ui,
      data: {'state': state.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    _log.debug('Building WhatsMyShareApp', tag: LogTags.ui);
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: "What's My Share",
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // Router configuration
        routerConfig: _router,
      ),
    );
  }
}
