import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import 'onboarding_screen.dart';
import 'widgets/root_n_branch_logo.dart';

/// Temporary placeholder destination when onboarding is completed.
///
/// NOTE: This placeholder serves as the clear transition point for
/// Phase 1, Task 2 where Login, Signup, and OTP verification will be added.
class AuthPlaceholderScreen extends StatelessWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const RootNBranchLogo(monogramSize: 80),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.subtleBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPurple.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryPurple,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Onboarding Complete',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You have completed the onboarding experience.\n\n'
                      'The authentication flow (Login, Sign Up, and OTP verification) '
                      'will be integrated here in Phase 1, Task 2.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Convenient button for testing and replaying onboarding
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                icon: const Icon(Icons.replay_rounded),
                label: Text(
                  'Replay Onboarding',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
