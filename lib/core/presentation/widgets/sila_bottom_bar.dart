import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';

import '../main_layout.dart'; // To access bottomNavIndexProvider

class _NavItemData {
  _NavItemData({
    required this.icon,
    required this.label,
    required this.index,
    this.featured = false,
  });
  final IconData icon;
  final String label;
  final int index;
  final bool featured;
}

class SilaBottomBar extends ConsumerWidget {
  const SilaBottomBar({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    // Define nav items
    final navItems = [
      _NavItemData(icon: Icons.home_rounded, label: 'nav_home'.tr(), index: 0),
      _NavItemData(
          icon: Icons.menu_book_rounded, label: 'nav_quran'.tr(), index: 1),
      _NavItemData(
          icon: Icons.auto_stories,
          label: 'nav_hifz'.tr(),
          index: 2,
          featured: true),
      _NavItemData(
          icon: Icons.access_time_rounded, label: 'nav_prayers'.tr(), index: 3),
      _NavItemData(
          icon: Icons.favorite_rounded, label: 'nav_azkar'.tr(), index: 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              return Expanded(
                child: _NavItem(
                  icon: item.icon,
                  label: item.label,
                  index: item.index,
                  featured: item.featured,
                  currentIndex: currentIndex,
                  ref: ref,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.featured = false,
    required this.currentIndex,
    required this.ref,
  });
  final IconData icon;
  final String label;
  final int index;
  final bool featured;
  final int currentIndex;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    final txtS = isDark ? Colors.white60 : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected && !featured
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (featured)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0a6b52)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              )
            else
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : txtS,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.getFont(
                'Cairo',
                fontSize: 10,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? primaryColor : txtS,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
