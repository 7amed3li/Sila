import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/vefa/domain/entities/vefa_person.dart';

class VefaCard extends StatelessWidget {
  const VefaCard({
    super.key,
    required this.person,
    this.onTap,
    required this.onDelete,
    this.isSelectionMode = false,
  });
  final VefaPerson person;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelectionMode
              ? AppTheme.accentColor
              : (isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05)),
          width: isSelectionMode ? 2 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelectionMode
                        ? AppTheme.accentColor.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style: AppFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelectionMode
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: AppFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                      if (person.relation != null)
                        Text(
                          person.relation!,
                          style: AppFonts.cairo(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Stats / Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isSelectionMode)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.grey, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (!isSelectionMode) const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite,
                              color: Colors.red[400], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${person.giftCount}',
                            style: AppFonts.cairo(
                              fontSize: 14,
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
