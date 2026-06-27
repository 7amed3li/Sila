import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_settings_controller.dart';

class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({
    super.key,
    required this.featureKey,
  });
  final String featureKey;

  @override
  ConsumerState<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends ConsumerState<NotificationSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final featureKey = widget.featureKey;
    final state = ref.watch(notificationSettingsProvider(featureKey));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFDCE3EE);
    final title = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF102A43);
    final subtitle = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF486581);

    return state.when(
      data: (settings) {
        return Container(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6FFFA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.notifications_active_rounded,
                                  size: 18,
                                  color: Color(0xFF0F766E)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'notification_reminder_settings'.tr(),
                                  style: AppFonts.getFont(
                                    'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: title,
                                  ),
                                ),
                                Text(
                                  'customize_reminders'.tr(),
                                  style: AppFonts.getFont(
                                    'Cairo',
                                    fontSize: 11,
                                    color: subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: settings.isEnabled,
                          activeColor: const Color(0xFF064E3B),
                          title: Text(
                            'enable_reminder'.tr(),
                            style: AppFonts.getFont('Cairo',
                                color: title, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            settings.isEnabled
                                ? 'notifications_active_now'.tr()
                                : 'notifications_disabled_now'.tr(),
                            style: AppFonts.getFont('Cairo',
                                color: subtitle, fontSize: 11),
                          ),
                          onChanged: (v) => ref
                              .read(notificationSettingsProvider(featureKey)
                                  .notifier)
                              .toggleEnabled(v),
                        ),
                      ],
                    ),
                  ),
                  if (settings.isEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('repeat_frequency'.tr(),
                              style: AppFonts.getFont(
                                'Cairo',
                                color: title,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: settings.frequency,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF7FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: border),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text('daily'.tr(),
                                    style: AppFonts.getFont('Cairo')),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text('weekly'.tr(),
                                    style: AppFonts.getFont('Cairo')),
                              ),
                              DropdownMenuItem(
                                value: 'smart',
                                child: Text('smart'.tr(),
                                    style: AppFonts.getFont('Cairo')),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(
                                        notificationSettingsProvider(featureKey)
                                            .notifier)
                                    .setFrequency(v);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          Text('preferred_content_type'.tr(),
                              style: AppFonts.getFont(
                                'Cairo',
                                color: title,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TypeChip(
                                  featureKey: featureKey,
                                  type: 'hadith',
                                  label: 'hadith'.tr()),
                              _TypeChip(
                                  featureKey: featureKey,
                                  type: 'ayah',
                                  label: 'verse'.tr()),
                              _TypeChip(
                                  featureKey: featureKey,
                                  type: 'dhikr',
                                  label: 'dhikr'.tr()),
                              _TypeChip(
                                  featureKey: featureKey,
                                  type: 'hikma',
                                  label: 'wisdom'.tr()),
                            ],
                          ),
                          if (featureKey == 'azkar') ...[
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: settings.endTimeReminderEnabled,
                              activeColor: const Color(0xFF064E3B),
                              title: Text(
                                'reminder_before_end'.tr(),
                                style: AppFonts.getFont('Cairo',
                                    color: title, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'reminder_before_end_desc'.tr(),
                                style: AppFonts.getFont('Cairo',
                                    color: subtitle, fontSize: 11),
                              ),
                              onChanged: (v) => ref
                                  .read(notificationSettingsProvider(featureKey)
                                      .notifier)
                                  .toggleEndTimeReminder(v),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('settings_load_error'.tr()),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(notificationSettingsProvider(featureKey)),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('retry'.tr(), style: AppFonts.getFont('Cairo')),
              ),
              const SizedBox(height: 4),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: AppFonts.getFont('Cairo',
                    fontSize: 10, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends ConsumerWidget {
  const _TypeChip({
    required this.featureKey,
    required this.type,
    required this.label,
  });
  final String featureKey;
  final String type;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider(featureKey));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final chipSelected =
        isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1);
    final chipBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFDCE3EE);
    final textColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final selected = state.value?.preferredTypes.contains(type) ?? false;
    return ChoiceChip(
      label: Text(label,
          style: AppFonts.getFont('Cairo',
              color: textColor, fontWeight: FontWeight.w700)),
      selected: selected,
      backgroundColor: chipBg,
      selectedColor: chipSelected,
      side: BorderSide(color: chipBorder),
      onSelected: (_) => ref
          .read(notificationSettingsProvider(featureKey).notifier)
          .togglePreferredType(type),
    );
  }
}
