import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';

String _toArabicNumber(BuildContext context, String input) {
  if (context.locale.languageCode != 'ar') return input;
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class TasmiPageHeader extends ConsumerWidget implements PreferredSizeWidget {
  const TasmiPageHeader({
    super.key,
    required this.surahName,
    required this.fromAya,
    required this.toAya,
    required this.isListening,
  });
  final String surahName;
  final int fromAya;
  final int toAya;
  final bool isListening;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 18,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: primaryColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'tasmi_ayah_range'.tr(args: [
                        _toArabicNumber(context, fromAya.toString()),
                        _toArabicNumber(context, toAya.toString())
                      ]),
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.red.withValues(alpha: 0.1)
                      : primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isListening
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isListening) ...[
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(
                        Icons.mic_none_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isListening
                          ? 'tasmi_status_listening'.tr()
                          : 'tasmi_status_ready'.tr(),
                      style: TextStyle(
                        color: isListening ? Colors.red : primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showReciterPickerSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic_rounded,
                          color: primaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ref
                                .watch(reciterControllerProvider)
                                .valueOrNull
                                ?.nameArabic
                                .split(' ')
                                .last ??
                            'tasmi_reciter_fallback'.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF064E3B),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: primaryColor, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(146);
}
