import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sila_app/core/providers/audio_download_provider.dart';
import 'package:sila_app/core/riverpod/model_download_notifier.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/theme/app_theme.dart';

class DynamicDownloadButton extends ConsumerWidget {
  const DynamicDownloadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return downloadState.when(
      data: (state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildStateWidget(context, ref, state, isDark),
      ),
      loading: () => const _LoadingPlaceholder(),
      error: (err, stack) => _ErrorButton(message: err.toString(), isDark: isDark),
    );
  }

  Widget _buildStateWidget(BuildContext context, WidgetRef ref, ModelDownloadState state, bool isDark) {
    switch (state.status) {
      case ModelDownloadStatus.notDownloaded:
        return _IdleButton(isDark: isDark, onDownload: () => _startDownload(ref));
      case ModelDownloadStatus.downloading:
        return _DownloadingButton(progress: state.progress, message: state.errorMessage, isDark: isDark, onCancel: () => ref.read(modelDownloadNotifierProvider.notifier).cancelDownload());
      case ModelDownloadStatus.downloaded:
        final audioAvailable = ref.watch(audioAvailabilityProvider).value ?? false;
        return _SuccessButton(isDark: isDark, audioAvailable: audioAvailable);
      case ModelDownloadStatus.error:
        return _ErrorButton(message: state.errorMessage ?? "Error", isDark: isDark, onRetry: () => _startDownload(ref));
      case ModelDownloadStatus.notEnoughSpace:
        return _ErrorButton(message: 'offline_stt.not_enough_space'.tr(), isDark: isDark, onRetry: () => _startDownload(ref));
    }
  }

  void _startDownload(WidgetRef ref) {
    // Ensure permissions are granted before starting
    NotificationService().requestPermissions();
    
    // Official public release model (2025-02-10) - Supports Arabic + others
    const modelUrl = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10.tar.bz2';
    ref.read(modelDownloadNotifierProvider.notifier).startDownload(modelUrl);
  }
}

class _IdleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDownload;

  const _IdleButton({required this.isDark, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFFF8FAFC), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDownload,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'offline_stt.activate_button'.tr(),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '45MB · High Precision',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadingButton extends StatelessWidget {
  final double progress;
  final String? message;
  final bool isDark;
  final VoidCallback onCancel;

  const _DownloadingButton({required this.progress, this.message, required this.isDark, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'offline_stt.downloading'.tr(args: [percentage.toString()]),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(onPressed: onCancel, icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessButton extends StatelessWidget {
  final bool isDark;
  final bool audioAvailable;
  
  const _SuccessButton({required this.isDark, required this.audioAvailable});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                'offline_stt.ready'.tr(),
                style: GoogleFonts.cairo(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (!audioAvailable) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'offline_stt.missing_audio_reminder'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.amber[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorButton extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback? onRetry;

  const _ErrorButton({required this.message, required this.isDark, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('retry'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
