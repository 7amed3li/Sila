
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/services/reciter_service.dart';
import 'package:sila_app/core/presentation/widgets/dynamic_download_button.dart';

class TasmiSelectionHeader extends ConsumerWidget {
  const TasmiSelectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioState = ref.watch(audioControllerProvider);
    final isDownloadingAll = audioState.isDownloadingAll;

    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: isDark ? Colors.white : AppTheme.primaryColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: isDownloadingAll
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                          ),
                        )
                      : IconButton(
                          tooltip: 'download_all'.tr(),
                          icon: Icon(Icons.cloud_download_rounded,
                              color: isDark ? AppTheme.accentColor : AppTheme.primaryColor),
                          onPressed: () async {
                            debugPrint('TasmiSelectionHeader: Cloud icon pressed');
                            final reciter = await showReciterPickerSheet(context);
                            if (reciter == null) return;

                            if (context.mounted) {
                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                builder: (context) => AlertDialog(
                                  title: Text('download_all_confirm_title'.tr(),
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                  content: Text(
                                    'download_all_confirm_message'
                                        .tr(args: [reciter.nameArabic]),
                                    style: GoogleFonts.cairo(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('download_all_confirm_cancel'.tr(),
                                          style: GoogleFonts.cairo(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ref
                                            .read(audioControllerProvider.notifier)
                                            .downloadAllSurahs(reciter);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('download_all_started'.tr(),
                                                style: GoogleFonts.cairo()),
                                            backgroundColor: AppTheme.primaryColor,
                                          ),
                                        );
                                      },
                                      child: Text('download_all_confirm_confirm'.tr(),
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: DynamicDownloadButton(),
          ),
        ],
      ),
    );
  }
}
