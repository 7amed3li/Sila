import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/quran/domain/entities/quran_settings.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_data_provider.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_settings_controller.dart';
import 'package:sila_app/features/quran/presentation/utils/quran_ui_utils.dart';
import 'package:sila_app/features/quran/presentation/widgets/quran_details_sheet.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SurahDetailPage extends ConsumerStatefulWidget {
  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });
  final int surahNumber;
  final String surahName;

  @override
  ConsumerState<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends ConsumerState<SurahDetailPage> {
  late PageController _pageController;
  late int _currentPage;
  bool _isAudioBuffering = false;
  int? _selectedSurah;
  int? _selectedAyah;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _currentPage = quran.getPageNumber(widget.surahNumber, 1);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadBookmark();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBookmarked =
          prefs.getBool('bookmark_surah_${widget.surahNumber}') ?? false;
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isBookmarked = !_isBookmarked);
    await prefs.setBool('bookmark_surah_${widget.surahNumber}', _isBookmarked);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(quranSettingsControllerProvider);

    return settingsState.when(
      data: (settings) {
        final surahData = quran.getPageData(_currentPage);
        final firstSurahOnPage =
            surahData.isNotEmpty ? surahData[0]['surah'] as int : 1;
        final firstAyahOnPage =
            surahData.isNotEmpty ? surahData[0]['start'] as int : 1;
        final currentJuz =
            quran.getJuzNumber(firstSurahOnPage, firstAyahOnPage);
        final currentSurahName =
            SurahUtils.getLocalizedSurahName(context, firstSurahOnPage);

        return Scaffold(
          backgroundColor: QuranUIUtils.getBackgroundColor(settings.themeMode),
          appBar: _buildCustomAppBar(settings, currentSurahName, currentJuz),
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
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 604,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page + 1),
                      itemBuilder: (context, index) {
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
                              child: _buildQuranPage(index + 1, settings),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildToolbar(context, ref, settings),
                  _buildBottomSlider(settings),
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
      QuranSettings settings, String surahName, int juz) {
    final iconColor = QuranUIUtils.getTextColor(settings.themeMode);
    return AppBar(
      backgroundColor: QuranUIUtils.getBackgroundColor(settings.themeMode),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'surah_label'.tr(args: [surahName]),
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: settings.fontFamily,
            ),
          ),
          Text(
            'page_with_juz_label'.tr(args: [
              context.locale.languageCode == 'ar'
                  ? QuranUIUtils.toArabicNumber(_currentPage)
                  : _currentPage.toString(),
              context.locale.languageCode == 'ar'
                  ? QuranUIUtils.toArabicNumber(juz)
                  : juz.toString()
            ]),
            style: GoogleFonts.cairo(
              color: iconColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: iconColor),
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: Icon(Icons.settings, color: iconColor),
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
          Text('604',
              style: GoogleFonts.cairo(
                  color: QuranUIUtils.getTextColor(settings.themeMode),
                  fontSize: 12)),
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
                activeColor: QuranUIUtils.getAccentColor(settings.themeMode),
                inactiveColor: QuranUIUtils.getTextColor(settings.themeMode)
                    .withValues(alpha: 0.2),
                onChanged: (val) {
                  final newPage = val.toInt();
                  if (newPage != _currentPage) {
                    _pageController.jumpToPage(newPage - 1);
                  }
                },
              ),
            ),
          ),
          Text('1',
              style: GoogleFonts.cairo(
                  color: QuranUIUtils.getTextColor(settings.themeMode),
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuranPage(int pageNumber, QuranSettings settings) {
    final pageData = quran.getPageData(pageNumber);
    final quranDataAsync = ref.watch(quranDataProvider);

    return quranDataAsync.when(
      data: (quranData) {
        final tajweedData = quranData.tajweed;
        final bgColor = QuranUIUtils.getBackgroundColor(settings.themeMode);
        final isDark = settings.themeMode == QuranThemeMode.dark;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
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
                            const Color(0xFFFBF4E9),
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
                  children: [
                    for (var data in pageData) ...[
                      _buildSurahSegment(data['surah'], data['start'],
                          data['end'], settings, tajweedData),
                    ],
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: QuranUIUtils.getAccentColor(
                                      settings.themeMode)
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
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            color: QuranUIUtils.getTextColor(settings.themeMode)
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSurahSegment(int surahNum, int startAyah, int endAyah,
      QuranSettings settings, Map<String, String> tajweedData) {
    final spans = <InlineSpan>[];

    for (var i = startAyah; i <= endAyah; i++) {
      spans.addAll(_buildAyahSpans(surahNum, i, settings, tajweedData,
          context.locale.languageCode == 'ar'));
    }

    return Column(
      children: [
        if (startAyah == 1) ...[
          _buildBismillahFrame(surahNum, settings),
          if (surahNum != 1 && surahNum != 9)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 24,
                    color: QuranUIUtils.getTextColor(settings.themeMode)),
              ),
            ),
        ],
        Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: ui.TextDirection.rtl,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<InlineSpan> _buildAyahSpans(int surahNum, int ayahNum,
      QuranSettings settings, Map<String, String> tajweedData, bool isArabic) {
    final key = '${surahNum}_$ayahNum';
    final rawVerse = tajweedData.containsKey(key)
        ? tajweedData[key]!
        : quran.getVerse(surahNum, ayahNum);

    final isSelected = _selectedSurah == surahNum && _selectedAyah == ayahNum;

    // Style for the verse and symbol
    final baseStyle = _getQuranStyle(settings);
    final selectedStyle = isSelected
        ? baseStyle.copyWith(
            backgroundColor: QuranUIUtils.getAccentColor(settings.themeMode)
                .withValues(alpha: 0.15))
        : baseStyle;

    final tajweedSpans = QuranUIUtils.buildTajweedSpans(
        rawVerse, settings.themeMode,
        baseStyle: selectedStyle);

    final ayahSpans = <InlineSpan>[
      TextSpan(
        children: tajweedSpans.map((s) {
          return TextSpan(
            text: s.text,
            style: s.style?.copyWith(
                backgroundColor: isSelected
                    ? QuranUIUtils.getAccentColor(settings.themeMode)
                        .withValues(alpha: 0.15)
                    : s.style?.backgroundColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () => setState(() {
                    if (isSelected) {
                      _selectedSurah = null;
                      _selectedAyah = null;
                    } else {
                      _selectedSurah = surahNum;
                      _selectedAyah = ayahNum;
                    }
                  }),
          );
                  return s;
        }).toList(),
      ),
    ];

    // Add the verse end symbol
    if (isArabic) {
      final verseSymbol = quran.getVerseEndSymbol(ayahNum, arabicNumeral: true);
      ayahSpans.add(TextSpan(
        text: ' $verseSymbol ',
        style: selectedStyle,
      ));
    } else {
      ayahSpans.add(const TextSpan(text: ' '));
      ayahSpans.add(WidgetSpan(
        alignment: ui.PlaceholderAlignment.middle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('\u06DD',
                style: selectedStyle.copyWith(
                    fontSize: (selectedStyle.fontSize ?? 26) * 1.4, height: 1)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                ayahNum.toString(),
                style: GoogleFonts.cairo(
                  fontSize: (selectedStyle.fontSize ?? 26) * 0.4,
                  fontWeight: FontWeight.w800,
                  color: selectedStyle.color,
                ),
              ),
            ),
          ],
        ),
      ));
      ayahSpans.add(const TextSpan(text: ' '));
    }

    return ayahSpans;
  }

  Widget _buildBismillahFrame(int surahNum, QuranSettings settings) {
    final isDark = settings.themeMode == QuranThemeMode.dark;
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

  TextStyle _getQuranStyle(QuranSettings settings) {
    final color = QuranUIUtils.getTextColor(settings.themeMode);
    final size = settings.fontSize;
    const height = 2.2;

    switch (settings.fontFamily) {
      case 'KFGQPCUthmanicScript':
        return TextStyle(
            fontFamily: 'KFGQPCUthmanicScript',
            fontSize: size,
            height: height,
            color: color);
      case 'Amiri':
        return GoogleFonts.amiri(fontSize: size, height: height, color: color);
      case 'Scheherazade':
        return GoogleFonts.scheherazadeNew(
            fontSize: size, height: height, color: color);
      case 'Noto Naskh':
        return GoogleFonts.notoNaskhArabic(
            fontSize: size, height: height, color: color);
      default:
        return GoogleFonts.getFont(settings.fontFamily,
            fontSize: size, height: height, color: color);
    }
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
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: QuranUIUtils.getTextColor(settings.themeMode))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Consumer(builder: (context, ref, child) {
                final reciterName = ref.watch(reciterControllerProvider).when(
                    data: (r) => r.nameArabic,
                    loading: () => 'loading_label'.tr(),
                    error: (e, s) => 'reciter_label'.tr());
                return _buildSettingTile(
                    icon: Icons.mic_rounded,
                    label: reciterName,
                    onTap: () => showReciterPickerSheet(context),
                    settings: settings);
              })),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildSettingTile(
                      icon: Icons.info_outline,
                      label: 'about_surah_label'.tr(),
                      onTap: () {},
                      settings: settings)),
            ]),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildThemeOption(
                  ref, QuranThemeMode.light, 'theme_light'.tr(), settings),
              _buildThemeOption(
                  ref, QuranThemeMode.sepia, 'theme_sepia'.tr(), settings),
              _buildThemeOption(
                  ref, QuranThemeMode.dark, 'theme_dark'.tr(), settings),
            ]),
            const SizedBox(height: 24),
            Text('quran_font_label'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: QuranUIUtils.getTextColor(settings.themeMode))),
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
                    color:
                        QuranUIUtils.getTextColor(currentSettings.themeMode)),
                Expanded(
                    child: Slider(
                  value: currentSettings.fontSize.clamp(16.0, 44.0),
                  min: 16,
                  max: 44,
                  activeColor:
                      QuranUIUtils.getAccentColor(currentSettings.themeMode),
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
              Icon(icon,
                  color: QuranUIUtils.getAccentColor(settings.themeMode)),
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: QuranUIUtils.getTextColor(settings.themeMode)))
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
                          ? QuranUIUtils.getAccentColor(settings.themeMode)
                          : Colors.grey))),
          Text(label,
              style: GoogleFonts.cairo(
                  color: QuranUIUtils.getTextColor(settings.themeMode)))
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
              ? QuranUIUtils.getAccentColor(settings.themeMode).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? QuranUIUtils.getAccentColor(settings.themeMode)
                  : Colors.grey),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                color: QuranUIUtils.getTextColor(settings.themeMode))),
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, WidgetRef ref, QuranSettings settings) {
    final isAnySelected = _selectedSurah != null && _selectedAyah != null;
    if (!isAnySelected) return const SizedBox.shrink();
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ]),
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
                SnackBar(content: Text('verse_copied_success'.tr())));
          }),
        ],
      ),
    );
  }

  Widget _toolbarAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 20),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF1D9E75), fontSize: 10, fontFamily: 'Cairo'))
        ]));
  }

  Future<void> _playAyahAudio(int surahNum, int ayahNum) async {
    setState(() => _isAudioBuffering = true);
    try {
      final url = ref
          .read(reciterControllerProvider.notifier)
          .buildAyahUrl(surahNum, ayahNum);
      await ref.read(audioControllerProvider.notifier).playAudio(url,
          surahName: SurahUtils.getLocalizedSurahName(context, surahNum),
          surahNumber: surahNum,
          ayahNumber: ayahNum);
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isAudioBuffering = false);
    }
  }
}
