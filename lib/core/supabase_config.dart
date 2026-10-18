import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized configuration and initialization helper for Supabase.
///
/// Expects backend credentials supplied via `--dart-define` parameters:
/// - `SUPABASE_URL`: The Supabase project URL (e.g. `https://xyzcompany.supabase.co`).
/// - `SUPABASE_PUBLISHABLE_KEY`: The Supabase anon / publishable key.
abstract final class SupabaseConfig {
  /// Supabase project URL provided via compile-time `--dart-define`.
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (anon) API key provided via compile-time `--dart-define`.
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Deep-link redirect URL scheme and host for OAuth callbacks.
  /// Matches the AndroidManifest intent-filter and Supabase Auth redirect URLs.
  static const String defaultRedirectUrl =
      'com.rootnbranch.root_n_branch://login-callback';

  /// OAuth redirect URL provided via compile-time `--dart-define` or default.
  static const String authCallbackUrl = String.fromEnvironment(
    'SUPABASE_AUTH_CALLBACK_URL',
    defaultValue: defaultRedirectUrl,
  );

  /// Safe OAuth redirect URL for the active platform.
  ///
  /// On Web:
  /// - Returns [authCallbackUrl] only if explicitly provided via `--dart-define`
  ///   and not using an Android deep-link scheme.
  /// - Otherwise returns `null`, allowing Supabase Auth to redirect back to the
  ///   Site URL configured in the Supabase Dashboard.
  ///
  /// On Native (Android, iOS, etc.):
  /// - Returns [authCallbackUrl] (defaulting to the Android package deep link).
  static String? get oauthRedirectUrl {
    if (kIsWeb) {
      const customUrl = String.fromEnvironment('SUPABASE_AUTH_CALLBACK_URL');
      if (customUrl.trim().isNotEmpty &&
          !customUrl.startsWith('com.rootnbranch.')) {
        return customUrl.trim();
      }
      return null;
    }
    return authCallbackUrl;
  }

  /// Whether both required Supabase configuration values are present and non-empty.
  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  /// Builds a formatted developer-facing error message explaining how to provide missing keys.
  static String formatErrorMessage(List<String> missingKeys) {
    return '''
[Supabase Configuration Error]
Missing required environment variable(s): ${missingKeys.join(', ')}

Please provide these values at run-time using `--dart-define`:
  flutter run \\
    --dart-define=SUPABASE_URL="https://<your-project>.supabase.co" \\
    --dart-define=SUPABASE_PUBLISHABLE_KEY="<your-publishable-key>"
''';
  }

  /// Human-readable explanation of missing environment variables and how to supply them.
  static String get configurationErrorMessage {
    final missing = <String>[];
    if (url.trim().isEmpty) missing.add('SUPABASE_URL');
    if (publishableKey.trim().isEmpty) missing.add('SUPABASE_PUBLISHABLE_KEY');

    return formatErrorMessage(missing);
  }

  /// Validates whether the given [url] and [publishableKey] strings are non-empty.
  ///
  /// Throws a [StateError] with clear developer guidance if either value is empty.
  static void validateCredentials({
    required String url,
    required String publishableKey,
  }) {
    final missing = <String>[];
    if (url.trim().isEmpty) missing.add('SUPABASE_URL');
    if (publishableKey.trim().isEmpty) missing.add('SUPABASE_PUBLISHABLE_KEY');

    if (missing.isNotEmpty) {
      throw StateError(formatErrorMessage(missing));
    }
  }

  /// Validates presence of compile-time environment configuration.
  ///
  /// Throws a [StateError] with detailed developer guidance if either
  /// [SUPABASE_URL] or [SUPABASE_PUBLISHABLE_KEY] is missing.
  static void validate() {
    validateCredentials(url: url, publishableKey: publishableKey);
  }

  /// Initializes Supabase using [url] and [publishableKey].
  ///
  /// Calls [validate] first to guarantee credentials exist before connecting.
  static Future<Supabase> initialize() async {
    validate();
    return await Supabase.initialize(
      url: url.trim(),
      publishableKey: publishableKey.trim(),
    );
  }

  /// Whether the global Supabase instance has been initialized and is ready for use.
  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Shortcut to access the initialized global [SupabaseClient].
  static SupabaseClient get client => Supabase.instance.client;
}

/// Developer-facing error screen rendered when required Supabase credentials
/// were not supplied via `--dart-define`.
class SupabaseConfigurationErrorApp extends StatelessWidget {
  final String errorMessage;

  const SupabaseConfigurationErrorApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Configuration Error',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B307C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF9F7FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFFE53935),
                    width: 1.5,
                  ),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE53935),
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Supabase Not Configured',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF231B2A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFB71C1C),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This screen is displayed in development because backend variables were omitted. Supply SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY via --dart-define to proceed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5A5260),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
