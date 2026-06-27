import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/ibadah_record.dart';
import 'package:sila_app/features/ibadah_tracker/domain/comparison_engine.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_calculator.dart';
import 'package:sila_app/features/ibadah_tracker/domain/ibadah_content_selector.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/controllers/custom_ibadah_controller.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/controllers/daily_report_controller.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';

class DailyReportPage extends ConsumerStatefulWidget {
  const DailyReportPage({super.key});

  @override
  ConsumerState<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends ConsumerState<DailyReportPage> {
  int _selectedDays = 30;
  DateTimeRange? _customRange;
  late final DateTime _anchorDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorDay = DateTime(now.year, now.month, now.day);
  }

  String _hijriDate(BuildContext context) {
    final h = HijriCalendar.now();
    final month = tr('hijri_months.${h.hMonth}');
    if (context.locale.languageCode == 'ar') {
      return '${h.hDay} $month ${h.hYear}هـ';
    }
    return '${h.hDay} $month ${h.hYear}';
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(dailyReportProvider);
    final firstRecordDateAsync = ref.watch(firstRecordDateProvider);
    final customIbadahs = ref.watch(customIbadahListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: report.when(
        data: (data) {
          final today = data.today;
          final yesterday = data.yesterday;
          final hasYesterday = yesterday != null;
          final engine = ComparisonEngine();
          final dailyStatusText = DailyStatusCalculator.getDailyStatusText(
              today,
              isMale: data.isMale,
              languageCode: context.locale.languageCode,
              customIbadahs: customIbadahs);
          final ratioToday = DailyStatusCalculator.completionRatio(today,
              isMale: data.isMale, customIbadahs: customIbadahs);
          final ratioYesterday = hasYesterday
              ? DailyStatusCalculator.completionRatio(yesterday,
                  isMale: data.isMale, customIbadahs: customIbadahs)
              : 0.0;
          final todayBetter = hasYesterday
              ? engine.isTodayBetter(
                  today: today, yesterday: yesterday, isMale: data.isMale)
              : false;
          final comparisonText = hasYesterday
              ? engine.comparisonText(
                  today: today, yesterday: yesterday, isMale: data.isMale)
              : tr('daily_report_page.first_day_message');
          final hijriDate = _hijriDate(context);

          final completedItems = _completedItems(today,
              isMale: data.isMale, customIbadahs: customIbadahs);
          final incompleteItems = _incompleteItems(today,
              isMale: data.isMale, customIbadahs: customIbadahs);
          final todayCount = DailyStatusCalculator.completedCount(today,
              isMale: data.isMale, customIbadahs: customIbadahs);
          final todayTotal = DailyStatusCalculator.totalCount(
              isMale: data.isMale, customIbadahs: customIbadahs);
          final yesterdayCount = hasYesterday
              ? DailyStatusCalculator.completedCount(yesterday,
                  isMale: data.isMale, customIbadahs: customIbadahs)
              : 0;
          final yesterdayTotal = hasYesterday ? todayTotal : 0;

          final range = _customRange == null
              ? (
                  start: _anchorDay.subtract(Duration(days: _selectedDays - 1)),
                  end: _anchorDay,
                )
              : (
                  start: DateTime(
                    _customRange!.start.year,
                    _customRange!.start.month,
                    _customRange!.start.day,
                  ),
                  end: DateTime(
                    _customRange!.end.year,
                    _customRange!.end.month,
                    _customRange!.end.day,
                  ),
                );
          final rangeAsync = ref.watch(recordsRangeProvider(range));

          final firstRecordDate = firstRecordDateAsync.valueOrNull;
          final ageDays = firstRecordDate == null
              ? 1
              : DateTime(_anchorDay.year, _anchorDay.month, _anchorDay.day)
                      .difference(DateTime(firstRecordDate.year,
                          firstRecordDate.month, firstRecordDate.day))
                      .inDays +
                  1;
          final requiredDays = _customRange == null
              ? _selectedDays
              : range.end.difference(range.start).inDays + 1;
          final hasEnoughRange = ageDays >= requiredDays;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: const Color(0xFF064E3B),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF0a6b52)]),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr('daily_report_page.title'),
                            style: AppFonts.getFont(
                              'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            hijriDate,
                            style: AppFonts.getFont('Cairo',
                                fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DailyStatusCard(text: dailyStatusText),
                    const SizedBox(height: 12),
                    _StatsStrip(
                      todayCount: todayCount,
                      todayTotal: todayTotal,
                      yesterdayCount: yesterdayCount,
                      yesterdayTotal: yesterdayTotal,
                      hasYesterday: hasYesterday,
                    ),
                    const SizedBox(height: 12),
                    _SectionTitle(tr('daily_report_page.completed_today')),
                    _PillList(items: completedItems, positive: true),
                    const SizedBox(height: 12),
                    if (incompleteItems.isNotEmpty) ...[
                      _SectionTitle(
                          tr('daily_report_page.tomorrow_opportunity')),
                      _PillList(items: incompleteItems, positive: false),
                      const SizedBox(height: 12),
                    ],
                    if (hasYesterday) ...[
                      _ComparisonCard(
                        ratioToday: ratioToday,
                        ratioYesterday: ratioYesterday,
                        message: comparisonText,
                        todayBetter: todayBetter,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _SectionTitle(tr('daily_report_page.time_comparison')),
                    _RangeSelector(
                      selectedDays: _selectedDays,
                      customSelected: _customRange != null,
                      onSelect: (days) => setState(() {
                        _customRange = null;
                        _selectedDays = days;
                      }),
                      onCustomTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(_anchorDay.year - 1, 1, 1),
                          lastDate: _anchorDay,
                          initialDateRange: _customRange,
                          helpText: tr('daily_report_page.select_time_range'),
                        );
                        if (picked != null) {
                          setState(() {
                            _customRange = picked;
                            _selectedDays = -1;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    rangeAsync.when(
                      data: (records) {
                        if (!hasEnoughRange) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              _selectedDays == 7
                                  ? tr(
                                      'daily_report_page.weekly_comparison_unavailable')
                                  : _selectedDays == 30
                                      ? tr(
                                          'daily_report_page.monthly_comparison_unavailable')
                                      : _customRange != null
                                          ? tr(
                                              'daily_report_page.custom_range_unavailable')
                                          : tr(
                                              'daily_report_page.three_months_comparison_unavailable'),
                              textAlign: TextAlign.center,
                              style: AppFonts.getFont('Cairo',
                                  fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          );
                        }

                        return _CalendarHeatmap(
                          records: records,
                          isMale: data.isMale,
                          days: requiredDays,
                          endDate: _anchorDay,
                          firstDayMode: !hasYesterday,
                          customIbadahs: customIbadahs,
                        );
                      },
                      loading: () => const SizedBox(
                        height: 80,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (incompleteItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionTitle(tr('daily_report_page.sunnah_reminder')),
                      _ReminderCards(
                          items: incompleteItems, isMale: data.isMale),
                    ],
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            Center(child: Text(tr('daily_report_page.load_error'))),
      ),
    );
  }
}

class _DailyStatusCard extends StatelessWidget {
  const _DailyStatusCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFonts.getFont('Cairo', fontSize: 14, height: 1.8),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: AppFonts.getFont('Cairo',
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PillList extends StatelessWidget {
  const _PillList({required this.items, required this.positive});
  final List<_IbadahItem> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF064E3B) : const Color(0xFFD97706);
    return Column(
      children: items
          .map(
            (e) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                e.label,
                textAlign: TextAlign.right,
                style: AppFonts.getFont('Cairo',
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.todayCount,
    required this.todayTotal,
    required this.yesterdayCount,
    required this.yesterdayTotal,
    required this.hasYesterday,
  });

  final int todayCount;
  final int todayTotal;
  final int yesterdayCount;
  final int yesterdayTotal;
  final bool hasYesterday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            title: tr('daily_report_page.today_achievement'),
            value: '$todayCount / $todayTotal',
            accent: const Color(0xFF064E3B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            title: tr('daily_report_page.yesterday_achievement'),
            value: hasYesterday
                ? '$yesterdayCount / $yesterdayTotal'
                : tr('daily_report_page.not_available'),
            accent: const Color(0xFFD97706),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard(
      {required this.title, required this.value, required this.accent});
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.getFont('Cairo',
                fontSize: 11, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.getFont('Cairo',
                fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.ratioToday,
    required this.ratioYesterday,
    required this.message,
    required this.todayBetter,
  });

  final double ratioToday;
  final double ratioYesterday;
  final String message;
  final bool todayBetter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        children: [
          Text(tr('daily_report_page.comparison_yesterday'),
              style: AppFonts.getFont('Cairo', fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RatioBox(
                    label: tr('daily_report_page.yesterday'),
                    ratio: ratioYesterday,
                    active: false),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RatioBox(
                    label: tr('daily_report_page.today'),
                    ratio: ratioToday,
                    active: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: (todayBetter
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFD97706))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.getFont('Cairo',
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatioBox extends StatelessWidget {
  const _RatioBox(
      {required this.label, required this.ratio, required this.active});

  final String label;
  final double ratio;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF064E3B) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppFonts.getFont('Cairo', fontSize: 12, color: color)),
          const SizedBox(height: 6),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}٪',
            style: AppFonts.getFont('Cairo',
                fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  const _CalendarHeatmap({
    required this.records,
    required this.isMale,
    required this.days,
    required this.endDate,
    required this.firstDayMode,
    required this.customIbadahs,
  });
  final List<IbadahRecord> records;
  final bool isMale;
  final int days;
  final DateTime endDate;
  final bool firstDayMode;
  final List<String> customIbadahs;

  @override
  Widget build(BuildContext context) {
    final map = <int, IbadahRecord>{};
    for (final r in records) {
      final key = r.date.year * 10000 + r.date.month * 100 + r.date.day;
      map[key] = r;
    }

    final cells = <Widget>[];
    var completed = 0;
    var partial = 0;
    var empty = 0;

    for (var i = 0; i < days; i++) {
      final d = DateTime(endDate.year, endDate.month, endDate.day)
          .subtract(Duration(days: i));
      final key = d.year * 10000 + d.month * 100 + d.day;
      final rec = map[key];

      Color color;
      if (rec == null) {
        color = const Color(0xFFE2E8F0);
        empty++;
      } else {
        final ratio = DailyStatusCalculator.completionRatio(rec,
            isMale: isMale, customIbadahs: customIbadahs);
        if (ratio >= 0.8) {
          color = const Color(0xFF064E3B);
          completed++;
        } else if (ratio >= 0.35) {
          color = const Color(0xFFD97706);
          partial++;
        } else {
          color = const Color(0xFFE2E8F0);
          empty++;
        }
      }

      cells.add(
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
      );
    }

    if (firstDayMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          tr('daily_report_page.today_unavailable'),
          textAlign: TextAlign.center,
          style: AppFonts.getFont('Cairo',
              fontSize: 12, color: const Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('daily_report_page.heatmap_legend', args: [
            days.toString(),
            completed.toString(),
            partial.toString(),
            empty.toString()
          ]),
          textAlign: TextAlign.center,
          style: AppFonts.getFont('Cairo',
              fontSize: 11, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: cells.reversed.toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(
                color: const Color(0xFF064E3B),
                label: tr('daily_report_page.completed')),
            const SizedBox(width: 10),
            _LegendDot(
                color: const Color(0xFFD97706),
                label: tr('daily_report_page.partial')),
            const SizedBox(width: 10),
            _LegendDot(
                color: const Color(0xFFE2E8F0),
                label: tr('daily_report_page.no_record')),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppFonts.getFont('Cairo',
                fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedDays,
    required this.onSelect,
    required this.onCustomTap,
    required this.customSelected,
  });
  final int selectedDays;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustomTap;
  final bool customSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _RangeChip(
            label: tr('daily_report_page.week'),
            days: 7,
            selected: selectedDays == 7,
            onTap: onSelect),
        _RangeChip(
            label: tr('daily_report_page.month'),
            days: 30,
            selected: selectedDays == 30,
            onTap: onSelect),
        _RangeChip(
            label: tr('daily_report_page.three_months'),
            days: 90,
            selected: selectedDays == 90,
            onTap: onSelect),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onCustomTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (customSelected
                      ? const Color(0xFF064E3B)
                      : const Color(0xFF64748B))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (customSelected
                        ? const Color(0xFF064E3B)
                        : const Color(0xFF64748B))
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              tr('daily_report_page.custom'),
              style: AppFonts.getFont(
                'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: customSelected
                    ? const Color(0xFF064E3B)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip(
      {required this.label,
      required this.days,
      required this.selected,
      required this.onTap});
  final String label;
  final int days;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF064E3B) : const Color(0xFF64748B);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onTap(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: AppFonts.getFont('Cairo',
              fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

List<_IbadahItem> _completedItems(IbadahRecord r,
    {required bool isMale, List<String>? customIbadahs}) {
  final out = <_IbadahItem>[];
  if (r.fajrStatus > 0) {
    out.add(_IbadahItem(key: 'fajr', label: tr('daily_report_page.fajr')));
  }
  if (r.dhuhrStatus > 0) {
    out.add(_IbadahItem(key: 'dhuhr', label: tr('daily_report_page.dhuhr')));
  }
  if (r.asrStatus > 0) {
    out.add(_IbadahItem(key: 'asr', label: tr('daily_report_page.asr')));
  }
  if (r.maghribStatus > 0) {
    out.add(
        _IbadahItem(key: 'maghrib', label: tr('daily_report_page.maghrib')));
  }
  if (r.ishaStatus > 0) {
    out.add(_IbadahItem(key: 'isha', label: tr('daily_report_page.isha')));
  }
  if (r.readWird) {
    out.add(_IbadahItem(key: 'wird', label: tr('daily_report_page.wird')));
  }
  if (r.readAzkarSabah) {
    out.add(_IbadahItem(
        key: 'azkar_sabah', label: tr('daily_report_page.azkar_sabah')));
  }
  if (r.readAzkarMasa) {
    out.add(_IbadahItem(
        key: 'azkar_masa', label: tr('daily_report_page.azkar_masa')));
  }
  if (r.didTasbih) {
    out.add(_IbadahItem(key: 'tasbih', label: tr('daily_report_page.tasbih')));
  }
  if (r.didHifz || r.didTasmi) {
    out.add(
        _IbadahItem(key: 'hifz', label: tr('daily_report_page.hifz_tasmi')));
  }
  if (isMale) {
    if (r.fajrInMasjid == true) {
      out.add(_IbadahItem(
          key: 'fajr', label: tr('daily_report_page.fajr_congregation')));
    }
    if (r.dhuhrInMasjid == true) {
      out.add(_IbadahItem(
          key: 'dhuhr', label: tr('daily_report_page.dhuhr_congregation')));
    }
    if (r.asrInMasjid == true) {
      out.add(_IbadahItem(
          key: 'asr', label: tr('daily_report_page.asr_congregation')));
    }
    if (r.maghribInMasjid == true) {
      out.add(_IbadahItem(
          key: 'maghrib', label: tr('daily_report_page.maghrib_congregation')));
    }
    // Only one ishaInMasjid block
    if (r.ishaInMasjid == true) {
      out.add(_IbadahItem(
          key: 'isha', label: tr('daily_report_page.isha_congregation')));
    }
  }

  if (customIbadahs != null) {
    try {
      final currentNote = r.personalNote ?? '{}';
      final map = jsonDecode(currentNote) as Map<String, dynamic>;
      if (map.containsKey('custom') && map['custom'] is Map) {
        final customMap = map['custom'] as Map<String, dynamic>;
        for (final name in customIbadahs) {
          if (customMap[name] == true) {
            out.add(_IbadahItem(key: 'custom_$name', label: name));
          }
        }
      }

      if (map.containsKey('mujahadah') && map['mujahadah'] is Map) {
        final mujahadahMap = map['mujahadah'] as Map<String, dynamic>;
        for (final entry in mujahadahMap.entries) {
          if (entry.value == 2) {
            out.add(_IbadahItem(
                key: 'muja_${entry.key}',
                label: '🛡️ ${entry.key} (انتصار تام 🟢)'));
          } else if (entry.value == 1) {
            out.add(_IbadahItem(
                key: 'muja_${entry.key}',
                label: '🛡️ ${entry.key} (زلة عابرة 🟡)'));
          }
        }
      }
    } catch (_) {}
  }

  return out.isEmpty
      ? [
          _IbadahItem(
              key: 'general', label: tr('daily_report_page.general_start'))
        ]
      : out;
}

List<_IbadahItem> _incompleteItems(IbadahRecord r,
    {required bool isMale, List<String>? customIbadahs}) {
  final out = <_IbadahItem>[];
  if (r.fajrStatus == 0) {
    out.add(_IbadahItem(key: 'fajr', label: tr('daily_report_page.fajr')));
  }
  if (r.dhuhrStatus == 0) {
    out.add(_IbadahItem(key: 'dhuhr', label: tr('daily_report_page.dhuhr')));
  }
  if (r.asrStatus == 0) {
    out.add(_IbadahItem(key: 'asr', label: tr('daily_report_page.asr')));
  }
  if (r.maghribStatus == 0) {
    out.add(
        _IbadahItem(key: 'maghrib', label: tr('daily_report_page.maghrib')));
  }
  if (r.ishaStatus == 0) {
    out.add(_IbadahItem(key: 'isha', label: tr('daily_report_page.isha')));
  }
  if (!r.readWird) {
    out.add(_IbadahItem(key: 'wird', label: tr('daily_report_page.wird')));
  }
  if (!r.readAzkarSabah) {
    out.add(_IbadahItem(
        key: 'azkar_sabah', label: tr('daily_report_page.azkar_sabah')));
  }
  if (!r.readAzkarMasa) {
    out.add(_IbadahItem(
        key: 'azkar_masa', label: tr('daily_report_page.azkar_masa')));
  }
  if (!r.didTasbih) {
    out.add(_IbadahItem(key: 'tasbih', label: tr('daily_report_page.tasbih')));
  }
  if (!(r.didHifz || r.didTasmi)) {
    out.add(
        _IbadahItem(key: 'hifz', label: tr('daily_report_page.hifz_tasmi')));
  }
  if (isMale) {
    if (r.fajrStatus > 0 && r.fajrInMasjid == false) {
      out.add(_IbadahItem(
          key: 'fajr', label: tr('daily_report_page.fajr_congregation')));
    }
    if (r.dhuhrStatus > 0 && r.dhuhrInMasjid == false) {
      out.add(_IbadahItem(
          key: 'dhuhr', label: tr('daily_report_page.dhuhr_congregation')));
    }
    if (r.asrStatus > 0 && r.asrInMasjid == false) {
      out.add(_IbadahItem(
          key: 'asr', label: tr('daily_report_page.asr_congregation')));
    }
    if (r.maghribStatus > 0 && r.maghribInMasjid == false) {
      out.add(_IbadahItem(
          key: 'maghrib', label: tr('daily_report_page.maghrib_congregation')));
    }
    // Only one ishaStatus/ishaInMasjid block
    if (r.ishaStatus > 0 && r.ishaInMasjid == false) {
      out.add(_IbadahItem(
          key: 'isha', label: tr('daily_report_page.isha_congregation')));
    }
  }

  if (customIbadahs != null) {
    try {
      final currentNote = r.personalNote ?? '{}';
      final map = jsonDecode(currentNote) as Map<String, dynamic>;
      final customMap = (map.containsKey('custom') && map['custom'] is Map)
          ? map['custom'] as Map<String, dynamic>
          : <String, dynamic>{};

      for (final name in customIbadahs) {
        if (customMap[name] != true) {
          out.add(_IbadahItem(key: 'custom_$name', label: name));
        }
      }

      if (map.containsKey('mujahadah') && map['mujahadah'] is Map) {
        final mujahadahMap = map['mujahadah'] as Map<String, dynamic>;
        for (final entry in mujahadahMap.entries) {
          if (entry.value == 0) {
            out.add(_IbadahItem(
                key: 'muja_${entry.key}',
                label: '🛡️ ${entry.key} (انتكاسة 🔴)'));
          }
        }
      }
    } catch (_) {
      for (final name in customIbadahs) {
        out.add(_IbadahItem(key: 'custom_$name', label: name));
      }
    }
  }

  return out;
}

class _IbadahItem {
  const _IbadahItem({required this.key, required this.label});
  final String key;
  final String label;
}

class _ReminderCards extends ConsumerWidget {
  const _ReminderCards({required this.items, required this.isMale});
  final List<_IbadahItem> items;
  final bool isMale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(notificationRepositoryProvider);
    return repoAsync.when(
      data: (repo) {
        final selector = IbadahContentSelector(notificationRepository: repo);
        return Column(
          children: items
              .take(6)
              .map(
                (item) => FutureBuilder(
                  future: item.key.startsWith('custom_')
                      ? Future.value(null)
                      : selector.getContent(
                          ibadahKey: item.key,
                          completed: false,
                          inMasjid: item.label.contains('جماعة') ? false : null,
                          isMale: isMale,
                        ),
                  builder: (context, snapshot) {
                    final content = snapshot.data;
                    final text = ((content?.type == 'hadith' ||
                                content?.type == 'ayah') &&
                            (content?.arabicText.trim().isNotEmpty ?? false))
                        ? content!.arabicText
                        : (content?.shortText ?? '...');
                    final source = [
                      content?.source ?? '',
                      content?.grade ?? '',
                    ].where((e) => e.trim().isNotEmpty).join(' • ');
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF9F5EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: AppFonts.getFont('Cairo',
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF064E3B)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text,
                            style: AppFonts.getFont(
                              content?.type == 'ayah' ||
                                      content?.type == 'hadith'
                                  ? 'Amiri'
                                  : 'Cairo',
                              fontSize: content?.type == 'ayah' ||
                                      content?.type == 'hadith'
                                  ? 17
                                  : 12,
                              height: 1.8,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          if (source.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(source,
                                style: AppFonts.getFont('Cairo',
                                    fontSize: 10,
                                    color: const Color(0xFF64748B))),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
