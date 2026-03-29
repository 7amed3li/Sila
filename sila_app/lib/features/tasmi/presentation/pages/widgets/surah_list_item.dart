import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';

String _toArabicNumber(BuildContext context, String input) {
  if (context.locale.languageCode != 'ar') return input;
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class SurahListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDownloaded =
        ref.watch(surahDownloadStatusProvider(surahNumber)).valueOrNull ??
            false;

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
                  style: GoogleFonts.cairo(
                    color:
                        isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'surah_name_prefix'.tr(args: [
                        SurahUtils.getLocalizedSurahName(context, surahNumber)
                      ]),
                      style: GoogleFonts.cairo(
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
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  style: GoogleFonts.cairo(
                    color: isDark
                        ? Colors.white70
                        : (isMakki ? Colors.amber[800] : Colors.blue[800]),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) {
                  final audioState = ref.watch(audioControllerProvider);
                  final isPlayingThis =
                      audioState.currentPlayingSurah == surahNumber;
                  final isAudioPlaying = audioState.playing;

                  return IconButton(
                    onPressed: () {
                      final notifier =
                          ref.read(audioControllerProvider.notifier);
                      if (isPlayingThis && isAudioPlaying) {
                        notifier.pauseAudio();
                      } else if (isPlayingThis && !isAudioPlaying) {
                        notifier.resumeAudio();
                      } else {
                        notifier.playAyah(surahNumber, 1);
                      }
                    },
                    icon: Icon(
                      (isPlayingThis && isAudioPlaying)
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: isPlayingThis
                          ? AppTheme.accentColor
                          : (isDark ? Colors.white30 : Colors.grey[400]),
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              if (!isDownloaded)
                IconButton(
                  onPressed: () async {
                    final reciter = await showReciterPickerSheet(context);
                    if (reciter == null) return;

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        useRootNavigator: true,
                        builder: (context) => AlertDialog(
                          title: Text('download_all_confirm_title'.tr(),
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold)),
                          content: Text(
                            'download_single_confirm_message'.tr(args: [
                              SurahUtils.getLocalizedSurahName(
                                  context, surahNumber),
                              reciter.nameArabic
                            ]),
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
                              onPressed: () async {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'download_all_started'.tr(),
                                            style: GoogleFonts.cairo())));
                                await ref
                                    .read(audioControllerProvider.notifier)
                                    .downloadSurah(surahNumber, reciter);
                                if (context.mounted) {
                                  ref.invalidate(
                                      surahDownloadStatusProvider(surahNumber));
                                }
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
                  icon: Icon(
                    Icons.download_for_offline_rounded,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                    size: 20,
                  ),
                )
              else
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.withValues(alpha: 0.6),
                  size: 18,
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left,
                  color: isDark ? Colors.white30 : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
