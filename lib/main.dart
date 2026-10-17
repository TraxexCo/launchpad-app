import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/legacy_storage_cleanup.dart';
import 'services/push_notification_service.dart';
import 'services/secure_storage_service.dart';
import 'widgets/network_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || publishableKey.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define.',
    );
  }
  await clearLegacyPlaintextStorage(url);
  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
    authOptions: kIsWeb
        ? const FlutterAuthClientOptions(persistSession: false)
        : const FlutterAuthClientOptions(
            localStorage: SecureSupabaseLocalStorage(),
            pkceAsyncStorage: SecurePkceStorage(),
          ),
  );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReportingService.record(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReportingService.record(error, stack);
    return false;
  };
  await AuthService().restoreInitialRecoveryState();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LaunchPadApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(PushNotificationService().initialize());
  });
}

class LaunchPadApp extends StatelessWidget {
  const LaunchPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kIsWeb ? 'LaunchPad Admin' : 'LaunchPad',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          NetworkBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
