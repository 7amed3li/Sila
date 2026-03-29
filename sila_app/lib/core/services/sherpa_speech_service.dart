import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:audio_streamer/audio_streamer.dart';
import 'package:sila_app/core/services/model_download_service.dart';
import 'package:sila_app/core/utils/storage_utils.dart';

class SherpaSpeechService {
  factory SherpaSpeechService() => _instance;
  SherpaSpeechService._internal();
  static final SherpaSpeechService _instance = SherpaSpeechService._internal();

  sherpa.OnlineRecognizer? _recognizer;
  StreamSubscription<List<double>>? _audioSubscription;
  final _resultController = StreamController<String>.broadcast();
  
  Stream<String> get resultStream => _resultController.stream;
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> isModelAvailable() async {
    final docDir = await StorageUtils.getNoBackupDirectory();
    final modelFolder = Directory('${docDir.path}/models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10');
    return await modelFolder.exists() && await File('${modelFolder.path}/encoder.onnx').exists();
  }

  Future<void> init() async {
    if (_recognizer != null) return;
    
    final sherpaDir = await StorageUtils.getNoBackupDirectory();
    final modelFolder = Directory('${sherpaDir.path}/models/sherpa-onnx-streaming-zipformer-ar_en_id_ja_ru_th_vi_zh-2025-02-10');
    
    debugPrint('ℹ️ SherpaSpeechService: Initializing with path: ${modelFolder.path}');
    if (!await modelFolder.exists()) {
      debugPrint('❌ SherpaSpeechService: Model folder MISSING');
      throw Exception('Model not found. Please download the smart engine.');
    }

    final encoderFile = File('${modelFolder.path}/encoder.onnx');
    if (!await encoderFile.exists()) {
      debugPrint('❌ SherpaSpeechService: encoder.onnx MISSING');
      throw Exception('Model files are incomplete.');
    }

    final config = sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: '${modelFolder.path}/encoder.onnx',
          decoder: '${modelFolder.path}/decoder.onnx',
          joiner: '${modelFolder.path}/joiner.onnx',
        ),
        tokens: '${modelFolder.path}/tokens.txt',
        numThreads: 4,
        debug: kDebugMode,
      ),
      enableEndpoint: true,
      rule1MinTrailingSilence: 2.4,
      rule3MinUtteranceLength: 0.0,
    );

    _recognizer = sherpa.OnlineRecognizer(config);
    debugPrint('✅ SherpaSpeechService: Recognizer initialized');
  }

  Future<void> startListening() async {
    if (_isListening) return;
    if (_recognizer == null) await init();

    final stream = _recognizer!.createStream();
    _isListening = true;
    debugPrint('🎤 SherpaSpeechService: Stream created, starting AudioStreamer');

    _audioSubscription = AudioStreamer().audioStream.listen((List<double> buffer) {
      if (!_isListening) return;
      
      // sherpa-onnx models usually expect 16000Hz. 
      // acceptWaveform handles different sample rates if specified.
      stream.acceptWaveform(samples: Float32List.fromList(buffer), sampleRate: 16000);
      
      while (_recognizer!.isReady(stream)) {
        _recognizer!.decode(stream);
      }
      
      final result = _recognizer!.getResult(stream);
      if (result.text.isNotEmpty) {
        _resultController.add(result.text);
      }
    });

    debugPrint('🎤 SherpaSpeechService: Listening started');
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    debugPrint('🛑 SherpaSpeechService: Listening stopped');
  }

  void dispose() {
    stopListening();
    _recognizer?.free();
    _recognizer = null;
  }
}
