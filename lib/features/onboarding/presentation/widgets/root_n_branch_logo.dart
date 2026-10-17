import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Reusable Root N Branch branding widget.
///
/// NOTE: The official brand logo file was not supplied in the project assets.
/// As per specifications, this widget renders a temporary, clearly replaceable
/// 'RB' monogram and 'ROOT N BRANCH' text.
///
/// When the official vector or PNG logo is supplied, update [logoAssetPath]
/// or replace the monogram implementation here without affecting other screens.
class RootNBranchLogo extends StatelessWidget {
  /// Path reserved for the official logo asset when provided by the design team.
  static const String logoAssetPath = 'assets/logo/logo.png';

  final double monogramSize;
  final Color? textColor;
  final bool showSubtitle;

  const RootNBranchLogo({
    super.key,
    this.monogramSize = 88.0,
    this.textColor,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? AppColors.primaryText;

    return Semantics(
      label: "Root N Branch Men's Salon Logo",
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Replaceable Monogram Badge
          Container(
            width: monogramSize,
            height: monogramSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryPurple, AppColors.darkPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.25),
                  blurRadius: monogramSize > 64 ? 18 : 12,
                  offset: Offset(0, monogramSize > 64 ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: AppColors.lightLavender.withValues(alpha: 0.8),
                width: monogramSize > 64 ? 2.0 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'RB',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontSize: monogramSize * 0.42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: monogramSize > 64 ? 20 : 12),
          // Brand Name
          Text(
            'ROOT N BRANCH',
            style: GoogleFonts.plusJakartaSans(
              color: effectiveTextColor,
              fontSize: monogramSize > 64 ? 20 : 17,
              fontWeight: FontWeight.w700,
              letterSpacing: monogramSize > 64 ? 4.0 : 3.2,
            ),
            textAlign: TextAlign.center,
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 6),
            Text(
              "MEN'S SALON",
              style: GoogleFonts.plusJakartaSans(
                color: effectiveTextColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
