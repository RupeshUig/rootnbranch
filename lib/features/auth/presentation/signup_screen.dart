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

/// Screen B — Create your Account / Signup.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
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

    // Advance to OTP Verification for signup flow
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          flowType: OtpFlowType.signup,
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
              vertical: 8.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: RootNBranchLogo(
                      monogramSize: 52,
                      showSubtitle: false,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Heading
                  const AuthHeader(
                    highlightedWord: 'Create',
                    remainingTitle: ' your Account',
                    subtitle: 'Fill in your details to start booking your salon sessions.',
                  ),
                  const SizedBox(height: 20),

                  // Name
                  AuthTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Name is required';
                      }
                      if (trimmed.length < 2) {
                        return 'Please enter a valid full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  AuthTextField(
                    controller: _mobileController,
                    labelText: 'Mobile Number',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: Icons.phone_android_rounded,
                    prefixText: '+91 ',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
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
                  const SizedBox(height: 16),

                  // Create Password
                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'Create Password',
                    hintText: 'Create a strong password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSignup(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Signup Button
                  AuthButton(
                    text: 'Sign up',
                    isLoading: _isLoading,
                    onPressed: _handleSignup,
                  ),
                  const SizedBox(height: 20),

                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Having an account?',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(
                          'Login',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
