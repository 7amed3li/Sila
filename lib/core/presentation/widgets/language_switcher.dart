import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_data_provider.dart';

class LanguageSwitcher extends ConsumerStatefulWidget {
  const LanguageSwitcher({super.key});

  // Color System from Design System
  static const Color primaryColor = Color(0xFF064E3B); // Deep Emerald
  static const Color accentColor = Color(0xFFD97706); // Burnished Gold
  static const Color successColor = Color(0xFF10B981); // Success Green
  static const Color backgroundColor = Color(0xFFFDFBF7); // Warm Ivory
  static const Color surfaceColor = Color(0xFFF9F5EC); // Soft Parchment
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Slate 800

  static const _languageNames = {
    'ar': 'العربية',
    'tr': 'Türkçe',
    'en': 'English',
    'fr': 'Français',
  };

  static const double spacing = 16; // 2cm = 16px (standard spacing)

  @override
  ConsumerState<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends ConsumerState<LanguageSwitcher> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<Locale>(
      onSelected: (locale) async {
        await context.setLocale(locale);
        ref.read(appLocaleProvider.notifier).state = locale;
      },
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark
          ? LanguageSwitcher.darkSurfaceColor
          : LanguageSwitcher.surfaceColor,
      offset: const Offset(0, 50),
      itemBuilder: (context) {
        return context.supportedLocales.map((locale) {
          final isSelected = context.locale == locale;
          final langName =
              LanguageSwitcher._languageNames[locale.languageCode] ??
                  locale.languageCode;

          return PopupMenuItem<Locale>(
            value: locale,
            padding: EdgeInsets.zero,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(
                horizontal: LanguageSwitcher.spacing,
                vertical: LanguageSwitcher.spacing / 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? LanguageSwitcher.primaryColor
                        : LanguageSwitcher.primaryColor.withValues(alpha: 0.05))
                    : Colors.transparent,
                border: isSelected
                    ? const Border(
                        left: BorderSide(
                          color: LanguageSwitcher.accentColor,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    langName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (isDark
                              ? LanguageSwitcher.successColor
                              : LanguageSwitcher.primaryColor)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: LanguageSwitcher.spacing / 2),
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: LanguageSwitcher.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                ],
              ),
            ),
          );
        }).toList();
      },
      // Custom button with design system colors
      child: Container(
        decoration: BoxDecoration(
          color: LanguageSwitcher.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: LanguageSwitcher.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: const Icon(
          Icons.language,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
