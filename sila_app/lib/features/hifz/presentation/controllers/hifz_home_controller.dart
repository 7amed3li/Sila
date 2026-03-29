import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/features/hifz/data/models/hifz_moment.dart';
import 'package:sila_app/features/hifz/data/models/hifz_session.dart';
import 'package:sila_app/features/hifz/data/models/hifz_user_profile.dart';
import 'package:sila_app/features/hifz/data/repositories/hifz_repository_provider.dart';
import 'package:sila_app/features/hifz/data/repositories/i_hifz_repository.dart';
import 'package:sila_app/features/hifz/domain/hasanat_calculator.dart';
import 'package:sila_app/features/hifz/domain/plan_generator.dart';

part 'hifz_home_controller.g.dart';

class HifzHomeState {
  const HifzHomeState({
    required this.isLoading,
    required this.profile,
    required this.plan,
    required this.doneAyahsToday,
    required this.targetAyahsToday,
    required this.reviewDueCount,
    required this.streakDays,
    required this.hasanatToday,
    required this.recentMoments,
    required this.activeSession,
    required this.resumeSurah,
    required this.resumeFromVerse,
    required this.resumeToVerse,
    required this.errorMessage,
  });

  factory HifzHomeState.initial() {
    return const HifzHomeState(
      isLoading: true,
      profile: null,
      plan: null,
      doneAyahsToday: 0,
      targetAyahsToday: 1,
      reviewDueCount: 0,
      streakDays: 0,
      hasanatToday: 0,
      recentMoments: [],
      activeSession: null,
      resumeSurah: 0,
      resumeFromVerse: 0,
      resumeToVerse: 0,
      errorMessage: null,
    );
  }
  final bool isLoading;
  final HifzUserProfile? profile;
  final HifzDailyPlan? plan;
  final int doneAyahsToday;
  final int targetAyahsToday;
  final int reviewDueCount;
  final int streakDays;
  final int hasanatToday;
  final List<HifzMoment> recentMoments;
  final HifzSession? activeSession;
  final int resumeSurah;
  final int resumeFromVerse;
  final int resumeToVerse;
  final String? errorMessage;

  bool get hasResumePoint =>
      resumeSurah > 0 &&
      resumeFromVerse > 0 &&
      resumeToVerse > 0 &&
      resumeFromVerse <= resumeToVerse;

  HifzHomeState copyWith({
    bool? isLoading,
    HifzUserProfile? profile,
    HifzDailyPlan? plan,
    int? doneAyahsToday,
    int? targetAyahsToday,
    int? reviewDueCount,
    int? streakDays,
    int? hasanatToday,
    List<HifzMoment>? recentMoments,
    HifzSession? activeSession,
    bool clearActiveSession = false,
    int? resumeSurah,
    int? resumeFromVerse,
    int? resumeToVerse,
    bool clearResumePoint = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HifzHomeState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      doneAyahsToday: doneAyahsToday ?? this.doneAyahsToday,
      targetAyahsToday: targetAyahsToday ?? this.targetAyahsToday,
      reviewDueCount: reviewDueCount ?? this.reviewDueCount,
      streakDays: streakDays ?? this.streakDays,
      hasanatToday: hasanatToday ?? this.hasanatToday,
      recentMoments: recentMoments ?? this.recentMoments,
      activeSession:
          clearActiveSession ? null : activeSession ?? this.activeSession,
      resumeSurah: clearResumePoint ? 0 : resumeSurah ?? this.resumeSurah,
      resumeFromVerse:
          clearResumePoint ? 0 : resumeFromVerse ?? this.resumeFromVerse,
      resumeToVerse: clearResumePoint ? 0 : resumeToVerse ?? this.resumeToVerse,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class HifzHomeController extends _$HifzHomeController {
  static const _notificationId = 7001;
  static const _streakKey = 'hifz_streak_days';
  static const _streakDateKey = 'hifz_streak_last_date';
  static const _resumeSurahKey = 'hifz_resume_surah';
  static const _resumeFromVerseKey = 'hifz_resume_from';
  static const _resumeToVerseKey = 'hifz_resume_to';

  @override
  HifzHomeState build() {
    Future<void>.microtask(loadHome);
    return HifzHomeState.initial();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final repository = await ref.read(hifzRepositoryProvider.future);
      final profile = await repository.getProfile();

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'لم يتم إعداد خطة الحفظ بعد',
        );
        return;
      }

      final plan = PlanGenerator.generate(profile);
      final recentMoments = await repository.getRecentMoments(12);
      final todaySessions = await _getTodaySessions(repository);
      final dueReviews = await repository.getDueReviews(DateTime.now());
      final activeSession = await _findActiveSession(repository);
      final streak = await _calculateStreak(todaySessions.isNotEmpty);
      final resumePoint = await _loadResumePoint();

      final doneAyahs = _countDoneAyahs(todaySessions);
      final targetAyahs = plan.newAyahsTarget;
      final hasanat = _calculateTodayHasanat(todaySessions);

      state = state.copyWith(
        isLoading: false,
        profile: profile,
        plan: plan,
        doneAyahsToday: doneAyahs,
        targetAyahsToday: targetAyahs,
        reviewDueCount: dueReviews.length,
        streakDays: streak,
        hasanatToday: hasanat,
        recentMoments: recentMoments,
        activeSession: activeSession,
        resumeSurah: resumePoint['surah'],
        resumeFromVerse: resumePoint['fromVerse'],
        resumeToVerse: resumePoint['toVerse'],
      );

      await _scheduleDailyHifzReminder(
        remainingAyahs: (targetAyahs - doneAyahs).clamp(0, targetAyahs),
        dueReviews: dueReviews.length,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل بيانات الحفظ الآن',
      );
    }
  }

