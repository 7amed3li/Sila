import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/presentation/main_layout.dart';
import 'package:sila_app/core/presentation/splash_page.dart';
import 'package:sila_app/core/services/adhan_scheduler_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/timezone_service.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/onboarding/presentation/pages/language_selection_page.dart';
import 'package:sila_app/features/prayers/data/repositories/prayer_repository_impl.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('MdbxError (11)')) {
      debugPrint('Ignored transient Isar lock: $text');
      return;
    }
    FlutterError.presentError(details);
  };

  // PERF: Allow runtime fetching for now since fonts aren't bundled yet
  GoogleFonts.config.allowRuntimeFetching = true;

  // PERF: Run all init operations in parallel instead of sequentially
  final results = await Future.wait([
    EasyLocalization.ensureInitialized(),
    TimezoneService().initialize(),
    Firebase.initializeApp(),
    SharedPreferences.getInstance(),
  ]);

  NotificationService().setNavigatorKey(appNavigatorKey);

  final prefs = results[3] as SharedPreferences;
  final isLanguageSelected = prefs.getBool('is_language_selected') ?? false;

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('tr', 'TR'),
          Locale('en', 'US'),
          Locale('fr', 'FR'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar', 'SA'),
        startLocale: const Locale('ar', 'SA'),
        child: SilaApp(isLanguageSelected: isLanguageSelected),
      ),
    ),
  );

  unawaited(_initBackgroundServices());
}

Future<void> _initBackgroundServices() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();

    final prayerRepo = PrayerRepositoryImpl();
    final prayerTimes = await prayerRepo.getPrayerTimes();
    final adhanScheduler = AdhanSchedulerService();
    await adhanScheduler.scheduleAllPrayers(prayerTimes);
    debugPrint('✅ Background services initialized');
  } catch (e) {
    debugPrint('❌ Background init failed: $e');
  }
}

class SilaApp extends StatefulWidget {
  const SilaApp({super.key, required this.isLanguageSelected});
  final bool isLanguageSelected;

  @override
  State<SilaApp> createState() => _SilaAppState();
}

class _SilaAppState extends State<SilaApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Sıla',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _showSplash
          ? SplashPage(
              onComplete: () => setState(() => _showSplash = false),
            )
          : widget.isLanguageSelected
              ? const MainLayout()
              : const LanguageSelectionPage(),
    );
  }
}
