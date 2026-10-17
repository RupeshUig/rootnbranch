import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/presentation/home_placeholder_screen.dart';

/// Screen F — Account Created success celebration screen.
///
/// NOTE: Reachable exclusively through the signup OTP verification flow.
class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen salon visual
            Image.asset(
              'assets/images/explore_salon.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.darkPurple,
                  child: const Center(
                    child: Icon(
                      Icons.content_cut_rounded,
                      size: 80,
                      color: AppColors.lightLavender,
                    ),
                  ),
                );
              },
            ),

            // Dark gradient overlay for optimal text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Colors.transparent,
                    Color(0x4D000000),
                    Color(0xD90D0814),
                    Color(0xF20D0814),
                  ],
                  stops: [0.0, 0.25, 0.50, 0.75, 1.0],
                ),
              ),
            ),

            // Content positioned near the bottom
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glowing success badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryPurple,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 36,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Account Created!',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle / message
                    Text(
                      'Welcome to Root N Branch Men\'s Salon. Your styling journey starts here.\n\n'
                      '(Demo UI: Real customer accounts will be activated during Supabase integration.)',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.lightLavender,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Continue Button leading to HomePlaceholderScreen
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const HomePlaceholderScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: AppColors.white,
                          elevation: 4,
                          shadowColor: AppColors.primaryPurple.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