  Future<void> refresh() async {
    await loadHome();
  }

  Future<void> loadTodayStats() async {
    await loadHome();
  }

  Future<void> loadRecentMoments() async {
    await loadHome();
  }

  Future<void> loadDueReviews() async {
    await loadHome();
  }

  Future<void> startSession(String method) async {
    final _ = method;
    await loadHome();
  }

  Future<void> startReviewSession() async {
    await startSession('smart_review');
  }

  Future<void> startListeningSession() async {
    await startSession('listening');
  }

  Future<void> startRepetitionSession() async {
    await startSession('repetition');
  }

  Future<void> continueSession() async {
    await loadHome();
  }

  int _countDoneAyahs(List<HifzSession> sessions) {
    var total = 0;
    for (final session in sessions) {
      total += session.toVerse - session.fromVerse + 1;
    }
    return total;
  }

  int _calculateTodayHasanat(List<HifzSession> sessions) {
    var hasanat = 0;
    for (final session in sessions) {
      if (session.hasanat > 0) {
        hasanat += session.hasanat;
      } else {
        final charsApprox = session.correctWords + session.wrongWords;
        hasanat += HasanatCalculator.calculate('ا' * charsApprox);
      }
    }
    return hasanat;
  }

  Future<List<HifzSession>> _getTodaySessions(
      IHifzRepository repository) async {
    final recent = await repository.getRecentSessions(50);
    final now = DateTime.now();
    return recent
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .toList();
  }

  Future<HifzSession?> _findActiveSession(IHifzRepository repository) async {
    final recent = await repository.getRecentSessions(20);
    if (recent.isEmpty) {
      return null;
    }
    final latest = recent.first;
    final age = DateTime.now().difference(latest.date);
    if (age.inMinutes <= 45) {
      return latest;
    }
    return null;
  }

  Future<Map<String, int>> _loadResumePoint() async {
    const empty = {'surah': 0, 'fromVerse': 0, 'toVerse': 0};
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_resumeSurahKey) ||
        !prefs.containsKey(_resumeFromVerseKey) ||
        !prefs.containsKey(_resumeToVerseKey)) {
      return empty;
    }
    final surah = prefs.getInt(_resumeSurahKey)!;
    final from = prefs.getInt(_resumeFromVerseKey)!;
    final to = prefs.getInt(_resumeToVerseKey)!;
    if (surah < 1 || from < 1 || to < 1 || from > to) {
      // Invalid data — clean up
      await prefs.remove(_resumeSurahKey);
      await prefs.remove(_resumeFromVerseKey);
      await prefs.remove(_resumeToVerseKey);
      return empty;
    }
    return {'surah': surah, 'fromVerse': from, 'toVerse': to};
  }

  Future<void> saveResumePoint({
    required int surah,
    required int fromVerse,
    required int toVerse,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resumeSurahKey, surah);
    await prefs.setInt(_resumeFromVerseKey, fromVerse);
    await prefs.setInt(_resumeToVerseKey, toVerse);
    // FIX: Update in-memory state so UI refreshes immediately
    state = state.copyWith(
      resumeSurah: surah,
      resumeFromVerse: fromVerse,
      resumeToVerse: toVerse,
    );
  }

  Future<void> clearResumePoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resumeSurahKey);
    await prefs.remove(_resumeFromVerseKey);
    await prefs.remove(_resumeToVerseKey);
    state = state.copyWith(clearResumePoint: true);
  }

  Future<int> _calculateStreak(bool hasSessionToday) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_streakKey) ?? 0;
    final lastDate = prefs.getString(_streakDateKey);
    final today = DateTime.now();

    if (!hasSessionToday) {
      return saved;
    }

    final todayKey = '${today.year}-${today.month}-${today.day}';
    if (lastDate == todayKey) {
      return saved == 0 ? 1 : saved;
    }

    var streak = 1;
    if (lastDate != null) {
      final parts = lastDate.split('-');
      if (parts.length == 3) {
        final prev = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(prev.year, prev.month, prev.day))
            .inDays;
        if (diff == 1) {
          streak = saved + 1;
        }
      }
    }

    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_streakDateKey, todayKey);
    return streak;
  }

  Future<void> _scheduleDailyHifzReminder({
    required int remainingAyahs,
    required int dueReviews,
  }) async {
    final notificationService = NotificationService();
    final body = remainingAyahs > 0
        ? 'تبقى ${_toArabicIndic(remainingAyahs)} آيات لتكمل هدفك اليوم'
        : 'لديك ${_toArabicIndic(dueReviews)} آيات للمراجعة';

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 5, 30);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await notificationService.scheduleDaily(
      id: _notificationId,
      title: 'وقت الحفظ اليوم 📖',
      body: body,
      dateTime: scheduled,
    );
  }

  String _toArabicIndic(int value) {
    final western = value.toString();
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (final unit in western.codeUnits) {
      final digit = unit - 48;
      if (digit >= 0 && digit <= 9) {
        buffer.write(digits[digit]);
      }
    }
    return buffer.toString();
  }
}
