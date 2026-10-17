import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/presentation/widgets/root_n_branch_logo.dart';
import '../models/otp_flow_type.dart';
import 'otp_verification_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';

/// Screen C — Forgot Password / Request OTP.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Advance to OTP Verification for password recovery flow
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          flowType: OtpFlowType.passwordRecovery,
          mobileNumber: _mobileController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          tooltip: 'Back to Login',
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
              vertical: 12.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const RootNBranchLogo(monogramSize: 52, showSubtitle: false),
                  const SizedBox(height: 20),

                  // Heading
                  const AuthHeader(
                    highlightedWord: 'Reset',
                    remainingTitle: ' Password',
                    subtitle: 'Enter your registered mobile number. We will verify your identity with a one-time code.',
                    centered: true,
                  ),
                  const SizedBox(height: 24),

                  // Mobile Number
                  AuthTextField(
                    controller: _mobileController,
                    labelText: 'Mobile Number',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: Icons.phone_android_rounded,
                    prefixText: '+91 ',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onFieldSubmitted: (_) => _handleGetOtp(),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (trimmed.length != 10) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Get OTP Button
                  AuthButton(
                    text: 'Get OTP',
                    isLoading: _isLoading,
                    onPressed: _handleGetOtp,
                  ),
                  const SizedBox(height: 18),

                  // Demo Note Box
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
                            'Demo mode: No actual SMS will be sent. Proceed to enter verification code.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.secondaryText.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Back to Login Link
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.primaryPurple,
                    ),
                    label: Text(
                      'Return to Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
