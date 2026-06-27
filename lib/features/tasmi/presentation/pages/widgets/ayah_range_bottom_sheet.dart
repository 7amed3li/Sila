import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/features/hifz/domain/hifz_selection.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_page.dart';

String _toArabicNumber(BuildContext context, String input) {
  if (context.locale.languageCode != 'ar') return input;
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class AyahRangeBottomSheet extends StatefulWidget {
  const AyahRangeBottomSheet({
    super.key,
    required this.surahNumber,
    this.returnSelectionOnly = false,
  });
  final int surahNumber;
  final bool returnSelectionOnly;

  @override
  State<AyahRangeBottomSheet> createState() => _AyahRangeBottomSheetState();
}

class _AyahRangeBottomSheetState extends State<AyahRangeBottomSheet> {
  bool _isCustomRangeExpanded = false;
  double _fromAyah = 1.0;
  late double _toAyah;
  late int _maxAyah;

  @override
  void initState() {
    super.initState();
    _maxAyah = quran.getVerseCount(widget.surahNumber);
    _toAyah = _maxAyah.toDouble();
  }

  void _navigateToTasmi(int from, int to) {
    if (widget.returnSelectionOnly) {
      Navigator.pop(
        context,
        HifzSelection(
          surahNumber: widget.surahNumber,
          fromVerse: from,
          toVerse: to,
          type: from == 1 && to == _maxAyah
              ? HifzSelectionType.fullSurah
              : HifzSelectionType.ayahRange,
        ),
      );
      return;
    }
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TasmiPage(
          surahNumber: widget.surahNumber,
          fromAya: from,
          toAya: to,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'surah_name_prefix'.tr(
                        args: [quran.getSurahNameArabic(widget.surahNumber)]),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'ayah_count_suffix'.tr(args: [
                      _toArabicNumber(context,
                          quran.getVerseCount(widget.surahNumber).toString())
                    ]),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 16),

          // Option 1: Full Surah
          _buildOptionCard(
            context: context,
            icon: Icons.done_all_rounded,
            title: 'full_surah_option'.tr(),
            subtitle: 'full_surah_desc'.tr(),
            isDark: isDark,
            primaryColor: primaryColor,
            onTap: () => _navigateToTasmi(1, _maxAyah),
          ),
          const SizedBox(height: 12),

          // Option 2: Custom Range
          _buildOptionCard(
            context: context,
            icon: Icons.tune_rounded,
            title: 'custom_range_option'.tr(),
            subtitle: 'custom_range_desc'.tr(),
            isDark: isDark,
            primaryColor: primaryColor,
            isSelected: _isCustomRangeExpanded,
            onTap: () {
              setState(() {
                _isCustomRangeExpanded = !_isCustomRangeExpanded;
              });
            },
          ),

          // Custom Range Sliders (Animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isCustomRangeExpanded ? 260 : 0,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('from_ayah_label'.tr(),
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color:
                                    isDark ? Colors.white70 : Colors.black54)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _toArabicNumber(
                                  context, _fromAyah.round().toString()),
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.2),
                        valueIndicatorColor: accentColor,
                      ),
                      child: Slider(
                        value: _fromAyah,
                        min: 1,
                        max: _maxAyah.toDouble(),
                        divisions: _maxAyah > 1 ? _maxAyah - 1 : 1,
                        label: _toArabicNumber(
                            context, _fromAyah.round().toString()),
                        onChanged: (value) {
                          setState(() {
                            _fromAyah = value;
                            if (_toAyah < _fromAyah) {
                              _toAyah = _fromAyah;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('to_ayah_label'.tr(),
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color:
                                    isDark ? Colors.white70 : Colors.black54)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _toArabicNumber(
                                  context, _toAyah.round().toString()),
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.2),
                        valueIndicatorColor: accentColor,
                      ),
                      child: Slider(
                        value: _toAyah,
                        min: 1,
                        max: _maxAyah.toDouble(),
                        divisions: _maxAyah > 1 ? _maxAyah - 1 : 1,
                        label: _toArabicNumber(
                            context, _toAyah.round().toString()),
                        onChanged: (value) {
                          setState(() {
                            if (value >= _fromAyah) {
                              _toAyah = value;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToTasmi(
                            _fromAyah.round(), _toAyah.round()),
                        icon: const Icon(Icons.mic_rounded),
                        label: Text(
                            widget.returnSelectionOnly
                                ? 'start_hifz_action'.tr()
                                : 'start_tasmi_action'.tr(),
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDark ? 0.2 : 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white10 : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : primaryColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_left_rounded,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
