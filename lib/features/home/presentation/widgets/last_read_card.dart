import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran;

import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/wird/presentation/pages/wird_reader_page.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

class LastReadCard extends ConsumerWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final border =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    final txtP = isDark ? Colors.white : AppTheme.primaryColor;
    final txtS = isDark ? Colors.white60 : Colors.grey[600];

    final wirdStateAsync = ref.watch(wirdControllerProvider);

    return wirdStateAsync.when(
      data: (wirdState) {
        final currentPage = wirdState.currentPage;
        final pageData = quran.getPageData(currentPage);
        final surahNumber =
            (pageData.isNotEmpty && pageData[0] is Map<String, dynamic>)
                ? (pageData[0]['surah'] as int? ?? 1)
                : 1;
        final surahName =
            SurahUtils.getLocalizedSurahName(context, surahNumber);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WirdReaderPage(
                  startPage: currentPage,
                  endPage: 604,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'continue_reading'.tr(),
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: txtS,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'surah_label'.tr(args: [surahName]),
                        style: AppFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: txtP),
                      ),
                      Text(
                        'page_label'.tr(args: [currentPage.toString()]),
                        style: AppFonts.cairo(
                          fontSize: 12,
                          color: txtS,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: txtS, size: 14),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}
