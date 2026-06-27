import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/core/services/reciter_service.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';

Future<void> showAudioStorageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AudioStorageSheet(),
  );
}

class _AudioStorageSheet extends ConsumerStatefulWidget {
  const _AudioStorageSheet();

  @override
  ConsumerState<_AudioStorageSheet> createState() => _AudioStorageSheetState();
}

class _AudioStorageSheetState extends ConsumerState<_AudioStorageSheet> {
  AudioCacheStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final stats =
        await ref.read(audioControllerProvider.notifier).getCacheStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const SizedBox(
                height: 220, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إدارة مساحة الصوت',
                    style: AppFonts.cairo(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الإجمالي: ${_fmt(_stats!.totalBytes)} - ملفات: ${_stats!.totalFiles}',
                    style: AppFonts.cairo(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView(
                      children: ReciterService.availableReciters.map((reciter) {
                        final bytes =
                            _stats!.bytesByFolder[reciter.folderName] ?? 0;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            reciter.nameArabic,
                            style: AppFonts.cairo(
                                color: Colors.white, fontSize: 13),
                          ),
                          subtitle: Text(
                            _fmt(bytes),
                            style: AppFonts.cairo(
                                color: Colors.white54, fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: bytes == 0
                                ? null
                                : () async {
                                    await ref
                                        .read(audioControllerProvider.notifier)
                                        .clearReciterCacheById(reciter.id);
                                    await _load();
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(audioControllerProvider.notifier)
                            .clearAllCache();
                        await _load();
                      },
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.redAccent),
                      label: Text(
                        'حذف كل الكاش',
                        style: AppFonts.cairo(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
