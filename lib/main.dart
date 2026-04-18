import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/presentation/main_layout.dart';
import 'package:sila_app/core/presentation/splash_page.dart';
import 'package:sila_app/core/services/adhan_scheduler_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/onboarding/presentation/pages/language_selection_page.dart';
import 'package:sila_app/features/prayers/data/repositories/prayer_repository_impl.dart';
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final startupStart = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 1. Initializing Timezone...');
  tz.initializeTimeZones();
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 1. Timezone: Done');

  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 2. Initializing Firebase...');
  await Firebase.initializeApp();
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 2. Firebase: Done');

  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 3. Initializing NotificationService...');
  await NotificationService().initialize();
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 3. NotificationService: Done');

  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 4. Retrieving SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();
  final isLanguageSelected = prefs.getBool('is_language_selected') ?? false;
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] 4. SharedPreferences: Done');

  final startupEnd = DateTime.now();
  final duration = startupEnd.difference(startupStart);
  debugPrint('[${DateTime.now().toIso8601String()}][Startup] Total init duration: ${duration.inMilliseconds} ms');

  debugPrint('🚩 [main.dart] About to runApp...');

   try {
     debugPrint('🚩 [main.dart] Before PROVIDER RUN');
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
    debugPrint('🚩 [main.dart] runApp completed');
   } catch (e, s) {
    debugPrint('❌ [main.dart] runApp crashed: $e\nStack: $s');
   }

}

Future<void> _initBackgroundServices() async {
  final bgServicesStart = DateTime.now();
  try {
    debugPrint('[${DateTime.now().toIso8601String()}][BG] Fetching prayer times...');
    final prayerRepo = PrayerRepositoryImpl();
    final prayerTimes = await prayerRepo.getPrayerTimes();
    debugPrint('[${DateTime.now().toIso8601String()}][BG] Got prayerTimes. Scheduling...');
    final adhanScheduler = AdhanSchedulerService();
    await adhanScheduler.scheduleAllPrayers(prayerTimes);
    debugPrint('[${DateTime.now().toIso8601String()}][BG] ScheduleAllPrayers done');
    final done = DateTime.now();
    debugPrint('[${done.toIso8601String()}][BG] Background services TOTAL: ${done.difference(bgServicesStart).inMilliseconds} ms');
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

class _SilaAppState extends State<SilaApp> with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[${DateTime.now().toIso8601String()}][SilaApp] Setting Notification NavigatorKey...');
      try {
        await NotificationService().setNavigatorKey(appNavigatorKey);
        debugPrint('[${DateTime.now().toIso8601String()}][SilaApp] Notification NavigatorKey set');
      } catch (e) {
        debugPrint('Failed to set notification navigator key: $e');
      }

      debugPrint('[${DateTime.now().toIso8601String()}][SilaApp] Initializing Background Services...');
      try {
        await _initBackgroundServices();
        debugPrint('[${DateTime.now().toIso8601String()}][SilaApp] Background Services Initialized');
      } catch (e) {
        debugPrint('Background service bootstrap failed: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(NotificationService().dispose());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      builder: (context, child) {
        return Directionality(
          textDirection: context.locale.languageCode == 'ar'
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: child!,
        );
      },
      home: _showSplash
          ? SplashPage(
              onComplete: () {
                debugPrint('🚩 [main.dart] SplashPage onComplete CALLED');
                setState(() => _showSplash = false);
              },
            )
          : widget.isLanguageSelected
              ? const MainLayout()
              : const LanguageSelectionPage(),
    );
  }
}
