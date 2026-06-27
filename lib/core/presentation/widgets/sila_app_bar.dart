import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';

class SilaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SilaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : const Color(0xFF064E3B),
      elevation: 0,
      centerTitle: false,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: AppFonts.getFont(
            'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
