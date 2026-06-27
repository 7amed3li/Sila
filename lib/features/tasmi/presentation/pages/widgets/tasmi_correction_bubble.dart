import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TasmiCorrectionBubble extends StatelessWidget {
  const TasmiCorrectionBubble({super.key, this.word});
  final String? word;

  @override
  Widget build(BuildContext context) {
    if (word == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'tasmi_correct_word_label'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            word!,
            style: const TextStyle(
              fontSize: 36,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textDirection: ui.TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'tasmi_resuming_label'.tr(),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
