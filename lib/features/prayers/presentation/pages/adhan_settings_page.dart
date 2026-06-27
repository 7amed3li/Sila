import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/core/services/adhan_native_service.dart';
import 'package:sila_app/core/services/adhan_scheduler_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/features/prayers/data/repositories/prayer_repository_impl.dart';
import 'package:sila_app/features/prayers/presentation/riverpod/prayer_controller.dart';

class AdhanSettingsPage extends ConsumerStatefulWidget {
  const AdhanSettingsPage({super.key});
  @override
  ConsumerState<AdhanSettingsPage> createState() => _AdhanSettingsPageState();
}

class _AdhanSettingsPageState extends ConsumerState<AdhanSettingsPage> {
  final _prefs = PrefsService();
  final _adhanSvc = AdhanSchedulerService();

  bool _adhanEnabled = true;
  String _selectedSound = 'adhan_egypt.mp3';
  Map<String, bool> _prayerSettings = {
    'fajr': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  Map<String, String> _adhanModes = {
    'fajr': 'adhan',
    'dhuhr': 'adhan',
    'asr': 'adhan',
    'maghrib': 'adhan',
    'isha': 'adhan',
  };
  Map<String, int> _reminderMinutes = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  static const _sounds = {
    'adhan_egypt.mp3': 'egypt_adhan',
    'adhan_mecca.mp3': 'adhan_mecca',
    'adhan_medina.mp3': 'adhan_medina',
    'adhan_mishary.mp3': 'adhan_mishary',
    'adhan_turkey.mp3': 'adhan_turkey',
  };

  static const _prayerList = [
    {'key': 'fajr', 'name': 'الفجر', 'icon': Icons.wb_twilight_rounded},
    {'key': 'dhuhr', 'name': 'الظهر', 'icon': Icons.wb_sunny_rounded},
    {'key': 'asr', 'name': 'العصر', 'icon': Icons.wb_sunny_outlined},
    {'key': 'maghrib', 'name': 'المغرب', 'icon': Icons.wb_incandescent_rounded},
    {'key': 'isha', 'name': 'العشاء', 'icon': Icons.nightlight_round},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _prefs.isAdhanNotificationsEnabled();
    final sound = await _prefs.getAdhanSound();
    final settings = <String, bool>{};
    final modes = <String, String>{};
    final reminders = <String, int>{};
    for (final p in _prayerList) {
      final key = p['key'] as String;
      settings[key] = await _prefs.isAdhanEnabled(key);
      modes[key] = await _prefs.getAdhanMode(key) ?? 'adhan';
      reminders[key] = await _prefs.getPrayerReminderMinutes(key) ?? 0;
    }
    if (mounted) {
      setState(() {
        _adhanEnabled = enabled;
        _selectedSound = sound;
        _prayerSettings = settings;
        _adhanModes = modes;
        _reminderMinutes = reminders;
      });
    }
  }

  Future<void> _setAdhanMode(String prayer, String mode) async {
    await _prefs.setAdhanMode(prayer, mode);
    await _applyScheduleChanges();
    if (!mounted) return;
    setState(() => _adhanModes[prayer] = mode);
  }

  Future<void> _setReminderMinutes(String prayer, int minutes) async {
    await _prefs.setPrayerReminderMinutes(prayer, minutes);
    await _applyScheduleChanges();
    if (!mounted) return;
    setState(() => _reminderMinutes[prayer] = minutes);
  }

  Future<void> _toggleGlobal(bool v) async {
    await _prefs.setAdhanNotificationsEnabled(v);
    if (!v) {
      await _adhanSvc.cancelAllPrayers();
    } else {
      await _applyScheduleChanges();
    }
    if (!mounted) return;
    setState(() => _adhanEnabled = v);
    _snack(v ? 'adhan_enabled_message'.tr() : 'adhan_disabled_message'.tr());
  }

  Future<void> _togglePrayer(String key, bool v) async {
    await _prefs.setAdhanEnabled(key, v);
    ref.invalidate(prayerTimesControllerProvider);
    await _applyScheduleChanges();
    if (!mounted) return;
    setState(() => _prayerSettings[key] = v);
    _snack(v
      ? 'adhan_prayer_enabled'.tr(args: [_arabicName(key)])
      : 'adhan_prayer_disabled'.tr(args: [_arabicName(key)]));
  }

  Future<void> _changeSound(String f) async {
    await _prefs.setAdhanSound(f);
    await _applyScheduleChanges();
    if (!mounted) return;
    setState(() => _selectedSound = f);
    _snack('adhan_sound_changed'.tr());
  }

  Future<void> _applyScheduleChanges() async {
    try {
      await _adhanSvc.rescheduleDaily(PrayerRepositoryImpl());
    } catch (e) {
      debugPrint(
        'Failed to reschedule prayer notifications via '
        '_adhanSvc.rescheduleDaily(PrayerRepositoryImpl()): $e',
      );
      _snack('تعذر تحديث الجدولة. حاول مرة أخرى.');
    }
  }

  Future<void> _testAdhan() async {
    await _adhanSvc.testAdhan(_selectedSound);
    _snack('adhan_test_message'.tr());
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg, style: GoogleFonts.cairo()),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  String _arabicName(String key) {
    final match = _prayerList.firstWhere((p) => p['key'] == key,
        orElse: () => {'name': key});
    return match['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('adhan_settings'.tr(),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Global toggle ────────────────────────────────────────────────
          _card(
            child: SwitchListTile(
              title: Text('enable_adhan'.tr(),
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              subtitle: Text('adhan_notifications_enabled'.tr(),
                  style:
                      GoogleFonts.cairo(color: Colors.white38, fontSize: 12)),
              value: _adhanEnabled,
              onChanged: _toggleGlobal,
              activeColor: const Color(0xFF43A047),
            ),
          ),

          const SizedBox(height: 16),

          // ── Sound selector ───────────────────────────────────────────────
          _card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF66BB6A), size: 20),
              ),
              title: Text('adhan_sound_label'.tr(),
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(_sounds[_selectedSound]?.tr() ?? _selectedSound,
                  style:
                      GoogleFonts.cairo(color: Colors.white38, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
              onTap: _showSoundDialog,
            ),
          ),

          const SizedBox(height: 16),

          // ── Per-prayer ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('enable_per_prayer'.tr(),
                style: GoogleFonts.cairo(
                    color: const Color(0xFF43A047),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),

          _card(
            child: Column(
              children: _prayerList.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final key = p['key'] as String;
                final isEnabled = _prayerSettings[key] ?? true;
                return Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(p['icon'] as IconData,
                          color: _adhanEnabled && isEnabled
                              ? const Color(0xFF66BB6A)
                              : Colors.white24,
                          size: 22),
                      title: Text(p['name'] as String,
                          style: GoogleFonts.cairo(
                              color:
                                  _adhanEnabled ? Colors.white : Colors.white30,
                              fontSize: 15)),
                      value: isEnabled && _adhanEnabled,
                      onChanged:
                          _adhanEnabled ? (v) => _togglePrayer(key, v) : null,
                      activeColor: const Color(0xFF43A047),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Text('نوع الإشعار:',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _adhanModes[key],
                            dropdownColor: const Color(0xFF222B45),
                            items: const [
                              DropdownMenuItem(
                                  value: 'adhan',
                                  child: Text('تشغيل الأذان كاملًا',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'notification',
                                  child: Text('إشعار نصي فقط',
                                      style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (v) =>
                                v != null ? _setAdhanMode(key, v) : null,
                          ),
                          const Spacer(),
                          const Text('تذكير قبل:',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _reminderMinutes[key],
                            dropdownColor: const Color(0xFF222B45),
                            items: const [
                              DropdownMenuItem(
                                  value: 0,
                                  child: Text('لا يوجد',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 1,
                                  child: Text('1 دقيقة',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 5,
                                  child: Text('5 دقائق',
                                      style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (v) =>
                                v != null ? _setReminderMinutes(key, v) : null,
                          ),
                        ],
                      ),
                    ),
                    if (i < _prayerList.length - 1)
                      Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 1,
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Test & Stop buttons ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testAdhan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text('test_adhan_sound'.tr(),
                      style: GoogleFonts.cairo(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AdhanNativeService.stopAdhan();
                    _snack('تم إيقاف الأذان');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('إيقاف الأذان',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Info ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.blueAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'adhan_auto_play_info'.tr(),
                    style:
                        GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }

  void _showSoundDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('select_adhan_sound'.tr(),
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
            ..._sounds.entries.map((e) => RadioListTile<String>(
                  value: e.key,
                  groupValue: _selectedSound,
                  title: Text(e.value.tr(),
                      style: GoogleFonts.cairo(color: Colors.white70)),
                  activeColor: const Color(0xFF43A047),
                  onChanged: (v) {
                    if (v != null) {
                      _changeSound(v);
                      Navigator.pop(context);
                    }
                  },
                )),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(),
                  style: GoogleFonts.cairo(color: Colors.white38)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
