import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sila_app/core/presentation/widgets/audio_storage_sheet.dart';
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/presentation/widgets/update_dialog.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/core/services/remote_config_service.dart';
import 'package:sila_app/core/services/update_service.dart';
import 'package:sila_app/features/prayers/presentation/pages/adhan_settings_page.dart';
import 'package:sila_app/features/prayers/presentation/pages/qiblah_page.dart';
import 'package:sila_app/features/prayers/presentation/riverpod/prayer_controller.dart';
import 'package:sila_app/features/prayers/presentation/widgets/location_settings_dialog.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_onboarding_page.dart';

// ── All supported calculation methods ────────────────────────────────────────
const _methods = {
  'turkey': 'calculation_methods.turkey',
  'muslim_world_league': 'calculation_methods.muslim_world_league',
  'egyptian': 'calculation_methods.egyptian',
  'umm_al_qura': 'calculation_methods.umm_al_qura',
  'morocco': 'calculation_methods.morocco',
  'indonesia': 'calculation_methods.indonesia',
  'karachi': 'calculation_methods.karachi',
  'north_america': 'calculation_methods.north_america',
  'dubai': 'calculation_methods.dubai',
  'qatar': 'calculation_methods.qatar',
  'kuwait': 'calculation_methods.kuwait',
  'singapore': 'calculation_methods.singapore',
};

class PrayerSettingsPage extends ConsumerStatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  ConsumerState<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends ConsumerState<PrayerSettingsPage> {
  final _prefs = PrefsService();
  String _method = 'turkey';
  bool _isAuto = true;
  String _cityName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final method = await _prefs.getCalculationMethod();
    final isAuto = await _prefs.isAutoLocation();
    final stored = await _prefs.getStoredLocation();
    setState(() {
      _method = method;
      _isAuto = isAuto;
      _cityName = stored?['city'] as String? ?? '';
    });
  }

  Future<void> _pickMethod() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _MethodDialog(current: _method),
    );
    if (selected != null && selected != _method) {
      await _prefs.setCalculationMethod(selected);
      setState(() => _method = selected);
      ref.invalidate(prayerTimesControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('calculation_updated'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentReciter = ref.watch(reciterControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'prayer_settings'.tr(),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(label: 'location'.tr(), children: [
            _Tile(
              icon: Icons.location_on_rounded,
              title: 'auto_detect_location'.tr(),
              subtitle: _isAuto
                  ? 'auto_detect_enabled'.tr()
                  : 'auto_detect_disabled'.tr(),
              trailing: Switch(
                value: _isAuto,
                activeColor: const Color(0xFF43A047),
                onChanged: (v) async {
                  await _prefs.setAutoLocation(v);
                  setState(() => _isAuto = v);
                  ref.invalidate(prayerTimesControllerProvider);
                },
              ),
            ),
            if (!_isAuto)
              _Tile(
                icon: Icons.edit_location_alt_rounded,
                title: 'change_city'.tr(),
                subtitle: _cityName.isNotEmpty ? _cityName : 'select_city'.tr(),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const LocationSettingsDialog(),
                  );
                  await _load();
                  ref.invalidate(prayerTimesControllerProvider);
                },
              ),
          ]),
          const SizedBox(height: 16),
          _Section(label: 'calculation_method_label'.tr(), children: [
            _Tile(
              icon: Icons.calculate_rounded,
              title: 'calculation_method_name'.tr(),
              subtitle: _methods[_method]?.tr() ?? _method,
              onTap: _pickMethod,
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
            ),
            if (_isAuto)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'info_calculation_method'.tr(),
                  style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          _Section(label: 'adhan_notifications_label'.tr(), children: [
            _Tile(
              icon: Icons.notifications_active_rounded,
              title: 'adhan_settings'.tr(),
              subtitle: 'adhan_prayer_settings'.tr(),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdhanSettingsPage())),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(label: 'qiblah'.tr(), children: [
            _Tile(
              icon: Icons.explore_rounded,
              title: 'qiblah_direction'.tr(),
              subtitle: 'qibla_interactive_compass'.tr(),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QiblahPage())),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(label: 'tasmi_label'.tr(), children: [
            _Tile(
              icon: Icons.tune_rounded,
              title: 'tasmi_settings'.tr(),
              subtitle: 'tasmi_customize_preferences'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TasmiOnboardingPage(
                    onDone: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            _Tile(
              icon: Icons.mic_rounded,
              title: 'selected_reciter'.tr(),
              subtitle:
                  currentReciter?.nameArabic ?? 'default_reciter_name'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
              onTap: () => showReciterPickerSheet(context),
            ),
            _Tile(
              icon: Icons.storage_rounded,
              title: 'manage_audio_storage'.tr(),
              subtitle: 'view_delete_audio_cache'.tr(),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
              onTap: () => showAudioStorageSheet(context),
            ),
          ]),
          _Section(label: 'update_section_title'.tr(), children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                return _Tile(
                  icon: Icons.info_outline_rounded,
                  title: 'update_version'.tr(args: [version]),
                  subtitle: 'update_check'.tr(),
                  trailing: const Icon(Icons.system_update_rounded,
                      color: Colors.white38),
                  onTap: () async {
                    final remoteConfig = RemoteConfigService();
                    await remoteConfig.initialize();
                    final packageInfo = await PackageInfo.fromPlatform();
                    final currentVersion =
                        int.tryParse(packageInfo.buildNumber) ?? 1;
                    final result =
                        await remoteConfig.checkForUpdate(currentVersion);
                    if (!context.mounted) return;
                    if (result.hasUpdate) {
                      final updateService = ref.read(updateServiceProvider);
                      final analytics = ref.read(analyticsServiceProvider);
                      showDialog<void>(
                        context: context,
                        barrierDismissible: !result.isForced,
                        builder: (_) => UpdateDialog(
                          updateResult: result,
                          updateService: updateService,
                          analyticsService: analytics,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('update_up_to_date'.tr(),
                              style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: const Color(0xFF43A047),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: const Color(0xFF43A047),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF43A047).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF66BB6A), size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── Method picker dialog ───────────────────────────────────────────────────

class _MethodDialog extends StatelessWidget {
  const _MethodDialog({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'select_calculation_method'.tr(),
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 380,
            child: ListView(
              children: _methods.entries.map((e) {
                final selected = e.key == current;
                return ListTile(
                  onTap: () => Navigator.pop(context, e.key),
                  title: Text(e.value.tr(),
                      style: GoogleFonts.cairo(
                          color: selected
                              ? const Color(0xFF66BB6A)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400)),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF43A047))
                      : null,
                );
              }).toList(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(),
                style: GoogleFonts.cairo(color: Colors.white54)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
