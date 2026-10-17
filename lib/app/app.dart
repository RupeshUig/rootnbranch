import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/onboarding/presentation/splash_screen.dart';

/// Main application widget for Root N Branch Men's Salon.
class RootNBranchApp extends StatelessWidget {
  const RootNBranchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Root N Branch Men's Salon",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
