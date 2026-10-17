import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/supabase_config.dart';

/// Social authentication buttons styled to match the Root N Branch identity.
class SocialLoginButtons extends StatelessWidget {
  /// Callback when user taps Google Sign-In.
  final VoidCallback? onGoogleTap;

  /// Whether a Google OAuth sign-in request is actively in progress.
  final bool isGoogleLoading;

  const SocialLoginButtons({
    super.key,
    this.onGoogleTap,
    this.isGoogleLoading = false,
  });

  void _onSocialTap(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$provider login is currently unavailable. Backend authentication is not connected.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.darkPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleAvailable = SupabaseConfig.isInitialized;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppColors.subtleBorder, thickness: 1.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Or continue with',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.secondaryText.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: AppColors.subtleBorder, thickness: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Button
            _buildSocialTile(
              context: context,
              label: 'Google',
              icon: Icons.g_mobiledata_rounded,
              iconSize: 32,
              isLoading: isGoogleLoading,
              isAvailable: isGoogleAvailable,
              onTap: isGoogleLoading
                  ? () {}
                  : () {
                      if (!isGoogleAvailable || onGoogleTap == null) {
                        _onSocialTap(context, 'Google');
                      } else {
                        onGoogleTap!();
                      }
                    },
            ),
            const SizedBox(width: 16),
            // Apple Button
            _buildSocialTile(
              context: context,
              label: 'Apple',
              icon: Icons.apple_rounded,
              iconSize: 26,
              isLoading: false,
              isAvailable: false,
              onTap: () => _onSocialTap(context, 'Apple'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isAvailable = false,
  }) {
    final semanticLabel = isLoading
        ? 'Signing in with $label'
        : (isAvailable ? '$label login' : '$label login (currently unavailable)');

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 84,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.subtleBorder, width: 1.2),
          ),
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple,
                        ),
                      ),
                    )
                  : Icon(icon, size: iconSize, color: AppColors.primaryText),
            ),
          ),
        ),
      ),
    );
  }
}
