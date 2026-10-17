import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Data model representing an individual onboarding slide.
class OnboardingPageData {
  final String title;
  final String subtitle;
  final String imageAsset;
  final String buttonText;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.buttonText,
  });

  /// The 3 official onboarding pages as specified.
  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Stylist Profile',
      subtitle: 'Find the perfect match for your look.',
      imageAsset: 'assets/images/stylist_profile.jpg',
      buttonText: 'Continue',
    ),
    OnboardingPageData(
      title: 'One Tap Booking',
      subtitle: 'Find the perfect match for your look.',
      imageAsset: 'assets/images/one_tap_booking.jpg',
      buttonText: 'Continue',
    ),
    OnboardingPageData(
      title: 'Explore salon',
      subtitle: 'Find the perfect match for your look.',
      imageAsset: 'assets/images/explore_salon.jpg',
      buttonText: 'Get Started',
    ),
  ];
}

/// Content view for an onboarding page, rendering edge-to-edge photography,
/// dark gradient overlay, and readable typography.
class OnboardingPageContent extends StatelessWidget {
  final OnboardingPageData pageData;
  final double bottomSpacing;

  const OnboardingPageContent({
    super.key,
    required this.pageData,
    this.bottomSpacing = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen edge-to-edge visual
        Image.asset(
          pageData.imageAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Elegant fallback if asset is missing or during tests
            return Container(
              color: AppColors.darkPurple,
              child: Center(
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 72,
                  color: AppColors.lightLavender.withValues(alpha: 0.4),
                ),
              ),
            );
          },
        ),

        // Dark gradient overlay for optimal text contrast and readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(
                  0x66000000,
                ), // Subtle top shading for status bar / skip button
                Colors.transparent,
                Color(0x33000000),
                Color(
                  0xCC0D0814,
                ), // Rich dark purple/black shading over text area
                Color(0xF20D0814),
              ],
              stops: [0.0, 0.25, 0.55, 0.80, 1.0],
            ),
          ),
        ),

        // Text content positioned consistently in the lower screen portion
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomSpacing,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pageData.title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pageData.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.lightLavender,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
