import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/crash_reporting_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || publishableKey.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define.',
    );
  }
  await Supabase.initialize(url: url, publishableKey: publishableKey);
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
}

class LaunchPadApp extends StatelessWidget {
  const LaunchPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LaunchPad',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
