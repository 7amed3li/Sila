import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sila_app/features/azkar/presentation/pages/azkar_page.dart';
import 'package:sila_app/features/azkar/presentation/pages/tasbih_page.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_home_page.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_detail_controller.dart';
import 'package:sila_app/features/prayers/presentation/pages/prayers_page.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_surah_selection_page.dart';
import 'package:sila_app/features/wird/presentation/pages/wird_history_page.dart';

class NotificationDetailPage extends ConsumerWidget {
  const NotificationDetailPage({
    super.key,
    required this.contentId,
    required this.category,
  });
  final String contentId;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFF7FAFC);
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final lineColor =
        isDark ? const Color(0xFF243041) : const Color(0xFFE2E8F0);
    final titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final metaColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final detailAsync = ref.watch(notificationDetailProvider(contentId));
    return Scaffold(
      backgroundColor: backgroundColor,
      body: detailAsync.when(
        data: (content) {
          if (content == null) {
            return const Center(child: Text('المحتوى غير متوفر'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: const Color(0xFF064E3B),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: isDark
                            ? const [Color(0xFF064E3B), Color(0xFF0F766E)]
                            : const [Color(0xFF065F46), Color(0xFF0EA5A0)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _iconFor(content.category),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getCategoryName(content.category),
                            style: AppFonts.getFont(
                              'Cairo',
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lineColor),
                      ),
                      child: Text(
                        content.arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppFonts.getFont(
                          'Amiri',
                          fontSize: 24,
                          height: 2.0,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${content.source} • ${content.grade}',
                      style: AppFonts.getFont('Cairo', color: metaColor),
                    ),
                    if (content.shortExplanation.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lineColor),
                        ),
                        child: Text(
                          content.shortExplanation,
                          style: AppFonts.getFont('Cairo',
                              fontSize: 13, color: titleColor),
                        ),
                      ),
                    ],
                    if (content.type == 'ayah' &&
                        content.surahNumber > 0 &&
                        content.ayahNumber > 0) ...[
                      const SizedBox(height: 12),
                      _TafsirCard(
                        key: ValueKey(
                            'tafsir_${content.surahNumber}_${content.ayahNumber}'),
                        surahNumber: content.surahNumber,
                        ayahNumber: content.ayahNumber,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              'شارك',
                              style: AppFonts.getFont('Cairo',
                                  fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(color: lineColor),
                              foregroundColor: const Color(0xFF065F46),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bookmark_outline_rounded,
                                size: 18),
                            label: Text(
                              'احفظ',
                              style: AppFonts.getFont('Cairo',
                                  fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(color: lineColor),
                              foregroundColor: const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          _navigateToFeature(context, content.category),
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      label: Text(
                        'اذهب إلى ${_getCategoryName(content.category)}',
                        style: AppFonts.getFont(
                          'Cairo',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('حدث خطأ أثناء تحميل المحتوى')),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'azkar':
        return 'الأذكار';
      case 'wird':
        return 'الورد';
      case 'hifz':
        return 'الحفظ';
      case 'tasmi':
        return 'التسميع';
      case 'tasbih':
        return 'التسبيح';
      case 'salah':
        return 'الصلاة';
      default:
        return 'التذكيرات';
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'azkar':
        return Icons.auto_awesome_rounded;
      case 'wird':
        return Icons.menu_book_rounded;
      case 'hifz':
        return Icons.school_rounded;
      case 'tasmi':
        return Icons.mic_rounded;
      case 'tasbih':
        return Icons.brightness_3_rounded;
      case 'salah':
        return Icons.mosque_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  void _navigateToFeature(BuildContext context, String target) {
    Widget page;
    switch (target) {
      case 'azkar':
        page = const AzkarPage();
        break;
      case 'wird':
        page = const WirdHistoryPage();
        break;
      case 'hifz':
        page = const HifzHomePage();
        break;
      case 'tasmi':
        page = const TasmiSurahSelectionPage();
        break;
      case 'tasbih':
        page = const TasbihPage();
        break;
      case 'salah':
      default:
        page = const PrayersPage();
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _TafsirCard extends StatefulWidget {
  const _TafsirCard({
    required super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });
  final int surahNumber;
  final int ayahNumber;

  @override
  State<_TafsirCard> createState() => _TafsirCardState();
}

class _TafsirCardState extends State<_TafsirCard> {
  late Future<String?> _tafsirFuture;

  @override
  void initState() {
    super.initState();
    _tafsirFuture = _fetchTafsir();
  }

  Future<String?> _fetchTafsir() async {
    try {
      final url = Uri.parse(
        'https://api.quran-tafseer.com/tafseer/3/${widget.surahNumber}/${widget.ayahNumber}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        final text = data['text'];
        if (text is String && text.trim().isNotEmpty) return text.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF243041) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final title = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtitle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: FutureBuilder<String?>(
        future: _tafsirFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('جاري تحميل تفسير السعدي...',
                    style: AppFonts.getFont('Cairo', color: subtitle)),
              ],
            );
          }

          final tafsir = snapshot.data;
          if (tafsir == null || tafsir.isEmpty) {
            return Text(
              'تعذر تحميل التفسير الآن. سيبقى النص القرآني متاحًا بالكامل دون إنترنت.',
              style: AppFonts.getFont('Cairo', fontSize: 12, color: subtitle),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفسير السعدي',
                style: AppFonts.getFont('Cairo',
                    fontWeight: FontWeight.w700, color: title),
              ),
              const SizedBox(height: 8),
              Text(
                tafsir,
                textDirection: TextDirection.rtl,
                style: AppFonts.getFont('Cairo',
                    fontSize: 13, height: 1.8, color: title),
              ),
            ],
          );
        },
      ),
    );
  }
}
