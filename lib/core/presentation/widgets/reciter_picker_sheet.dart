import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/services/reciter_service.dart';

Future<void> showReciterPickerSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const ReciterPickerSheet(),
  );
}

class ReciterPickerSheet extends ConsumerWidget {
  const ReciterPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentReciter = ref.watch(reciterControllerProvider).valueOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر الشيخ',
                    style: AppFonts.getFont(
                      'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ موصى به للحفظ',
                      style: AppFonts.getFont(
                        'Cairo',
                        fontSize: 10,
                        color: const Color(0xFF064E3B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...ReciterService.availableReciters.map(
              (reciter) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: reciter.isRecommendedForHifz
                        ? const Color(0xFF064E3B).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: reciter.isRecommendedForHifz
                        ? const Color(0xFF064E3B)
                        : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  reciter.nameArabic,
                  style: AppFonts.getFont(
                    'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    _StyleBadge(style: reciter.style),
                    const SizedBox(width: 6),
                    if (reciter.isRecommendedForHifz) const _RecommendedBadge(),
                  ],
                ),
                trailing: currentReciter?.id == reciter.id
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF064E3B), size: 22)
                    : Icon(Icons.radio_button_unchecked,
                        color: Colors.grey[300], size: 22),
                onTap: () async {
                  await ref
                      .read(reciterControllerProvider.notifier)
                      .selectReciter(reciter.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StyleBadge extends StatelessWidget {
  const _StyleBadge({required this.style});
  final String style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        style,
        style:
            AppFonts.getFont('Cairo', fontSize: 10, color: Colors.grey[700]),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'مناسب للحفظ',
        style: AppFonts.getFont('Cairo',
            fontSize: 10, color: const Color(0xFF064E3B)),
      ),
    );
  }
}
