import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Reusable heading for authentication screens with purple highlight accent.
class AuthHeader extends StatelessWidget {
  final String highlightedWord;
  final String remainingTitle;
  final String? subtitle;
  final bool centered;

  const AuthHeader({
    super.key,
    required this.highlightedWord,
    required this.remainingTitle,
    this.subtitle,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 27,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: highlightedWord,
                style: const TextStyle(color: AppColors.primaryPurple),
              ),
              TextSpan(
                text: remainingTitle,
                style: const TextStyle(color: AppColors.primaryText),
              ),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryText,
              height: 1.35,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}
