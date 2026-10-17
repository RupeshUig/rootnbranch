import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Accessible pagination indicator for onboarding slides.
class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${activeIndex + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final bool isActive = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.lightLavender
                  : AppColors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
