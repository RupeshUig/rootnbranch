import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_n_branch/app/app.dart';
import 'package:root_n_branch/features/auth/models/otp_flow_type.dart';
import 'package:root_n_branch/features/auth/presentation/account_created_screen.dart';
import 'package:root_n_branch/features/auth/presentation/create_new_password_screen.dart';
import 'package:root_n_branch/features/auth/presentation/forgot_password_screen.dart';
import 'package:root_n_branch/features/auth/presentation/login_screen.dart';
import 'package:root_n_branch/features/auth/presentation/otp_verification_screen.dart';
import 'package:root_n_branch/features/auth/presentation/signup_screen.dart';
import 'package:root_n_branch/features/auth/presentation/widgets/auth_button.dart';
import 'package:root_n_branch/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:root_n_branch/features/home/presentation/home_placeholder_screen.dart';
import 'package:root_n_branch/features/onboarding/presentation/onboarding_screen.dart';
import 'package:root_n_branch/features/onboarding/presentation/splash_screen.dart';
import 'package:root_n_branch/features/onboarding/presentation/widgets/onboarding_indicator.dart';
import 'package:root_n_branch/features/onboarding/presentation/widgets/root_n_branch_logo.dart';

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 2.0;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('Splash Screen Tests', () {
    testWidgets('renders Root N Branch branding and RB monogram', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(splashDuration: Duration(seconds: 10)),
        ),
      );

      expect(find.byType(RootNBranchLogo), findsOneWidget);
      expect(find.text('RB'), findsOneWidget);
      expect(find.text('ROOT N BRANCH'), findsOneWidget);
      expect(find.text("MEN'S SALON"), findsOneWidget);
    });

    testWidgets('transitions to OnboardingScreen after splash duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(splashDuration: Duration(milliseconds: 500)),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Stylist Profile'), findsOneWidget);
    });
  });

  group('Onboarding Screen Tests', () {
    testWidgets('has 3 pages, correct titles, subtitles, and initial state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      expect(find.text('Stylist Profile'), findsOneWidget);
      expect(
        find.text('Find the perfect match for your look.'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      expect(find.byType(OnboardingIndicator), findsOneWidget);
      final indicator = tester.widget<OnboardingIndicator>(
        find.byType(OnboardingIndicator),
      );
      expect(indicator.count, equals(3));
      expect(indicator.activeIndex, equals(0));
    });

    testWidgets('Continue button advances through all 3 pages to Get Started', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      expect(find.text('Stylist Profile'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('One Tap Booking'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Explore salon'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('tapping Get Started on page 3 completes onboarding', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('tapping Skip from Page 1 immediately completes onboarding', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      expect(find.text('Stylist Profile'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Skip navigates to LoginScreen in default customer flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login to your Account'), findsOneWidget);
    });

    testWidgets('rapid taps on Continue do not crash or cause index errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Authentication Flow Tests', () {
    testWidgets('Login screen renders and validates required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Login to your Account'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.byType(AuthButton), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);

      // Attempt submit without filling fields
      await tester.tap(find.widgetWithText(AuthButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Enter invalid short mobile number
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Enter 10-digit mobile number'),
        '98765',
      );
      await tester.tap(find.widgetWithText(AuthButton, 'Login'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid 10-digit mobile number'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Initial Login screen has no success message or prefilled demo message',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        expect(
          find.text('Backend authentication is not connected yet.'),
          findsNothing,
        );
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'Valid login shows single clear backend not connected message without duplicate SnackBar',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await tester.enterText(
          find.widgetWithText(AuthTextField, 'Enter 10-digit mobile number'),
          '9876543210',
        );
        await tester.enterText(
          find.widgetWithText(AuthTextField, 'Enter your password'),
          'password123',
        );

        await tester.tap(find.widgetWithText(AuthButton, 'Login'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Exactly one message banner exists
        expect(
          find.text('Backend authentication is not connected yet.'),
          findsOneWidget,
        );
        // No duplicate SnackBar was shown for login
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets('Social login buttons show unavailable notice', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(
        find.bySemanticsLabel('Google login (currently unavailable)'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Google login is currently unavailable. Backend authentication is not connected.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Login and signup links navigate correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Tap Sign up link
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Create your Account'), findsOneWidget);

      // Tap Login footer link on Signup screen
      await tester.ensureVisible(find.text('Login'));
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Signup screen renders all four fields and validates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Submit empty form
      await tester.ensureVisible(find.widgetWithText(AuthButton, 'Sign up'));
      await tester.tap(find.widgetWithText(AuthButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Confirm password is required'), findsOneWidget);
    });

    testWidgets('Signup rejects mismatched passwords', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Enter your full name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Enter 10-digit mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Create a strong password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Re-enter your password'),
        'differentpassword',
      );

      await tester.ensureVisible(find.widgetWithText(AuthButton, 'Sign up'));
      await tester.tap(find.widgetWithText(AuthButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Forgot Password opens phone-entry flow and validates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Get OTP'), findsOneWidget);

      // Submit empty mobile
      await tester.tap(find.widgetWithText(AuthButton, 'Get OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile number is required'), findsOneWidget);

      // Enter valid mobile and advance
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Enter 10-digit mobile number'),
        '9876543210',
      );
      await tester.tap(find.widgetWithText(AuthButton, 'Get OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('Verify Account'), findsOneWidget);
    });

    testWidgets('OTP rejects fewer than four digits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            flowType: OtpFlowType.signup,
            mobileNumber: '9876543210',
          ),
        ),
      );

      expect(find.text('Verify Account'), findsOneWidget);

      // Tap Continue without 4 digits
      await tester.tap(find.widgetWithText(AuthButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter the complete 4-digit verification code'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Signup OTP and password-recovery OTP navigate to different destinations',
      (WidgetTester tester) async {
        // 1. Signup Flow -> AccountCreatedScreen
        await tester.pumpWidget(
          const MaterialApp(
            key: Key('otp_signup_app'),
            home: OtpVerificationScreen(
              flowType: OtpFlowType.signup,
              mobileNumber: '9876543210',
            ),
          ),
        );

        // Enter 4 digits
        final textFields = find.byType(TextFormField);
        for (int i = 0; i < 4; i++) {
          await tester.enterText(textFields.at(i), '${i + 1}');
        }
        await tester.tap(find.widgetWithText(AuthButton, 'Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.byType(AccountCreatedScreen), findsOneWidget);
        expect(find.text('Account Created!'), findsOneWidget);

        // 2. Password Recovery Flow -> CreateNewPasswordScreen
        await tester.pumpWidget(
          const MaterialApp(
            key: Key('otp_recovery_app'),
            home: OtpVerificationScreen(
              flowType: OtpFlowType.passwordRecovery,
              mobileNumber: '9876543210',
            ),
          ),
        );

        final recoveryFields = find.byType(TextFormField);
        for (int i = 0; i < 4; i++) {
          await tester.enterText(recoveryFields.at(i), '${i + 1}');
        }
        await tester.tap(find.widgetWithText(AuthButton, 'Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
        expect(find.text('Update Password'), findsOneWidget);
      },
    );

    testWidgets('Password reset rejects mismatched passwords', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: CreateNewPasswordScreen()),
      );

      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Enter new password'),
        'newsecret123',
      );
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Re-enter new password'),
        'wrongsecret',
      );

      await tester.tap(find.widgetWithText(AuthButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Correct matching password
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Re-enter new password'),
        'newsecret123',
      );
      await tester.tap(find.widgetWithText(AuthButton, 'Update Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Returns to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('AccountCreatedScreen continues to HomePlaceholderScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AccountCreatedScreen()));

      expect(find.text('Account Created!'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePlaceholderScreen), findsOneWidget);
      expect(find.text('Welcome to Root N Branch'), findsOneWidget);
    });

    testWidgets(
      'Android back navigation from Signup returns cleanly to Login',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await tester.ensureVisible(find.text('Sign up'));
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
        expect(find.byType(SignupScreen), findsOneWidget);

        // Back navigation
        await tester.tap(find.byTooltip('Back to Login'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });

  group('Full App Flow Smoke Test', () {
    testWidgets(
      'starts at splash, transitions to onboarding, and reaches login',
      (WidgetTester tester) async {
        await tester.pumpWidget(const RootNBranchApp());

        expect(find.byType(SplashScreen), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);

        // Skip onboarding to Login
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
