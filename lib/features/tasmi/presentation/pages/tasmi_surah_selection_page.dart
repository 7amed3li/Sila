import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/features/hifz/domain/hifz_selection.dart';
import 'package:sila_app/features/tasmi/domain/tajweed_normalizer.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/ayah_range_bottom_sheet.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/search_and_filter_bar.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/surah_list_item.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/tasmi_selection_header.dart';

const List<bool> _isMakki = [
  true,
  false,
  false,
  false,
  false,
  true,
  true,
  false,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  true,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  true,
  true,
  true,
  true,
  true,
  false,
  false,
  true,
  true,
  true,
  true,
  true,
  false,
  false,
  false,
  false,
  false,
  false,
  true,
  false,
  false,
  false,
  false,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  false,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true,
  true
];

class TasmiSurahSelectionPage extends StatefulWidget {
  const TasmiSurahSelectionPage({
    super.key,
    this.forHifz = false,
    this.showAyahRange = true,
  });
  final bool forHifz;
  final bool showAyahRange;

  @override
  State<TasmiSurahSelectionPage> createState() =>
      _TasmiSurahSelectionPageState();
}

String _toArabicNumber(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class _TasmiSurahSelectionPageState extends State<TasmiSurahSelectionPage> {
  String _searchQuery = '';
  int _filterIndex = 0;
  List<int> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.generate(quran.totalSurahCount, (i) => i + 1);
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _updateFilter(int index) {
    setState(() {
      _filterIndex = index;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final results = <int>[];
    final normalizedQuery = TajweedNormalizer.normalize(_searchQuery);

    for (var i = 1; i <= quran.totalSurahCount; i++) {
      final bool matchesFilter;
      if (_filterIndex == 1) {
        matchesFilter = _isMakki[i - 1];
      } else if (_filterIndex == 2) {
        matchesFilter = !_isMakki[i - 1];
      } else {
        matchesFilter = true;
      }

      final bool matchesSearch;
      if (normalizedQuery.isEmpty) {
        matchesSearch = true;
      } else {
        matchesSearch = TajweedNormalizer.normalize(quran.getSurahNameArabic(i))
                .contains(normalizedQuery) ||
            i.toString().contains(normalizedQuery) ||
            _toArabicNumber(i.toString()).contains(normalizedQuery);
      }

      if (matchesFilter && matchesSearch) {
        results.add(i);
      }
    }
    _filteredSurahs = results;
  }

  void _onSurahTapped(int surahNumber) {
    if (widget.forHifz && !widget.showAyahRange) {
      final toVerse = quran.getVerseCount(surahNumber);
      debugPrint(
        'TasmiSurahSelection (hifz full) tapped surah=$surahNumber toVerse=$toVerse',
      );
      Navigator.pop(
        context,
        HifzSelection(
          surahNumber: surahNumber,
          fromVerse: 1,
          toVerse: toVerse,
          type: HifzSelectionType.fullSurah,
        ),
      );
      return;
    }

    if (widget.forHifz) {
      // FIX: await the bottom sheet so we capture the HifzSelection result
      showModalBottomSheet<HifzSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AyahRangeBottomSheet(
          surahNumber: surahNumber,
          returnSelectionOnly: true,
        ),
      ).then((result) {
        if (result != null && mounted) {
          debugPrint(
            'TasmiSurahSelection (hifz range) returning surah=${result.surahNumber}, from=${result.fromVerse}, to=${result.toVerse}',
          );
          Navigator.pop(context, result);
        }
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahRangeBottomSheet(
        surahNumber: surahNumber,
        returnSelectionOnly: widget.forHifz,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TasmiSelectionHeader(
            title:
                widget.forHifz ? 'hifz_label'.tr() : 'tasmi_header_title'.tr(),
            subtitle: widget.forHifz
                ? 'hifz_header_subtitle'.tr()
                : 'tasmi_header_subtitle'.tr(),
          ),
          SearchAndFilterBar(
            onSearchChanged: _updateSearchQuery,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip(0, 'all_surahs'.tr()),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'makki'.tr()),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'madani'.tr()),
              ],
            ),
          ),
          Expanded(
            child: _filteredSurahs.isEmpty
                ? Center(child: Text('no_results_found'.tr()))
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surahNumber = _filteredSurahs[index];
                      return SurahListItem(
                        surahNumber: surahNumber,
                        isMakki: _isMakki[surahNumber - 1],
                        onTap: () => _onSurahTapped(surahNumber),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isActive = _filterIndex == index;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      onSelected: (_) {
        _updateFilter(index);
      },
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : theme.textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isActive
              ? theme.primaryColor
              : theme.dividerColor.withOpacity(0.5),
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
