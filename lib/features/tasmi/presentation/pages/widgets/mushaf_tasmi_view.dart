import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_entry.dart';
import 'package:sila_app/features/tasmi/presentation/controllers/tasmi_controller.dart';

String _toArabicNumber(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (var i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }
  return input;
}

class MushafTasmiView extends ConsumerWidget {
  const MushafTasmiView({
    super.key,
    this.wordsOverride,
    this.currentIndexOverride,
    this.showAsBlank = false,
  });
  final List<TasmiWordEntry>? wordsOverride;
  final int? currentIndexOverride;
  final bool showAsBlank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimization: Select only words and currentIndex to prevent rebuilding on other state changes
    final wordsRaw = wordsOverride ??
        ref.watch(tasmiControllerProvider.select((state) => state.words));
    final currentIndexRaw = currentIndexOverride ??
        ref.watch(
            tasmiControllerProvider.select((state) => state.currentIndex));

    final words = wordsRaw ?? const <TasmiWordEntry>[];
    final currentIndex = currentIndexRaw ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mushaf specific typography
    const fontFamily = 'Amiri';
    const fontSize = 32.0;

    return SingleChildScrollView(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: GoogleFonts.getFont(
              fontFamily,
              fontSize: fontSize,
              height: 2.2, // Generous line height for Mushaf aesthetics
              color: isDark ? Colors.white : Colors.black87,
            ),
            children: _buildTextSpans(
                words, currentIndex, isDark, fontFamily, fontSize),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(
    List<TasmiWordEntry> words,
    int currentIndex,
    bool isDark,
    String fontFamily,
    double fontSize,
  ) {
    final spans = <InlineSpan>[];
    if (words.isEmpty) return spans;

    for (var i = 0; i < words.length; i++) {
      final entry = words[i];
      final isCurrent = i == currentIndex;

      final renderBlank = showAsBlank && entry.status == WordEntryStatus.hidden;
      final renderedText = renderBlank ? _blankFor(entry.word) : entry.word;

      spans.add(TextSpan(
          text: '$renderedText ',
          style: _getWordStyle(entry.status, isCurrent, isDark, renderBlank)));

      final isLastWordOfAyah = (i + 1 == words.length) ||
          (words[i + 1].verseNumber != entry.verseNumber);

      if (isLastWordOfAyah) {
        final ayahColor =
            isDark ? const Color(0xFFD97706) : const Color(0xFF064E3B);
        spans.add(
          TextSpan(
            text: ' ﴿${_toArabicNumber(entry.verseNumber.toString())}﴾ ',
            style: TextStyle(
              color: ayahColor,
              fontSize: fontSize * 0.65,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        );
      }
    }
    return spans;
  }

  TextStyle _getWordStyle(
      WordEntryStatus status, bool isCurrent, bool isDark, bool isBlank) {
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);

    // Current word being recited gets a distinct highlight
    if (isCurrent) {
      return TextStyle(
        color: isDark ? accentColor : primaryColor, // Highlight color
        backgroundColor: isDark
            ? accentColor.withValues(alpha: 0.2)
            : primaryColor.withValues(alpha: 0.15),
        fontWeight: FontWeight.bold,
      );
    }

    switch (status) {
      case WordEntryStatus.correct:
        // Proper green for Mushaf success
        return TextStyle(
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32));
      case WordEntryStatus.closeError:
        return TextStyle(color: isDark ? Colors.amber[300] : Colors.amber[800]);
      case WordEntryStatus.wrongWord:
        return TextStyle(
          color: isDark ? const Color(0xFFE57373) : const Color(0xFFA32D2D),
          backgroundColor: isDark
              ? const Color(0xFFE57373).withValues(alpha: 0.15)
              : const Color(0xFFA32D2D).withValues(alpha: 0.1),
        );
      case WordEntryStatus.skipped:
        return TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]);
      case WordEntryStatus.hidden:
        if (isBlank) {
          return TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontWeight: FontWeight.w600,
          );
        }
        return const TextStyle(color: Colors.transparent);
    }
  }

  String _blankFor(String word) {
    final clean = word.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    final length = clean.isEmpty ? 3 : clean.length;
    return List<String>.filled(length, 'ـ').join();
  }
}
