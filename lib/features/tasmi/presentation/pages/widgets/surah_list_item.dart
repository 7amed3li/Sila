import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';

String _toArabicNumber(BuildContext context, String input) {
  if (context.locale.languageCode != 'ar') return input;
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class SurahListItem extends StatelessWidget {
  const SurahListItem({
    super.key,
    required this.surahNumber,
    required this.isMakki,
    required this.onTap,
  });
  final int surahNumber;
  final bool isMakki;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Number Badge
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.accentColor.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _toArabicNumber(context, surahNumber.toString()),
                  style: AppFonts.cairo(
                    color:
                        isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Surah Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'surah_name_prefix'.tr(args: [
                        SurahUtils.getLocalizedSurahName(context, surahNumber)
                      ]),
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'ayah_count_suffix'.tr(args: [
                        _toArabicNumber(context,
                            quran.getVerseCount(surahNumber).toString())
                      ]),
                      style: AppFonts.cairo(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Makki/Madani Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : (isMakki ? Colors.amber[50] : Colors.blue[50]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMakki ? 'makki'.tr() : 'madani'.tr(),
                  style: AppFonts.cairo(
                    color: isDark
                        ? Colors.white70
                        : (isMakki ? Colors.amber[800] : Colors.blue[800]),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_left,
                  color: isDark ? Colors.white30 : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
