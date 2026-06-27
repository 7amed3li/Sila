import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sila_app/core/presentation/widgets/sila_app_bar.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/features/azkar/presentation/riverpod/azkar_controller.dart';
import 'package:sila_app/features/vefa/presentation/pages/vefa_page.dart';

class AzkarDetailPage extends ConsumerStatefulWidget {
  const AzkarDetailPage(
      {super.key, required this.categoryId, required this.title});
  final String categoryId;
  final String title;

  @override
  ConsumerState<AzkarDetailPage> createState() => _AzkarDetailPageState();
}

class _AzkarDetailPageState extends ConsumerState<AzkarDetailPage> {
  // Map to track progress of each item: index -> currentCount
  final Map<int, int> _counts = {};

  void _checkCompletion(List items) {
    if (items.isEmpty) return;

    // Check if all items are completed
    var allCompleted = true;
    for (var i = 0; i < items.length; i++) {
      final requiredCount = items[i].count;
      final currentCount = _counts[i] ?? 0;
      if (currentCount < requiredCount) {
        allCompleted = false;
        break;
      }
    }

    if (allCompleted) {
      ref.read(analyticsServiceProvider).logAzkarComplete(
            categoryName: widget.categoryId,
          );
      // Small delay to let the UI update last count
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showVefaDialog();
      });
    }
  }

  void _showVefaDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'vefa_reminder_title'.tr(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'vefa_reminder_body'.tr(),
          style: TextStyle(
            fontFamily: 'Cairo',
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(
                fontFamily: 'Cairo',
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.diversity_1, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showVefaSelectionSheet();
            },
            label: Text(
              'gift_thawab'.tr(),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVefaSelectionSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VefaPage(isSelectionMode: true),
        fullscreenDialog: true, // Make it look like a modal
      ),
    );
  }

  Widget _buildAzkarList(
    List<dynamic> items,
    Color textColor,
    Color primaryColor,
    Color accentColor,
    Color backgroundColor,
    Color surfaceColor,
    bool isDark,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final currentCount = _counts[index] ?? 0;
        final isCompleted = currentCount >= item.count;
        final progress = (item.count > 0) ? currentCount / item.count : 0.0;
        final subtitleColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isCompleted ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isCompleted
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _counts[index] = currentCount + 1;
                        });
                        if (_counts[index]! >= item.count) {
                          _checkCompletion(items);
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Top Row: Count Badge & Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.count}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (item.fadilah.isNotEmpty)
                            Icon(Icons.info_outline,
                                color: accentColor, size: 24),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Azkar Title (Optional)
                      if (item.title != null && item.title!.isNotEmpty) ...[
                        Text(
                          item.title!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Azkar Text
                      Text(
                        item.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri', // Use Arabic font for Zikr
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.8,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Fadilah
                      if (item.fadilah.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.fadilah,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: subtitleColor,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Divider(color: subtitleColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      // Progress Ring
                      CircularPercentIndicator(
                        radius: 36.0,
                        lineWidth: 6.0,
                        percent: progress > 1.0 ? 1.0 : progress,
                        center: Text(
                          '${item.count - currentCount}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: textColor,
                          ),
                        ),
                        progressColor: primaryColor,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animateFromLastPercent: true,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'tap_to_count'.tr(),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Load azkar data (now locale-aware globally)
    final azkarAsync = ref.watch(azkarDataProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: SilaAppBar(
        title: widget.title,
      ),
      body: azkarAsync.when(
        data: (data) {
          final items = data[widget.categoryId] ?? [];

          // Show message if category is empty (not yet translated to Turkish)
          if (items.isEmpty) {
            final isTurkish = context.locale.languageCode == 'tr';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 80,
                      color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isTurkish
                          ? 'turkish_translation_coming'.tr()
                          : 'Coming soon...',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: subtitleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTurkish
                          ? 'main_azkar_available'.tr()
                          : 'This content is coming soon',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: subtitleColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Check if Turkish user is viewing Arabic-only content
          final isTurkish = context.locale.languageCode.startsWith('tr');
          // Show info banner if Turkish content is only partially translated
          if (isTurkish && items.isNotEmpty) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Türkçe çevirisi, Arapça orijinal metni içermektedir. Faydaları Türkçedir.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildAzkarList(items, textColor, primaryColor,
                      accentColor, backgroundColor, surfaceColor, isDark),
                ),
              ],
            );
          }

          return _buildAzkarList(items, textColor, primaryColor, accentColor,
              backgroundColor, surfaceColor, isDark);
        },
        error: (e, st) => Center(
          child: Text(
            'Error: $e',
            style:
                const TextStyle(color: Colors.redAccent, fontFamily: 'Cairo'),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      ),
    );
  }
}

// No longer needed, using global azkarData which is locale-aware
