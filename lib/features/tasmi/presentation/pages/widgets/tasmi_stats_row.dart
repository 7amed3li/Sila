import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_entry.dart';
import 'package:sila_app/features/tasmi/presentation/controllers/tasmi_controller.dart';

String _toArabicNumber(BuildContext context, String input) {
  if (context.locale.languageCode != 'ar') return input;
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class TasmiStatsRow extends StatelessWidget {
  const TasmiStatsRow({super.key, required this.state});
  final TasmiState state;

  @override
  Widget build(BuildContext context) {
    final correctCount =
        state.words.where((w) => w.status == WordEntryStatus.correct).length;
    final errorCount = state.words
        .where((w) =>
            w.status == WordEntryStatus.closeError ||
            w.status == WordEntryStatus.wrongWord)
        .length;
    final currentAyah =
        state.words.isEmpty || state.currentIndex >= state.words.length
            ? 0
            : state.words[state.currentIndex].verseNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
                  label: 'tasmi_stat_current_ayah'.tr(),
                  value: currentAyah > 0
                      ? _toArabicNumber(context, currentAyah.toString())
                      : '-',
                  icon: Icons.menu_book_rounded)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'tasmi_stat_errors'.tr(),
                  value: _toArabicNumber(context, errorCount.toString()),
                  color: Colors.red[400],
                  icon: Icons.error_outline_rounded)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'tasmi_stat_correct'.tr(),
                  value: _toArabicNumber(context, correctCount.toString()),
                  color: Colors.green[400],
                  icon: Icons.check_circle_outline_rounded)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      this.color,
      required this.icon});
  final String label;
  final String value;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    final displayColor = color ?? primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: displayColor.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: displayColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
