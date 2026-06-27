import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_controller.dart';

class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});

  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final quranState = ref.watch(quranControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final txtP = isDark ? Colors.white : const Color(0xFF0F172A);
    final txtS = isDark ? Colors.white60 : const Color(0xFF64748B);
    const primaryColor = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: bg,
      body: quranState.when(
        data: (surahs) {
          final filteredSurahs = surahs.where((s) {
            if (_searchQuery.isEmpty) return true;
            return s.nameArabic.contains(_searchQuery) ||
                s.englishName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverAppBar(
                pinned: true,
                backgroundColor: primaryColor,
                expandedHeight: 160,
                elevation: 0,
                centerTitle: false,
                actions: const [
                  SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF064E3B),
                          Color(0xFF0a6b52),
                          Color(0xFF1a3a5c)
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'quran_title'.tr(),
                              style: AppFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'surah_count'.tr(args: ['${surahs.length}']),
                              style: AppFonts.cairo(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppFonts.cairo(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'search_surah'.tr(),
                          hintStyle: AppFonts.cairo(
                              color: Colors.white60, fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white60, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Surah List ──
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final surah = filteredSurahs[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SurahDetailPage(
                                surahNumber: surah.number,
                                surahName: context.locale.languageCode == 'ar'
                                    ? surah.nameArabic
                                    : context.locale.languageCode == 'en'
                                        ? surah.englishName
                                        : surah.nameTurkish,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Circular number
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${surah.number}',
                                    style: AppFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Name & info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.locale.languageCode == 'ar'
                                          ? surah.nameArabic
                                          : context.locale.languageCode == 'en'
                                              ? surah.englishName
                                              : surah.nameTurkish,
                                      style: AppFonts.amiri(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: txtP,
                                      ),
                                    ),
                                    Text(
                                      context.locale.languageCode == 'ar'
                                          ? '${surah.numberOfAyahs} آية · ${surah.revelationType}'
                                          : context.locale.languageCode == 'en'
                                              ? '${surah.numberOfAyahs} Verses · ${surah.revelationType}'
                                              : '${surah.numberOfAyahs} ${surah.revelationType == 'Meccan' ? 'Mecci' : 'Medini'}',
                                      style: AppFonts.cairo(
                                        fontSize: 11,
                                        color: txtS,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Large decorative name
                              Text(
                                context.locale.languageCode == 'ar'
                                    ? surah.nameArabic
                                    : context.locale.languageCode == 'en'
                                        ? surah.englishName
                                        : surah.nameTurkish,
                                style: AppFonts.amiri(
                                  fontSize: 22,
                                  color: primaryColor.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filteredSurahs.length,
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Text('Error: $error', style: TextStyle(color: txtP)),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color surface,
    Color txtP,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'quran_settings'.tr(),
              style: AppFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.palette_outlined, color: primaryColor),
              title: Text('appearance'.tr(), style: AppFonts.cairo()),
              trailing: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: primaryColor),
              onTap: () {
                // Toggle theme or show options
              },
            ),
            ListTile(
              leading: Icon(Icons.text_fields, color: primaryColor),
              title: Text('text_settings'.tr(), style: AppFonts.cairo()),
              onTap: () {
                // Navigate to a dedicated settings page if available
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
