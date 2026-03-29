import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/core/presentation/widgets/dynamic_download_button.dart';
import 'package:sila_app/core/theme/app_theme.dart';

class DialogUtils {
  static Future<void> showSmartEnginePrompt(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text('🧠', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              'offline_stt.prompt_title'.tr(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'offline_stt.prompt_message'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const DynamicDownloadButton(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
