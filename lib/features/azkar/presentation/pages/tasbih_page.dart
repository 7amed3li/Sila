import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sila_app/core/presentation/widgets/sila_app_bar.dart';
import 'package:sila_app/features/azkar/presentation/riverpod/tasbih_controller.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/tasbih_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/widgets/streak_badge.dart';

class TasbihPage extends ConsumerStatefulWidget {
  const TasbihPage({super.key});

  @override
  ConsumerState<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends ConsumerState<TasbihPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final tracker = await ref.read(streakTrackerProvider.future);
      await tracker.logActivity('tasbih');
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    ref.read(tasbihControllerProvider.notifier).increment();
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  String _formatNumber(number, BuildContext context) {
    final s = number.toString();
    if (context.locale.languageCode == 'ar') {
      const symbols = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return s.split('').map((d) {
        final idx = int.tryParse(d);
        return idx != null ? symbols[idx] : d;
      }).join('');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final tasbihState = ref.watch(tasbihControllerProvider);
    final controller = ref.read(tasbihControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFF10B981);
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    const target = 33;
    final count = tasbihState.activeCount;
    final progressCount = count % target;
    final progress = progressCount / target;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: SilaAppBar(
        title: 'azkar_tasbih'.tr(),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: StreakBadge(featureKey: 'tasbih'),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TasbihNotificationSettings()),
              );
            },
            icon: const Icon(Icons.notifications_active_rounded,
                color: Colors.white),
          ),
          IconButton(
            onPressed: controller.resetAll,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Zikr Selector (Horizontal Carousel) - Top
            Container(
              height: 100,
              margin: const EdgeInsets.only(top: 10),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: TasbihController.availableAzkar.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final key = TasbihController.availableAzkar[index];
                  final isSelected = tasbihState.activeZikrKey == key;

                  return GestureDetector(
                    onTap: () {
                      controller.setActiveZikr(key);
                      HapticFeedback.mediumImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 90,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected ? primaryColor : Colors.black)
                                .withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : primaryColor.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            child: Text(
                              key.tr().split(' ').take(2).join(' '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatNumber(
                                tasbihState.counts[key] ?? 0, context),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Active Zikr Name (Focus Area)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  tasbihState.activeZikrKey.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // 3. The Counter Area (Pearl)
            Expanded(
              child: GestureDetector(
                onTap: _incrementCounter,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: CircularPercentIndicator(
                      radius: 130.0,
                      lineWidth: 14.0,
                      percent: progress == 0 && count > 0 ? 1.0 : progress,
                      progressColor: accentColor,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: surfaceColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 35,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'total_count'.tr(),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: primaryColor.withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              _formatNumber(tasbihState.totalCount, context),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatNumber(count, context),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 90,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'tasbih_round'.tr(args: [
                                _formatNumber(count ~/ target + 1, context)
                              ]),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: accentColor,
                                fontWeight: FontWeight.bold,
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

            // 4. Instructions (Bottom)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    'tasbih_tap_instruction'.tr(),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tasbih_target'.tr(args: [_formatNumber(target, context)]),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
