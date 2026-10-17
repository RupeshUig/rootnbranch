import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/presentation/widgets/root_n_branch_logo.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_login_buttons.dart';

/// Screen A — Login to your Account.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _demoStatusMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Unfocus any active keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _demoStatusMessage = null;
    });

    // Simulated local processing delay
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _demoStatusMessage = 'Backend authentication is not connected yet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryText,
                  size: 20,
                ),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimal brand mark with reduced spacing
                  const Center(
                    child: RootNBranchLogo(
                      monogramSize: 52,
                      showSubtitle: false,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heading
                  const AuthHeader(
                    highlightedWord: 'Login',
                    remainingTitle: ' to your Account',
                    subtitle: 'Welcome back! Please enter your details.',
                  ),
                  const SizedBox(height: 18),

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
                  const SizedBox(height: 14),

                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
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
                  const SizedBox(height: 6),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Login Button
                  AuthButton(
                    text: 'Login',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),

                  // Single clear demo message feedback banner
                  if (_demoStatusMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryPurple.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryPurple,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _demoStatusMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.darkPurple,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Social Login Section
                  const SocialLoginButtons(),
                  const SizedBox(height: 18),

                  // Signup Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign up',
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
