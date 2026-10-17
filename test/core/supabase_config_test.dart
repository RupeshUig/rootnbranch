import 'package:flutter_test/flutter_test.dart';
import 'package:root_n_branch/core/supabase_config.dart';

void main() {
  group('SupabaseConfig Validation Tests', () {
    test('validateCredentials throws StateError when both keys are empty', () {
      expect(
        () => SupabaseConfig.validateCredentials(
          url: '',
          publishableKey: '',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('SUPABASE_URL'),
              contains('SUPABASE_PUBLISHABLE_KEY'),
              contains('--dart-define'),
            ),
          ),
        ),
      );
    });

    test('validateCredentials throws StateError when only url is missing', () {
      expect(
        () => SupabaseConfig.validateCredentials(
          url: '',
          publishableKey: 'valid_key',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('SUPABASE_URL'),
              contains('--dart-define'),
            ),
          ),
        ),
      );
    });

    test('validateCredentials throws StateError when only publishableKey is missing', () {
      expect(
        () => SupabaseConfig.validateCredentials(
          url: 'https://example.supabase.co',
          publishableKey: '',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('SUPABASE_PUBLISHABLE_KEY'),
              contains('--dart-define'),
            ),
          ),
        ),
      );
    });

    test('validateCredentials succeeds when both credentials are provided', () {
      expect(
        () => SupabaseConfig.validateCredentials(
          url: 'https://example.supabase.co',
          publishableKey: 'valid_key',
        ),
        returnsNormally,
      );
    });

    test('environment validate conforms to isConfigured state', () {
      if (SupabaseConfig.isConfigured) {
        expect(() => SupabaseConfig.validate(), returnsNormally);
      } else {
        expect(() => SupabaseConfig.validate(), throwsA(isA<StateError>()));
      }
    });

    testWidgets('SupabaseConfigurationErrorApp renders error UI properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const SupabaseConfigurationErrorApp(
          errorMessage: 'Missing SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY',
        ),
      );

      expect(find.text('Supabase Not Configured'), findsOneWidget);
      expect(
        find.text('Missing SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Supply SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY'),
        findsOneWidget,
      );
    });

    test('defaultRedirectUrl matches Android package scheme and login-callback host', () {
      expect(
        SupabaseConfig.defaultRedirectUrl,
        equals('com.rootnbranch.root_n_branch://login-callback'),
      );
      expect(SupabaseConfig.authCallbackUrl, isNotEmpty);
    });
  });
}
