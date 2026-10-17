import 'package:flutter/material.dart';

/// Centralized brand colors for Root N Branch Men's Salon.
///
/// Exact color specifications:
/// - Primary purple: #7046A6
/// - Light lavender: #D4C4EC
/// - Dark purple: #3F2468
/// - Light pink: #F8D8E8
/// - Dark pink: #A73F72
/// - Success: #22A06B
/// - Warning: #C88A14
/// - Error: #D14343
/// - White: #FFFFFF
/// - Soft background: #FAF8FC
/// - Primary text: #1B1724
/// - Secondary text: #625A70
class AppColors {
  AppColors._();

  // Primary brand palette
  static const Color primaryPurple = Color(0xFF7046A6);
  static const Color lightLavender = Color(0xFFD4C4EC);
  static const Color darkPurple = Color(0xFF3F2468);
  static const Color lightPink = Color(0xFFF8D8E8);
  static const Color darkPink = Color(0xFFA73F72);

  // Status & semantic colors
  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFC88A14);
  static const Color error = Color(0xFFD14343);

  // Neutral & background palette
  static const Color white = Color(0xFFFFFFFF);
  static const Color softBackground = Color(0xFFFAF8FC);
  static const Color primaryText = Color(0xFF1B1724);
  static const Color secondaryText = Color(0xFF625A70);

  // Borders & overlays
  static const Color subtleBorder = Color(0xFFE9E4F0);
  static const Color scrimDark = Color(0x99000000);
}
