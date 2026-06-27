import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/vefa/presentation/riverpod/vefa_providers.dart';
import 'package:sila_app/features/vefa/presentation/widgets/add_vefa_contact_sheet.dart';
import 'package:sila_app/features/vefa/presentation/widgets/vefa_card.dart';

class VefaPage extends ConsumerWidget {
  const VefaPage({
    super.key,
    this.isSelectionMode = false,
  });
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isarAsync = ref.watch(isarInstanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'vefa_list'.tr(),
          style: AppFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'vefa_list_desc'.tr(),
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            child: isarAsync.when(
              data: (_) {
                final vefaListState = ref.watch(vefaListControllerProvider);
                return vefaListState.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurfaceColor
                                    : AppTheme.surfaceColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.diversity_1,
                                size: 64,
                                color: isDark
                                    ? AppTheme.accentColor
                                    : AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'vefa_list_empty'.tr(),
                              style: AppFonts.cairo(
                                color:
                                    isDark ? Colors.white70 : Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isSelectionMode) ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (context) =>
                                        const AddVefaContactSheet(),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: Text('add_new'.tr(),
                                    style: AppFonts.cairo(
                                        fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final person = list[index];
                        return VefaCard(
                          person: person,
                          isSelectionMode: true,
                          onTap: () {
                            if (isSelectionMode) {
                              ref
                                  .read(vefaListControllerProvider.notifier)
                                  .giftThawab(person.id!);
                            }
                            _showDuaBottomSheet(context, ref, person);
                          },
                          onDelete: () {
                            ref
                                .read(vefaListControllerProvider.notifier)
                                .deletePerson(person.id!);
                          },
                        );
                      },
                    );
                  },
                  error: (err, stack) => Center(
                      child: Text('Error: $err', style: AppFonts.cairo())),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                );
              },
              error: (err, stack) => Center(
                  child: Text('Database Error: $err', style: AppFonts.cairo())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: isDark
                ? AppTheme.darkBackgroundColor
                : AppTheme.backgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => const AddVefaContactSheet(),
          );
        },
        label: Text('add_new'.tr(),
            style: AppFonts.cairo(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showDuaBottomSheet(BuildContext context, WidgetRef ref, person) {
    final duaaText = 'duaa_safe_template'.tr(args: [person.name]);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'duaa_suggested_title'.tr(),
              style: AppFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'duaa_suggested_desc'.tr(),
              textAlign: TextAlign.center,
              style: AppFonts.cairo(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                duaaText,
                textAlign: TextAlign.center,
                style: AppFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.8,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: duaaText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.surfaceColor,
                          content: Text(
                            'تم نسخ الدعاء',
                            style: AppFonts.cairo(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AppTheme.accentColor),
                    label: Text(
                      'copy_duaa'.tr(),
                      style: AppFonts.cairo(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'حسناً',
                      style: AppFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
