import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/sunan_mahjoura/data/sunan_data.dart';

class SunanListPage extends StatelessWidget {
  const SunanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'sunan_mahjoura'.tr(),
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: sunanMahjouraList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final sunnah = sunanMahjouraList[index];
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.brightness_3_rounded,
                          color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sunnah.textKey.tr(),
                          style: AppFonts.amiri(
                            fontSize: 20,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                isDark ? Colors.white10 : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'sunnah_source'.tr(args: [sunnah.sourceKey.tr()]),
                            style: AppFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (sunnah.explanationKey.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDark
                                    ? AppTheme.darkSurfaceColor
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  'sunnah_explanation_title'.tr(),
                                  style: AppFonts.cairo(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  sunnah.explanationKey.tr(),
                                  style: AppFonts.cairo(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'close_button'.tr(),
                                        style: AppFonts.cairo(
                                          color: AppTheme.accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ))
                                ],
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.info_outline,
                                size: 22, color: AppTheme.accentColor),
                          ),
                        )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
