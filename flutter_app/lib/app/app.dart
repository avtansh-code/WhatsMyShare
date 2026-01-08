import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'routes.dart';
import '../core/config/theme_config.dart';

/// Main application widget
class WhatsMyShareApp extends StatelessWidget {
  const WhatsMyShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "What's My Share",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}