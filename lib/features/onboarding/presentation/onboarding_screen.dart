import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/presentation/login_screen.dart';
import 'widgets/onboarding_indicator.dart';
import 'widgets/onboarding_page_content.dart';

/// Screen managing the 3-slide onboarding experience for Root N Branch Men's Salon.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentPage != index) {
      setState(() {
        _currentPage = index;
      });
    }
  }

  void _onContinuePressed() {
    if (_currentPage < OnboardingPageData.pages.length - 1) {
      final int targetPage = (_currentPage + 1).clamp(
        0,
        OnboardingPageData.pages.length - 1,
      );
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingPageData.pages;
    final bool isLastPage = _currentPage == pages.length - 1;

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
            // Swipeable PageView with 3 slides
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                return OnboardingPageContent(
                  pageData: pages[index],
                  bottomSpacing: 160.0,
                );
              },
            ),

            // Top bar with Skip button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 20.0),
                  child: Semantics(
                    button: true,
                    label: 'Skip onboarding',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _completeOnboarding,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Section: Indicators and Primary Action Button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pagination Indicators
                      OnboardingIndicator(
                        count: pages.length,
                        activeIndex: _currentPage,
                      ),
                      const SizedBox(height: 24),
                      // Primary Button ("Continue" or "Get Started")
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onContinuePressed,
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
                            isLastPage ? 'Get Started' : 'Continue',
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
            ),
          ],
        ),
      ),
    );
  }
}
