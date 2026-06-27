import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran_lib;
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/quran/domain/entities/quran_settings.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_data_provider.dart';

class QuranDetailsSheet extends ConsumerStatefulWidget {
  const QuranDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.showTafsir,
    required this.settings,
  });
  final int surahNumber;
  final int ayahNumber;
  final bool showTafsir;
  final QuranSettings settings;

  @override
  ConsumerState<QuranDetailsSheet> createState() => _QuranDetailsSheetState();
}

class _QuranDetailsSheetState extends ConsumerState<QuranDetailsSheet> {
  late int activeSurah;
  late int activeAyah;
  bool _isAudioBuffering = false;

  @override
  void initState() {
    super.initState();
    activeSurah = widget.surahNumber;
    activeAyah = widget.ayahNumber;
  }

  @override
  Widget build(BuildContext context) {
    final quranDataAsync = ref.watch(quranDataProvider);
    final settings = widget.settings;
    final isDark = settings.themeMode == QuranThemeMode.dark;

    // Determine title based on language
    final title =
        widget.showTafsir ? 'tafsir_label'.tr() : 'translation_label'.tr();

    return quranDataAsync.when(
      data: (quranData) {
        final isArabic = context.locale.languageCode == 'ar';
        final isTurkish = context.locale.languageCode == 'tr';

        final content = widget.showTafsir
            ? (quranData.tafsir['${activeSurah}_$activeAyah'] ??
                (isArabic ? 'لا يوجد تفسير متوفر حالياً' : 'Tefsir bulunamadı'))
            : (quranData.translation['${activeSurah}_$activeAyah'] ??
                (isArabic ? 'لا توجد ترجمة متوفرة' : 'Çeviri bulunamadı'));

        final surahName =
            SurahUtils.getLocalizedSurahName(context, activeSurah);
        final verseText = quran_lib.getVerse(activeSurah, activeAyah);

        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _getBackgroundColor(settings.themeMode)
                  .withOpacity(isDark ? 0.85 : 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: _getAccentColor(settings.themeMode).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
              border: Border.all(
                color: _getAccentColor(settings.themeMode)
                    .withOpacity(isDark ? 0.2 : 0.4),
                width: 1.0,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header with Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onPressed: (activeSurah == 1 && activeAyah == 1)
                            ? null
                            : () {
                                setState(() {
                                  if (activeAyah > 1) {
                                    activeAyah--;
                                  } else if (activeSurah > 1) {
                                    activeSurah--;
                                    activeAyah =
                                        quran_lib.getVerseCount(activeSurah);
                                  }
                                });
                              },
                        settings: settings,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              title,
                              style: AppFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _getTextColor(settings.themeMode),
                              ),
                            ),
                            Text(
                              'surah_ayah_label'
                                  .tr(args: [surahName, activeAyah.toString()]),
                              style: AppFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getAccentColor(settings.themeMode),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNavButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        onPressed: (activeSurah == 114 &&
                                activeAyah == quran_lib.getVerseCount(114))
                            ? null
                            : () {
                                setState(() {
                                  if (activeAyah <
                                      quran_lib.getVerseCount(activeSurah)) {
                                    activeAyah++;
                                  } else if (activeSurah < 114) {
                                    activeSurah++;
                                    activeAyah = 1;
                                  }
                                });
                              },
                        settings: settings,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Verse Text
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          _getAccentColor(settings.themeMode).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _getAccentColor(settings.themeMode)
                              .withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isAudioBuffering
                              ? null
                              : () => _playAyahAudio(activeSurah, activeAyah),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getAccentColor(settings.themeMode),
                                    _getAccentColor(settings.themeMode)
                                        .withValues(alpha: 0.7)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: _getAccentColor(settings.themeMode)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6))
                                ]),
                            child: _isAudioBuffering
                                ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2, color: Colors.white))
                                : const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '﴿ $verseText ﴾',
                          textAlign: TextAlign.center,
                          textDirection: ui.TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            height: 2.0,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(settings.themeMode),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Content
                  Text(
                    widget.showTafsir
                        ? 'tafsir_label'.tr()
                        : 'translation_label'.tr(),
                    style: AppFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getAccentColor(settings.themeMode),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    content.replaceAll('\n', '\n\n'),
                    textAlign:
                        widget.showTafsir ? TextAlign.justify : TextAlign.left,
                    textDirection: widget.showTafsir
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr,
                    style: TextStyle(
                      fontFamily:
                          widget.showTafsir ? settings.fontFamily : 'Roboto',
                      fontSize: settings.fontSize * 0.9,
                      height: widget.showTafsir ? 2.2 : 1.6,
                      color: _getTextColor(settings.themeMode).withValues(alpha: 0.9),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getAccentColor(settings.themeMode),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('close'.tr(),
                        style: AppFonts.cairo(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildNavButton(
      {required IconData icon,
      required VoidCallback? onPressed,
      required QuranSettings settings}) {
    return Container(
      decoration: BoxDecoration(
        color: _getAccentColor(settings.themeMode).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: _getAccentColor(settings.themeMode), size: 22),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Future<void> _playAyahAudio(int surahNum, int ayahNum) async {
    setState(() => _isAudioBuffering = true);
    final url = ref
        .read(reciterControllerProvider.notifier)
        .buildAyahUrl(surahNum, ayahNum);
    try {
      await ref.read(audioControllerProvider.notifier).playAudio(
            url,
            surahName: quran_lib.getSurahNameArabic(surahNum),
            surahNumber: surahNum,
            ayahNumber: ayahNum,
          );
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isAudioBuffering = false);
    }
  }

  Color _getBackgroundColor(QuranThemeMode mode) {
    if (mode == QuranThemeMode.dark) return AppTheme.darkBackgroundColor;
    if (mode == QuranThemeMode.sepia) return const Color(0xFFFBF4E4);
    return AppTheme.backgroundColor;
  }

  Color _getTextColor(QuranThemeMode mode) {
    if (mode == QuranThemeMode.dark) return const Color(0xFFF1F5F9);
    if (mode == QuranThemeMode.sepia) return const Color(0xFF4A3B32);
    return AppTheme.primaryColor;
  }

  Color _getAccentColor(QuranThemeMode mode) {
    if (mode == QuranThemeMode.dark) return AppTheme.accentColor;
    if (mode == QuranThemeMode.sepia) return const Color(0xFF795548);
    return AppTheme.primaryColor;
  }
}

void showQuranDetailsSheet(BuildContext context,
    {required int surahNumber,
    required int ayahNumber,
    required bool showTafsir,
    required QuranSettings settings}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => QuranDetailsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        showTafsir: showTafsir,
        settings: settings,
      ),
    ),
  );
}
