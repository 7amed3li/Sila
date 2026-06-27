import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/wird_notification_settings.dart';
import 'package:sila_app/features/quran/domain/entities/quran_settings.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_settings_controller.dart';
import 'package:sila_app/features/quran/presentation/utils/quran_ui_utils.dart';
import 'package:sila_app/features/quran/presentation/widgets/quran_details_sheet.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WirdReaderPage extends ConsumerStatefulWidget {
  const WirdReaderPage({
    super.key,
    required this.startPage,
    required this.endPage,
  });
  final int startPage;
  final int endPage;

  @override
  ConsumerState<WirdReaderPage> createState() => _WirdReaderPageState();
}

class _WirdReaderPageState extends ConsumerState<WirdReaderPage> {
  late PageController _pageController;
  late int _currentPage;
  bool _isAudioBuffering = false;
  int? _selectedSurah;
  int? _selectedAyah;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _currentPage = widget.startPage;
    _pageController = PageController(initialPage: 0);
    Future<void>.microtask(() async {
      final tracker = await ref.read(streakTrackerProvider.future);
      await tracker.logActivity('wird');

      // Show hint SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('wird_hint_text'.tr(),
                    style: AppFonts.cairo(fontSize: 13)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.9),
            duration: const Duration(seconds: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final page = widget.startPage + index;
    setState(() {
      _currentPage = page;
    });
    ref.read(wirdControllerProvider.notifier).updateCurrentPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(quranSettingsControllerProvider);
    final isDone = _currentPage >= widget.endPage;

    return settingsState.when(
      data: (settings) {
        final surahData = quran.getPageData(_currentPage);
        final currentSurah =
            surahData.isNotEmpty ? surahData[0]['surah'] as int : 1;
        final firstAyah =
            surahData.isNotEmpty ? surahData[0]['start'] as int : 1;
        final currentJuz = quran.getJuzNumber(currentSurah, firstAyah);
        final surahName = quran.getSurahNameArabic(currentSurah);

        return Scaffold(
          backgroundColor: QuranUIUtils.getBackgroundColor(settings.themeMode),
          appBar: _buildCustomAppBar(settings, surahName, currentJuz, isDone),
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() {
                _selectedSurah = null;
                _selectedAyah = null;
              }),
              child: Column(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: context.locale.languageCode == 'ar'
                          ? ui.TextDirection.rtl
                          : ui.TextDirection.ltr, // Dynamic directionality
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: (widget.endPage - widget.startPage + 1)
                            .clamp(1, 604),
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final pageNum = widget.startPage + index;
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 0;
                              if (_pageController.position.haveDimensions) {
                                value = index.toDouble() -
                                    (_pageController.page ?? 0);
                              }

                              // Apply a 3D rotation effect
                              final rotation = value.clamp(-1, 1) *
                                  (3.1415926535 / 8); // ~22.5 degrees

                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // perspective
                                  ..rotateY(rotation),
                                alignment: context.locale.languageCode == 'ar'
                                    ? (value > 0
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft)
                                    : (value > 0
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight),
                                child: _buildQuranPage(pageNum, settings),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // Features Toolbar
                  _buildToolbar(context, ref, settings),
                  // Bottom Progress indicator instead of slider if it's a restricted view
                  _buildBottomProgress(settings),
                ],
              ),
            ),
          ),
        );
      },
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(
      QuranSettings settings, String surahName, int juz, bool isDone) {
    final isDarkSettings = settings.themeMode == QuranThemeMode.dark;
    final appBarBg = QuranUIUtils.getBackgroundColor(settings.themeMode);
    final iconColor = _getTextColor(settings.themeMode);

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'surah_label'.tr(args: [surahName]),
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          fontFamily: settings.fontFamily,
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final wirdState = ref.watch(wirdControllerProvider).valueOrNull;
            final isBookmarked = wirdState?.bookmarkPage == _currentPage;
            return IconButton(
              icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppTheme.accentColor : iconColor),
              onPressed: () {
                ref
                    .read(wirdControllerProvider.notifier)
                    .updateBookmark(_currentPage);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppTheme.surfaceColor,
                  content: Text(
                    isBookmarked
                        ? 'تم إزالة العلامة المرجعية'
                        : 'تم الحفظ في العلامات المرجعية',
                    style: AppFonts.cairo(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 1),
                ));
              },
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: iconColor),
          onPressed: () => _showSettingsDialog(context, ref, settings),
        ),
      ],
    );
  }

  Widget _buildBottomSlider(QuranSettings settings) {
    return Container(
      color: QuranUIUtils.getBackgroundColor(settings.themeMode),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '604',
            style: AppFonts.cairo(
                color: _getTextColor(settings.themeMode), fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                value: _currentPage.toDouble(),
                min: 1,
                max: 604,
                activeColor: _getAccentColor(settings.themeMode),
                inactiveColor:
                    _getTextColor(settings.themeMode).withValues(alpha: 0.2),
                onChanged: (val) {
                  final newPage = val.toInt();
                  if (newPage != _currentPage) {
                    _pageController.jumpToPage(newPage - 1);
                  }
                },
              ),
            ),
          ),
          Text(
            '1',
            style: AppFonts.cairo(
                color: _getTextColor(settings.themeMode), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranPage(int pageNumber, QuranSettings settings) {
    final pageData = quran.getPageData(pageNumber);
    final bgColor = QuranUIUtils.getBackgroundColor(settings.themeMode);
    final isDark = settings.themeMode == QuranThemeMode.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          // Outer ornate frame
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFF064E3B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : const Color(0xFFD97706).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Container(
            // Inner page
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              image: settings.themeMode == QuranThemeMode.sepia
                  ? const DecorationImage(
                      image: AssetImage('assets/images/paper_texture.png'),
                      fit: BoxFit.cover,
                      opacity: 0.4,
                    )
                  : null,
              gradient: isDark
                  ? null
                  : RadialGradient(
                      colors: [
                        bgColor,
                        const Color(
                            0xFFFBF4E9), // Slightly darker sepia at edges
                      ],
                      center: Alignment.center,
                      radius: 1.2,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : const Color(0xFFD97706).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var data in pageData) ...[
                  _buildSurahSegment(
                      data['surah'], data['start'], data['end'], settings),
                ],
                const SizedBox(height: 12),
                // Page number at bottom
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: _getAccentColor(settings.themeMode)
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      context.locale.languageCode == 'ar'
                          ? '— ${QuranUIUtils.toArabicNumber(pageNumber)} —'
                          : '— $pageNumber —',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 14,
                        color: _getTextColor(settings.themeMode)
                            .withValues(alpha: 0.7),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahSegment(
      int surahNum, int startAyah, int endAyah, QuranSettings settings) {
    final textColor = _getTextColor(settings.themeMode);
    final accentColor = _getAccentColor(settings.themeMode);

    // Build one continuous text block with tap per ayah
    final spans = <InlineSpan>[];
    for (var i = startAyah; i <= endAyah; i++) {
      final ayahIndex = i; // capture for closure
      final verse = quran.getVerse(surahNum, ayahIndex);
      final isArabic = context.locale.languageCode == 'ar';
      final isSelected =
          _selectedSurah == surahNum && _selectedAyah == ayahIndex;

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          setState(() {
            if (isSelected) {
              _selectedSurah = null;
              _selectedAyah = null;
            } else {
              _selectedSurah = surahNum;
              _selectedAyah = ayahIndex;
            }
          });
        };

      final baseStyle = _getQuranStyle(settings, isSelected: isSelected);
      final tajweedSpans = QuranUIUtils.buildTajweedSpans(
          '$verse ', settings.themeMode,
          baseStyle: baseStyle);

      spans.add(TextSpan(
        children: tajweedSpans.map((s) {
          return TextSpan(
            text: s.text,
            style: s.style?.copyWith(
                backgroundColor: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : s.style?.backgroundColor),
            recognizer: recognizer,
          );
          return s;
        }).toList(),
      ));

      if (isArabic) {
        final verseSymbol =
            quran.getVerseEndSymbol(ayahIndex, arabicNumeral: true);
        spans.add(TextSpan(
          text: ' $verseSymbol ',
          style: baseStyle,
        ));
      } else {
        spans.add(const TextSpan(text: ' '));
        spans.add(WidgetSpan(
          alignment: ui.PlaceholderAlignment.middle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('\u06DD',
                  style: baseStyle.copyWith(
                      fontSize: (baseStyle.fontSize ?? 26) * 1.4, height: 1)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  ayahIndex.toString(),
                  style: AppFonts.cairo(
                    fontSize: (baseStyle.fontSize ?? 26) * 0.4,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? accentColor : textColor,
                  ),
                ),
              ),
            ],
          ),
        ));
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (startAyah == 1) ...[
          _buildBismillahFrame(surahNum, settings),
          if (surahNum != 1 && surahNum != 9)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                  height: 1.8,
                  color: textColor,
                ),
              ),
            ),
        ],
        RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: ui.TextDirection.rtl,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showAyahSheet(
      BuildContext context, int surahNum, int ayahNum, QuranSettings settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranDetailsSheet(
        surahNumber: surahNum,
        ayahNumber: ayahNum,
        showTafsir: true,
        settings: settings,
      ),
    );
  }

  Map<String, dynamic> _buildTajweedSpans(String text, QuranSettings settings) {
    final spans = QuranUIUtils.buildTajweedSpans(text, settings.themeMode);
    return {
      'spans': spans,
      'length': text.length
    }; // Length not strictly used for UI
  }

  // --- RESTORED UI HELPERS ---

  TextStyle _getQuranStyle(QuranSettings settings,
      {Color? color, bool isSelected = false}) {
    final textColor = color ?? _getTextColor(settings.themeMode);
    final accentColor = _getAccentColor(settings.themeMode);
    final size = settings.fontSize;
    const height = 1.85;

    TextStyle baseStyle;
    switch (settings.fontFamily) {
      case 'KFGQPCUthmanicScript':
        baseStyle = TextStyle(
            fontFamily: 'KFGQPCUthmanicScript', fontSize: size, height: height);
        break;
      case 'Amiri':
        baseStyle = AppFonts.amiri(fontSize: size, height: height);
        break;
      case 'Scheherazade':
        baseStyle = AppFonts.scheherazadeNew(fontSize: size, height: height);
        break;
      case 'Noto Naskh':
        baseStyle = AppFonts.notoNaskhArabic(fontSize: size, height: height);
        break;
      default:
        baseStyle = TextStyle(
            fontFamily: settings.fontFamily, fontSize: size, height: height);
    }

    return baseStyle.copyWith(
      color: isSelected ? accentColor : textColor,
      backgroundColor: isSelected ? accentColor.withValues(alpha: 0.15) : null,
    );
  }

  Color _getTextColor(QuranThemeMode mode) => QuranUIUtils.getTextColor(mode);
  Color _getAccentColor(QuranThemeMode mode) =>
      QuranUIUtils.getAccentColor(mode);
  String _arabicNumber(int n) => QuranUIUtils.toArabicNumber(n);

  Widget _buildBismillahFrame(int surahNum, QuranSettings settings) {
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final accentColor = _getAccentColor(settings.themeMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF064E3B), const Color(0xFF047857)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'surah_label'.tr(args: [quran.getSurahNameArabic(surahNum)]),
            style: TextStyle(
              fontFamily: settings.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
      BuildContext context, WidgetRef ref, QuranSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: QuranUIUtils.getBackgroundColor(settings.themeMode),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('reading_settings_title'.tr(),
                textAlign: TextAlign.center,
                style: AppFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(settings.themeMode))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Consumer(builder: (context, ref, child) {
                    final reciterName = ref
                        .watch(reciterControllerProvider)
                        .when(
                            data: (r) => context.locale.languageCode == 'ar'
                                ? r.nameArabic
                                : r.nameEnglish,
                            loading: () => 'loading_label'.tr(),
                            error: (e, s) => 'reciter_label'.tr());
                    return _buildSettingTile(
                        icon: Icons.mic_rounded,
                        label: reciterName,
                        onTap: () => showReciterPickerSheet(context),
                        settings: settings);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildSettingTile(
                        icon: Icons.notifications_active_rounded,
                        label: 'notifications_label'.tr(),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const WirdNotificationSettings())),
                        settings: settings)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildThemeOption(
                    ref, QuranThemeMode.light, 'theme_light'.tr(), settings),
                _buildThemeOption(
                    ref, QuranThemeMode.sepia, 'theme_sepia'.tr(), settings),
                _buildThemeOption(
                    ref, QuranThemeMode.dark, 'theme_dark'.tr(), settings),
              ],
            ),
            const SizedBox(height: 24),
            Text('quran_font_label'.tr(),
                textAlign: TextAlign.center,
                style: AppFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(settings.themeMode))),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFontOption(ref, 'KFGQPCUthmanicScript',
                      'font_uthmanic'.tr(), settings),
                  const SizedBox(width: 8),
                  _buildFontOption(ref, 'Amiri', 'font_amiri'.tr(), settings),
                  const SizedBox(width: 8),
                  _buildFontOption(
                      ref, 'Scheherazade', 'font_scheherazade'.tr(), settings),
                  const SizedBox(width: 8),
                  _buildFontOption(
                      ref, 'Noto Naskh', 'font_noto_naskh'.tr(), settings),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer(builder: (context, ref, child) {
              final currentSettings =
                  ref.watch(quranSettingsControllerProvider).valueOrNull ??
                      settings;
              return Row(children: [
                Icon(Icons.format_size,
                    color: _getTextColor(currentSettings.themeMode)),
                Expanded(
                    child: Slider(
                  value: currentSettings.fontSize.clamp(16.0, 44.0),
                  min: 16,
                  max: 44,
                  activeColor: _getAccentColor(currentSettings.themeMode),
                  onChanged: (v) => ref
                      .read(quranSettingsControllerProvider.notifier)
                      .updateFontSize(v),
                )),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required QuranSettings settings}) {
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: settings.themeMode == QuranThemeMode.dark
                    ? Colors.white10
                    : Colors.black12,
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(icon, color: _getAccentColor(settings.themeMode)),
              Text(label,
                  style: AppFonts.cairo(
                      fontSize: 12, color: _getTextColor(settings.themeMode)))
            ])));
  }

  Widget _buildThemeOption(WidgetRef ref, QuranThemeMode mode, String label,
      QuranSettings settings) {
    final isSelected = settings.themeMode == mode;
    return GestureDetector(
        onTap: () => ref
            .read(quranSettingsControllerProvider.notifier)
            .updateThemeMode(mode),
        child: Column(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: QuranUIUtils.getBackgroundColor(mode),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected
                          ? _getAccentColor(settings.themeMode)
                          : Colors.grey))),
          Text(label,
              style: AppFonts.cairo(color: _getTextColor(settings.themeMode)))
        ]));
  }

  Widget _buildFontOption(
      WidgetRef ref, String fontFamily, String label, QuranSettings settings) {
    final isSelected = settings.fontFamily == fontFamily;
    return GestureDetector(
      onTap: () => ref
          .read(quranSettingsControllerProvider.notifier)
          .updateFontFamily(fontFamily),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _getAccentColor(settings.themeMode).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? _getAccentColor(settings.themeMode)
                  : Colors.grey),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                color: _getTextColor(settings.themeMode))),
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, WidgetRef ref, QuranSettings settings) {
    final isAnySelected = _selectedSurah != null && _selectedAyah != null;
    if (!isAnySelected) return const SizedBox.shrink();

    final isDark = settings.themeMode == QuranThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF064E3B);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolbarAction(Icons.volume_up_rounded, 'toolbar_listen'.tr(),
              () => _playAyahAudio(_selectedSurah!, _selectedAyah!)),
          _toolbarAction(
              Icons.menu_book_rounded,
              'toolbar_tafsir'.tr(),
              () => showQuranDetailsSheet(context,
                  surahNumber: _selectedSurah!,
                  ayahNumber: _selectedAyah!,
                  showTafsir: true,
                  settings: settings)),
          _toolbarAction(
              Icons.translate_rounded,
              'toolbar_translation'.tr(),
              () => showQuranDetailsSheet(context,
                  surahNumber: _selectedSurah!,
                  ayahNumber: _selectedAyah!,
                  showTafsir: false,
                  settings: settings)),
          _toolbarAction(Icons.share_rounded, 'toolbar_copy'.tr(), () {
            Clipboard.setData(ClipboardData(
                text: quran.getVerse(_selectedSurah!, _selectedAyah!,
                    verseEndSymbol: false)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('verse_copied_success'.tr(), style: AppFonts.cairo()),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _toolbarAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.cairo(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomProgress(QuranSettings settings) {
    final total = widget.endPage - widget.startPage + 1;
    final current = _currentPage - widget.startPage + 1;
    final progress = (current / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: QuranUIUtils.getBackgroundColor(settings.themeMode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  _getAccentColor(settings.themeMode).withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getAccentColor(settings.themeMode)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _playAyahAudio(int surahNum, int ayahNum) async {
    setState(() => _isAudioBuffering = true);
    try {
      final url = ref
          .read(reciterControllerProvider.notifier)
          .buildAyahUrl(surahNum, ayahNum);
      await ref.read(audioControllerProvider.notifier).playAudio(url,
          surahName: quran.getSurahNameArabic(surahNum),
          surahNumber: surahNum,
          ayahNumber: ayahNum);
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isAudioBuffering = false);
    }
  }
}
