import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/presentation/widgets/root_n_branch_logo.dart';
import '../models/otp_flow_type.dart';
import 'account_created_screen.dart';
import 'create_new_password_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/otp_input_field.dart';

/// Screen D — Verify Account / OTP entry.
class OtpVerificationScreen extends StatefulWidget {
  final OtpFlowType flowType;
  final String mobileNumber;

  const OtpVerificationScreen({
    super.key,
    required this.flowType,
    required this.mobileNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<OtpInputFieldState> _otpKey = GlobalKey<OtpInputFieldState>();
  String _otpCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Resend Countdown
  int _resendSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _resendSeconds = 30;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResend() {
    if (_resendSeconds > 0) return;

    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demo Mode: Simulated new OTP code sent to your phone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleVerify() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (_otpCode.length < 4) {
      setState(() {
        _errorMessage = 'Please enter the complete 4-digit verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Navigate based explicitly on flow type
    if (widget.flowType == OtpFlowType.signup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountCreatedScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CreateNewPasswordScreen()),
      );
    }
  }

  String _formatMaskedPhone(String phone) {
    if (phone.length == 10) {
      return '+91 ••••• •${phone.substring(6)}';
    }
    return phone.isNotEmpty ? '+91 $phone' : 'your mobile number';
  }

  @override
  Widget build(BuildContext context) {
    final isResendActive = _resendSeconds == 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryText,
            size: 20,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const RootNBranchLogo(monogramSize: 52, showSubtitle: false),
                const SizedBox(height: 20),

                // Heading
                const AuthHeader(
                  highlightedWord: 'Verify',
                  remainingTitle: ' Account',
                  centered: true,
                ),
                const SizedBox(height: 12),

                // Instructions with masked phone
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'We have sent a 4-digit verification code to\n${_formatMaskedPhone(widget.mobileNumber)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 4-Digit OTP Input
                OtpInputField(
                  key: _otpKey,
                  hasError: _errorMessage != null,
                  onChanged: (code) {
                    setState(() {
                      _otpCode = code;
                      if (_errorMessage != null) {
                        _errorMessage = null;
                      }
                    });
                  },
                  onCompleted: (code) {
                    _otpCode = code;
                  },
                ),

                // Inline Error message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Resend OTP Row
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: isResendActive ? _handleResend : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isResendActive
                            ? 'Resend OTP'
                            : 'Resend in ${_resendSeconds}s',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isResendActive
                              ? AppColors.primaryPurple
                              : AppColors.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Continue Button
                AuthButton(
                  text: 'Continue',
                  isLoading: _isLoading,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 18),

                // Demo Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.subtleBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo mode: Enter any 4-digit code (e.g., 1234) to proceed.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.secondaryText.withValues(
                              alpha: 0.9,
                            ),
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
