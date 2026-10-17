import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import 'onboarding_screen.dart';
import 'widgets/root_n_branch_logo.dart';

/// Clean, minimalist splash screen for Root N Branch Men's Salon.
///
/// Features:
/// - Pure white background.
/// - Centered Root N Branch branding with replaceable RB monogram.
/// - Generous whitespace without arbitrary decorations.
/// - Smooth transition to onboarding.
class SplashScreen extends StatefulWidget {
  final Duration splashDuration;

  const SplashScreen({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(widget.splashDuration, _navigateToOnboarding);
  }

  void _navigateToOnboarding() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: RootNBranchLogo(
              monogramSize: 96,
              textColor: AppColors.primaryText,
              showSubtitle: true,
            ),
          ),
        ),
      ),
    );
  }
}
