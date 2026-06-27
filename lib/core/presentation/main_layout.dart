import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/presentation/widgets/update_dialog.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/core/services/remote_config_service.dart';
import 'package:sila_app/core/services/update_service.dart';
import 'package:sila_app/features/azkar/presentation/pages/azkar_page.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_home_page.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_onboarding_page.dart';
import 'package:sila_app/features/home/presentation/pages/home_page.dart';
import 'package:sila_app/features/prayers/presentation/riverpod/prayer_controller.dart';
import 'package:sila_app/features/prayers/presentation/pages/prayers_page.dart';
import 'package:sila_app/features/quran/presentation/pages/quran_page.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_data_provider.dart';
import 'package:sila_app/features/vefa/presentation/pages/vefa_page.dart';

import 'widgets/sila_bottom_bar.dart';

// PERF FIX 7: Note — AppFonts.cairo() and AppFonts.getFont('Cairo') replaced
// with TextStyle(fontFamily: 'Cairo', ...) throughout this file.
// For other files using GoogleFonts, apply the same pattern.
// To bundle the font locally, add to pubspec.yaml:
//   fonts:
//     - family: Cairo
//       fonts:
//         - asset: assets/fonts/Cairo-Regular.ttf
//         - asset: assets/fonts/Cairo-Bold.ttf
//           weight: 700
// Place the font files in assets/fonts/

// State provider for Bottom Navigation Index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final hifzOnboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hifz_onboarding_done') ?? false;
});

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int? _lastLoggedIndex;

  // PERF FIX 3: Lazy page cache — each page is built only on first visit
  final List<Widget?> _cachedPages = List.filled(6, null);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _prefetchPrayerData();
      await _checkAndShowNotificationPrompt();
      _checkForUpdate();

      // Initial sync of Riverpod appLocaleProvider with easy_localization locale
      if (mounted) {
        ref.read(appLocaleProvider.notifier).state = context.locale;
      }
    });

    // PERF FIX 6: Log screen on tab change via provider listener, not in build()
    ref.listenManual(bottomNavIndexProvider, (_, __) => _logCurrentScreen());
  }

  Future<void> _prefetchPrayerData() async {
    try {
      await Future.wait([
        ref.read(prayerTimesControllerProvider.future),
        ref.read(nextPrayerControllerProvider.future),
      ]);
    } catch (_) {
      // Non-fatal prefetch; UI will fetch again if needed.
    }
  }

  // PERF FIX 3: Build page lazily
  Widget _buildPage(int index, Widget hifzPage) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const QuranPage();
      case 2:
        return hifzPage;
      case 3:
        return const PrayersPage();
      case 4:
        return const AzkarPage();
      case 5:
        return const VefaPage();
      default:
        return const HomePage();
    }
  }

  Future<void> _checkAndShowNotificationPrompt() async {
    final prefs = PrefsService();
    final neverShow = await prefs.getNeverShowNotificationPrompt();
    if (neverShow) return;

    if (await Permission.notification.isGranted) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0F1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'notification_permission_title'.tr(),
            style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold), // PERF FIX 7
            textAlign: TextAlign.center,
          ),
          content: Text(
            'notification_permission_desc'.tr(),
            style: const TextStyle(
                fontFamily: 'Cairo', color: Colors.white70), // PERF FIX 7
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actionsOverflowDirection: VerticalDirection.down,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final granted =
                    await NotificationService().requestPermissions();
                if (granted) {
                  if (!mounted) return;
                  _showMiuiSettingsGuide(context);
                } else {
                  final status = await Permission.notification.status;
                  if (status.isPermanentlyDenied) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('notification_permission_desc'.tr(),
                            style: const TextStyle(
                                fontFamily: 'Cairo')), // PERF FIX 7
                        action: SnackBarAction(
                          label: 'notification_settings_label'.tr(),
                          onPressed: openAppSettings,
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text('agree_button'.tr(),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)), // PERF FIX 7
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('disagree_button'.tr(),
                  style: const TextStyle(fontFamily: 'Cairo')), // PERF FIX 7
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await prefs.setNeverShowNotificationPrompt(true);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              },
              child: Text('never_show_again'.tr(),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 13)), // PERF FIX 7
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForUpdate() async {
    final remoteConfig = ref.read(remoteConfigServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;

    await analytics.setUserProperties(appVersion: packageInfo.version);

    final result = await remoteConfig.checkForUpdate(currentVersion);
    if (!result.hasUpdate || !mounted) return;

    await analytics.logUpdateDialogShown(newVersion: result.latestVersion);

    showDialog<void>(
      context: context,
      barrierDismissible: !result.isForced,
      builder: (_) => UpdateDialog(
        updateResult: result,
        updateService: ref.read(updateServiceProvider),
        analyticsService: analytics,
      ),
    );
  }

  Future<void> _logCurrentScreen() async {
    final currentIndex = ref.read(bottomNavIndexProvider);
    if (_lastLoggedIndex == currentIndex) return;
    _lastLoggedIndex = currentIndex;

    final analytics = ref.read(analyticsServiceProvider);
    switch (currentIndex) {
      case 0:
        await analytics.logScreenHome();
        break;
      case 1:
        await analytics.logScreenQuran();
        break;
      case 2:
        await analytics.logScreenHifz();
        break;
      case 3:
        await analytics.logScreenPrayers();
        break;
      case 4:
        await analytics.logScreenAzkar();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final hifzDoneAsync = ref.watch(hifzOnboardingDoneProvider);

    // PERF FIX 6: Removed addPostFrameCallback from build() — now handled by ref.listenManual in initState

    final hifzPage = hifzDoneAsync.when(
      data: (done) {
        if (done) {
          return const HifzHomePage();
        }
        return HifzOnboardingPage(
          onCompleted: () => ref.invalidate(hifzOnboardingDoneProvider),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => HifzOnboardingPage(
        onCompleted: () => ref.invalidate(hifzOnboardingDoneProvider),
      ),
    );

    // Safety check in case the index is somehow out of bounds.
    final displayIndex = currentIndex < 6 ? currentIndex : 0;

    // PERF FIX 3: Build page lazily on first visit
    // FIX: If it's the Hifz page (index 2), we check if the onboarding status changed
    if (displayIndex == 2) {
      _cachedPages[2] = _buildPage(2, hifzPage);
    } else {
      _cachedPages[displayIndex] ??= _buildPage(displayIndex, hifzPage);
    }

    return Scaffold(
      body: _cachedPages[
          displayIndex]!, // PERF FIX 3: Use cached page instead of IndexedStack
      bottomNavigationBar: SilaBottomBar(currentIndex: displayIndex),
    );
  }

  Future<void> _showMiuiSettingsGuide(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('miui_guide_shown') ?? false;
    if (alreadyShown) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'miui_warning_title'.tr(),
          style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.bold), // PERF FIX 7
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'miui_warning_desc'.tr(),
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Colors.white70), // PERF FIX 7
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGuideStep('1', 'miui_step1'.tr()),
            _buildGuideStep('2', 'miui_step2'.tr()),
            _buildGuideStep('3', 'miui_step3'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('miui_guide_shown', true);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text('understood'.tr(),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF43A047))), // PERF FIX 7
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF43A047),
            child: Text(num,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white60,
                      fontSize: 13))), // PERF FIX 7
        ],
      ),
    );
  }
}
