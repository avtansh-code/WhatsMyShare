import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/theme_config.dart';
import 'routes.dart';

/// Main application widget
class WhatsMyShareApp extends StatefulWidget {
  const WhatsMyShareApp({super.key});

  @override
  State<WhatsMyShareApp> createState() => _WhatsMyShareAppState();
}

class _WhatsMyShareAppState extends State<WhatsMyShareApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "What's My Share",
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: _router,
    );
  }
}
