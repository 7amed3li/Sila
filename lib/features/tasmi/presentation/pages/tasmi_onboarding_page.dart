import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_preferences.dart';
import 'package:sila_app/features/tasmi/presentation/riverpod/tasmi_preferences_provider.dart';

class TasmiOnboardingPage extends ConsumerStatefulWidget {
  const TasmiOnboardingPage({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<TasmiOnboardingPage> createState() =>
      _TasmiOnboardingPageState();
}

class _TasmiOnboardingPageState extends ConsumerState<TasmiOnboardingPage> {
  OnErrorBehavior _onError = OnErrorBehavior.speakAndContinue;
  AttemptsMode _attempts = AttemptsMode.two;
  bool _ttsEnabled = true;
  StrictnessLevel _strictness = StrictnessLevel.medium;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tasmi_onboarding_title'.tr(),
                style: AppFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'tasmi_onboarding_subtitle'.tr(),
                style: AppFonts.cairo(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _SectionTitle('on_error_behavior_title'.tr(), isDark),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      selected: _onError == OnErrorBehavior.speakAndContinue,
                      icon: Icons.record_voice_over_rounded,
                      title: 'behavior_speak_continue'.tr(),
                      subtitle: 'behavior_speak_continue_desc'.tr(),
                      onTap: () => setState(
                          () => _onError = OnErrorBehavior.speakAndContinue),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ChoiceCard(
                      selected: _onError == OnErrorBehavior.waitForUser,
                      icon: Icons.pause_circle_rounded,
                      title: 'behavior_wait_user'.tr(),
                      subtitle: 'behavior_wait_user_desc'.tr(),
                      onTap: () => setState(
                          () => _onError = OnErrorBehavior.waitForUser),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ChoiceCard(
                      selected: _onError == OnErrorBehavior.continueOnly,
                      icon: Icons.skip_next_rounded,
                      title: 'behavior_continue_only'.tr(),
                      subtitle: 'behavior_continue_only_desc'.tr(),
                      onTap: () => setState(
                          () => _onError = OnErrorBehavior.continueOnly),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle('attempts_before_error_title'.tr(), isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AttemptsChip(
                          label: 'one_time'.tr(),
                          selected: _attempts == AttemptsMode.one,
                          onTap: () =>
                              setState(() => _attempts = AttemptsMode.one),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _AttemptsChip(
                          label: 'two_times'.tr(),
                          selected: _attempts == AttemptsMode.two,
                          onTap: () =>
                              setState(() => _attempts = AttemptsMode.two),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _AttemptsChip(
                          label: 'three_times'.tr(),
                          selected: _attempts == AttemptsMode.three,
                          onTap: () =>
                              setState(() => _attempts = AttemptsMode.three),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle('tts_enable_title'.tr(), isDark),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppTheme.darkSurfaceColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _ttsEnabled,
                        activeColor: AppTheme.accentColor,
                        onChanged: (value) =>
                            setState(() => _ttsEnabled = value),
                        title: Text(
                          'correction_voice'.tr(),
                          style: AppFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                        subtitle: Text(
                          _ttsEnabled ? 'enabled'.tr() : 'disabled'.tr(),
                          style: AppFonts.cairo(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle('strictness_title'.tr(), isDark),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      selected: _strictness == StrictnessLevel.easy,
                      icon: Icons.sentiment_satisfied_rounded,
                      title: 'lenient'.tr(),
                      subtitle: 'strictness_easy_desc'.tr(),
                      onTap: () =>
                          setState(() => _strictness = StrictnessLevel.easy),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ChoiceCard(
                      selected: _strictness == StrictnessLevel.medium,
                      icon: Icons.sentiment_neutral_rounded,
                      title: 'medium'.tr(),
                      subtitle: 'strictness_medium_desc'.tr(),
                      onTap: () =>
                          setState(() => _strictness = StrictnessLevel.medium),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ChoiceCard(
                      selected: _strictness == StrictnessLevel.strict,
                      icon: Icons.sentiment_very_dissatisfied_rounded,
                      title: 'strict'.tr(),
                      subtitle: 'strictness_strict_desc'.tr(),
                      onTap: () =>
                          setState(() => _strictness = StrictnessLevel.strict),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'start_tasmi_button'.tr(),
                    style: AppFonts.cairo(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final prefs = TasmiPreferences(
      onErrorBehavior: _onError,
      attemptsMode: _attempts,
      ttsEnabled: _ttsEnabled,
      strictness: _strictness,
      isOnboardingDone: true,
    );
    await ref.read(tasmiPreferencesNotifierProvider.notifier).update(prefs);
    widget.onDone();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.cairo(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppTheme.primaryColor,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppTheme.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.1)
              : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
          border: Border.all(
            color: selected
                ? activeColor
                : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
            width: selected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? activeColor
                    : (isDark ? Colors.white54 : Colors.grey),
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: selected
                          ? activeColor
                          : (isDark ? Colors.white : AppTheme.primaryColor),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppFonts.cairo(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: activeColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _AttemptsChip extends StatelessWidget {
  const _AttemptsChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppTheme.accentColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? activeColor
                : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
            border: Border.all(
              color: selected
                  ? activeColor
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
              width: selected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white : AppTheme.primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}
