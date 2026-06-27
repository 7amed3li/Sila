import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/features/sunan_mahjoura/data/sunan_data.dart';

class DailyContentCard extends StatelessWidget {
  const DailyContentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sunnah = getTodaySunnah();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final txtP = isDark ? Colors.white : const Color(0xFF0F172A);
    final txtS = isDark ? Colors.white60 : const Color(0xFF64748B);
    const primaryColor = Color(0xFF064E3B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'sunan_mahjoura'.tr(),
                style: GoogleFonts.getFont(
                  'Cairo',
                  color: const Color(0xFFD97706),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sunnah.text,
            style: GoogleFonts.getFont(
              'Cairo',
              color: txtP,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),

          // Source & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  "${'source'.tr()}: ${sunnah.source}",
                  style: GoogleFonts.getFont(
                    'Cairo',
                    color: txtS,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (sunnah.explanation.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: surface,
                        title: Text('explanation'.tr(),
                            style: GoogleFonts.getFont('Cairo', color: txtP)),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sunnah.text,
                                  style: GoogleFonts.getFont('Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: txtP)),
                              const SizedBox(height: 10),
                              Text(sunnah.explanation,
                                  style: GoogleFonts.getFont('Cairo',
                                      color: txtP, height: 1.6)),
                              const SizedBox(height: 20),
                              Text("${'source'.tr()}: ${sunnah.source}",
                                  style: GoogleFonts.getFont('Cairo',
                                      color: txtS, fontSize: 12)),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('close'.tr(),
                                style: GoogleFonts.getFont('Cairo',
                                    color: primaryColor)),
                          )
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                        Text('explanation'.tr(),
                            style: GoogleFonts.getFont('Cairo',
                                fontSize: 11,
                                color: primaryColor,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}
