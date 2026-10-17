import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/presentation/login_screen.dart';
import '../../onboarding/presentation/widgets/root_n_branch_logo.dart';

/// Screen G — Temporary Home Screen Placeholder.
///
/// NOTE: Displayed after customer account creation demonstration.
/// In Phase 2, this will be replaced with the real customer dashboard,
/// service discovery, stylist booking, and appointment management.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AppBar(
        title: Text(
          "Root N Branch Men's Salon",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.softBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.primaryPurple,
            ),
            tooltip: 'Log Out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const RootNBranchLogo(monogramSize: 84, showSubtitle: true),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.subtleBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkPurple.withValues(alpha: 0.05),
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
                          Icons.content_cut_rounded,
                          color: AppColors.primaryPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to Root N Branch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Phase 1: Authentication UI & Navigation is complete.\n\n'
                        'In Phase 2, this screen will be replaced with the complete '
                        'customer experience: service selection, stylist scheduling, '
                        'Supabase real-time booking, and customer profile management.',
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primaryPurple,
                    ),
                    label: Text(
                      'Return to Login Screen',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
