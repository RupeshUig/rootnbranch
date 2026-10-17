import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Check compile-time environment configuration
  if (!SupabaseConfig.isConfigured) {
    debugPrint(SupabaseConfig.configurationErrorMessage);
    runApp(
      SupabaseConfigurationErrorApp(
        errorMessage: SupabaseConfig.configurationErrorMessage,
      ),
    );
    return;
  }

  // Initialize Supabase prior to running the application
  try {
    await SupabaseConfig.initialize();
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize Supabase: $error\n$stackTrace');
    runApp(
      SupabaseConfigurationErrorApp(
        errorMessage: 'Failed to initialize Supabase: $error',
      ),
    );
    return;
  }

  runApp(const RootNBranchApp());
}
