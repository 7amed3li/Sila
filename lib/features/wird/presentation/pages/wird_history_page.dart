import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sila_app/core/presentation/widgets/sila_app_bar.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

class WirdHistoryPage extends ConsumerWidget {
  const WirdHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wirdStateAsync = ref.watch(wirdControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Global Sila Colors
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    const primaryColor = Color(0xFF064E3B);
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const SilaAppBar(
        title: 'الأوراد السابقة',
      ),
      body: SafeArea(
        child: wirdStateAsync.when(
          data: (wirdState) {
            if (wirdState.history.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد أوراد سابقة مسجلة بعد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: subtitleColor,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: wirdState.history.length,
              itemBuilder: (context, index) {
                final historyItem = wirdState.history[index];
                final formattedDate =
                    DateFormat('yyyy/MM/dd').format(historyItem.date);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'من صفحة ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${historyItem.startPage} ',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'إلى ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${historyItem.endPage}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(
              child: Text('Error: $err',
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.redAccent))),
        ),
      ),
    );
  }
}
