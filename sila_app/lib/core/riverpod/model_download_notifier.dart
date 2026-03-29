import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sila_app/core/services/model_download_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/utils/storage_utils.dart';
import 'package:easy_localization/easy_localization.dart';

part 'model_download_notifier.g.dart';

enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
  notEnoughSpace,
}

class ModelDownloadState {
  final ModelDownloadStatus status;
  final double progress;
  final String? errorMessage;

  ModelDownloadState({
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
  });

  ModelDownloadState copyWith({
    ModelDownloadStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return ModelDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class ModelDownloadNotifier extends _$ModelDownloadNotifier {
  late final ModelDownloadService _downloadService;
  late final String _modelPath;

  @override
  FutureOr<ModelDownloadState> build() async {
    ref.keepAlive();
    _downloadService = ModelDownloadService();
    final directory = await StorageUtils.getNoBackupDirectory();
    final modelDir = Directory('${directory.path}/models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10');
    final exists = await modelDir.exists() && await File('${modelDir.path}/encoder.onnx').exists();
    
    return ModelDownloadState(
      status: exists ? ModelDownloadStatus.downloaded : ModelDownloadStatus.notDownloaded,
    );
  }

  void _updateState(ModelDownloadStatus status, {double? progress, String? errorMessage}) {
    state = AsyncData(state.value!.copyWith(
      status: status,
      progress: progress ?? state.value!.progress,
      errorMessage: errorMessage,
    ));
  }

  Future<void> startDownload(String url) async {
    if (state.value?.status == ModelDownloadStatus.downloading) return;

    // 1. Check Space (45MB required + buffer)
    const requiredBytes = 45 * 1024 * 1024;
    final hasSpace = await StorageUtils.hasEnoughSpace(requiredBytes);
    if (!hasSpace) {
      _updateState(ModelDownloadStatus.notEnoughSpace);
      return;
    }

    _updateState(ModelDownloadStatus.downloading, progress: 0.0);

    try {
      final directory = await StorageUtils.getNoBackupDirectory();
      final tempZipPath = '${directory.path}/models/arabic_stt_temp.tar.bz2';
      final modelsDir = '${directory.path}/models';

      await _downloadService.downloadFile(
        url: url,
        savePath: tempZipPath,
        onProgress: (progress) {
          _updateState(ModelDownloadStatus.downloading, progress: progress);
          NotificationService().showModelDownloadProgress(
            locale: Intl.getCurrentLocale().split('_').first,
            percent: (progress * 100).toInt(),
          );
        },
      );
      
      // 3. Decompress the model
      _updateState(ModelDownloadStatus.downloading, progress: 0.99, errorMessage: "Extracting...");
      await _downloadService.decompressModel(tempZipPath, modelsDir);
      
      // Delete temp file
      try {
        await File(tempZipPath).delete();
      } catch (_) {}

      _updateState(ModelDownloadStatus.downloaded);
      NotificationService().hideModelDownloadNotification();
    } catch (e) {
      _updateState(ModelDownloadStatus.error, errorMessage: e.toString());
      NotificationService().hideModelDownloadNotification();
    }
  }

  void cancelDownload() {
    _downloadService.cancelDownload();
    NotificationService().hideModelDownloadNotification();
    state = AsyncData(state.value!.copyWith(status: ModelDownloadStatus.notDownloaded));
  }

  Future<void> deleteModel() async {
    final directory = await StorageUtils.getNoBackupDirectory();
    final modelFolder = Directory('${directory.path}/models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10');
    if (await modelFolder.exists()) {
      await modelFolder.delete(recursive: true);
    }
    state = AsyncData(state.value!.copyWith(status: ModelDownloadStatus.notDownloaded));
  }
}
