import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/controllers/ibadah_tracker_controller.dart';

Future<void> showIbadahDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String ibadahKey,
  required String label,
  required String icon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => SafeArea(
      minimum: const EdgeInsets.only(bottom: 18),
      child: _IbadahDetailSheet(ibadahKey: ibadahKey, label: label, icon: icon),
    ),
  );
}

class _IbadahDetailSheet extends ConsumerWidget {
  const _IbadahDetailSheet(
      {required this.ibadahKey, required this.label, required this.icon});

  final String ibadahKey;
  final String label;
  final String icon;

  bool _isPrayer(String key) =>
      ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].contains(key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ibadahTrackerControllerProvider);
    return state.when(
      data: (data) {
        final isPrayer = _isPrayer(ibadahKey);
        final isMale = data.isMale;
        final controller = ref.read(ibadahTrackerControllerProvider.notifier);

        Future<void> saveAndClose(Future<void> Function() action) async {
          await action();
          if (!context.mounted) return;
          await HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'tracker_statuses.saved_successfully'.tr(),
                  style: AppFonts.getFont('Cairo', fontWeight: FontWeight.w700),
                ),
                duration: const Duration(milliseconds: 700),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            );
          Navigator.pop(context);
        }

        int? prayerStatus;
        bool? inMasjid;
        bool? boolStatus;

        switch (ibadahKey) {
          case 'fajr':
            prayerStatus = data.today.fajrStatus;
            inMasjid = data.today.fajrInMasjid;
            break;
          case 'dhuhr':
            prayerStatus = data.today.dhuhrStatus;
            inMasjid = data.today.dhuhrInMasjid;
            break;
          case 'asr':
            prayerStatus = data.today.asrStatus;
            inMasjid = data.today.asrInMasjid;
            break;
          case 'maghrib':
            prayerStatus = data.today.maghribStatus;
            inMasjid = data.today.maghribInMasjid;
            break;
          case 'isha':
            prayerStatus = data.today.ishaStatus;
            inMasjid = data.today.ishaInMasjid;
            break;
          case 'wird':
            boolStatus = data.today.readWird;
            break;
          case 'azkar_sabah':
            boolStatus = data.today.readAzkarSabah;
            break;
          case 'azkar_masa':
            boolStatus = data.today.readAzkarMasa;
            break;
          case 'tasbih':
            boolStatus = data.today.didTasbih;
            break;
          case 'hifz':
            boolStatus = data.today.didHifz || data.today.didTasmi;
            break;
          case 'dhikr':
            boolStatus = data.today.rememberedAllah;
            break;
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$icon $label',
                  style: AppFonts.getFont('Cairo',
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                if (isPrayer) ...[
                  Text(
                    'tracker_statuses.how_did_you_pray'.tr(),
                    style: AppFonts.getFont('Cairo',
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusOption(
                        label: 'tracker_statuses.on_time'.tr(),
                        emoji: '✅',
                        selected: prayerStatus == 1,
                        onTap: () async {
                          if (!isMale) {
                            await saveAndClose(
                              () => controller.updatePrayerStatus(
                                  prayer: ibadahKey, status: 1),
                            );
                            return;
                          }
                          await controller.updatePrayerStatus(
                              prayer: ibadahKey, status: 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusOption(
                        label: 'tracker_statuses.late'.tr(),
                        emoji: '🕐',
                        selected: prayerStatus == 2,
                        onTap: () async {
                          if (!isMale) {
                            await saveAndClose(
                              () => controller.updatePrayerStatus(
                                  prayer: ibadahKey, status: 2),
                            );
                            return;
                          }
                          await controller.updatePrayerStatus(
                              prayer: ibadahKey, status: 2);
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusOption(
                        label: 'tracker_statuses.missed'.tr(),
                        emoji: '❌',
                        selected: prayerStatus == 0,
                        onTap: () => saveAndClose(
                          () => controller.updatePrayerStatus(
                              prayer: ibadahKey, status: 0),
                        ),
                      ),
                    ],
                  ),
                  if (isMale) ...[
                    const SizedBox(height: 16),
                    Text(
                      'tracker_statuses.where_did_you_pray'.tr(),
                      style: AppFonts.getFont('Cairo',
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatusOption(
                          label: 'tracker_statuses.in_masjid'.tr(),
                          emoji: '🕌',
                          selected: inMasjid == true,
                          onTap: () => saveAndClose(
                            () => controller.updateMasjidStatus(
                                prayer: ibadahKey, inMasjid: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusOption(
                          label: 'tracker_statuses.at_home'.tr(),
                          emoji: '🏠',
                          selected: inMasjid == false,
                          onTap: () => saveAndClose(
                            () => controller.updateMasjidStatus(
                                prayer: ibadahKey, inMasjid: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _BigToggle(
                          label: '${'tracker_statuses.yes'.tr()} ✅',
                          selected: boolStatus == true,
                          color: const Color(0xFF064E3B),
                          onTap: () => saveAndClose(
                            () => controller.updateBoolStatus(
                                key: ibadahKey, value: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BigToggle(
                          label: '${'tracker_statuses.no'.tr()} ❌',
                          selected: boolStatus == false,
                          color: Colors.red.shade400,
                          onTap: () => saveAndClose(
                            () => controller.updateBoolStatus(
                                key: ibadahKey, value: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
          height: 280, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 280),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption(
      {required this.label,
      required this.emoji,
      required this.selected,
      required this.onTap});
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF064E3B).withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
                color: selected
                    ? const Color(0xFF064E3B)
                    : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label, style: AppFonts.getFont('Cairo', fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigToggle extends StatelessWidget {
  const _BigToggle(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(label,
              style: AppFonts.getFont('Cairo', fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
