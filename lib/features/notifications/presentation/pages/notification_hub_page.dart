import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/azkar_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/hifz_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/salah_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/tasbih_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/wird_notification_settings.dart';

class NotificationHubPage extends StatelessWidget {
  const NotificationHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF243041) : const Color(0xFFE2E8F0);
    final title = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF065F46),
        foregroundColor: Colors.white,
        title: Text('smart_notifications_title'.tr(),
            style: AppFonts.getFont('Cairo', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubTile(
            title: 'salah_settings_title'.tr(),
            subtitle: 'salah_settings_subtitle'.tr(),
            icon: Icons.mosque_rounded,
            card: card,
            border: border,
            titleColor: title,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const SalahNotificationSettings()),
            ),
          ),
          _HubTile(
            title: 'wird_settings_title'.tr(),
            subtitle: 'wird_settings_subtitle'.tr(),
            icon: Icons.menu_book_rounded,
            card: card,
            border: border,
            titleColor: title,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WirdNotificationSettings()),
            ),
          ),
          _HubTile(
            title: 'azkar_settings_title'.tr(),
            subtitle: 'azkar_settings_subtitle'.tr(),
            icon: Icons.wb_sunny_rounded,
            card: card,
            border: border,
            titleColor: title,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AzkarNotificationSettings()),
            ),
          ),
          _HubTile(
            title: 'hifz_settings_title'.tr(),
            subtitle: 'hifz_settings_subtitle'.tr(),
            icon: Icons.school_rounded,
            card: card,
            border: border,
            titleColor: title,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const HifzNotificationSettings()),
            ),
          ),
          _HubTile(
            title: 'tasbih_settings_title'.tr(),
            subtitle: 'tasbih_settings_subtitle'.tr(),
            icon: Icons.auto_awesome_rounded,
            card: card,
            border: border,
            titleColor: title,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const TasbihNotificationSettings()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.card,
    required this.border,
    required this.titleColor,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color card;
  final Color border;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF065F46), size: 18),
        ),
        title: Text(
          title,
          style: AppFonts.getFont('Cairo',
              fontWeight: FontWeight.w700, color: titleColor),
        ),
        subtitle: Text(
          subtitle,
          style: AppFonts.getFont('Cairo', fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
