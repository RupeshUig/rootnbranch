import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/presentation/widgets/root_n_branch_logo.dart';
import 'login_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';

/// Screen E — Create New Password.
class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Return to LoginScreen and show demo notification
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo Mode: Password reset completed locally. Supabase Auth will persist real updates.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.darkPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
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
              vertical: 12.0,
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
                    highlightedWord: 'Reset',
                    remainingTitle: ' Password',
                    subtitle: 'Create a strong new password for your account.',
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  AuthTextField(
                    controller: _newPasswordController,
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm New Password
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm New Password',
                    hintText: 'Re-enter new password',
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleUpdatePassword(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Update Password Button
                  AuthButton(
                    text: 'Update Password',
                    isLoading: _isLoading,
                    onPressed: _handleUpdatePassword,
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
