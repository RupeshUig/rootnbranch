import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_n_branch/features/auth/presentation/widgets/social_login_buttons.dart';

void main() {
  group('Google Sign-In UI & State Tests', () {
    testWidgets('renders both Google and Apple login buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(),
          ),
        ),
      );

      expect(find.text('Or continue with'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
      expect(find.byIcon(Icons.apple_rounded), findsOneWidget);
    });

    testWidgets('shows loading spinner and disables taps when isGoogleLoading is true', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(
              onGoogleTap: () => tapped = true,
              isGoogleLoading: true,
            ),
          ),
        ),
      );

      // Verify circular progress indicator is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Signing in with Google'), findsOneWidget);

      // Attempt tap while loading
      await tester.tap(find.bySemanticsLabel('Signing in with Google'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders Google icon and responds to semantics label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButtons(
              onGoogleTap: () {},
              isGoogleLoading: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
    });
  });
}
