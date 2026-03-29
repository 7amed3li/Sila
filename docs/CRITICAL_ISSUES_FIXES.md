# 🔴 حل المشاكل الحرجة الـ 4 في Sila App

## التاريخ: 29 مارس 2026
## الحالة: خطة الحل الشاملة

---

## 📊 ملخص المشاكل

| الأولوية | المشكلة | السبب | التأثير |
|---------|--------|------|--------|
| 🔴 1 | Connection aborted في just_audio | تدمير ExoPlayer قبل انتهاء load() | Crash متكرر |
| 🔴 2 | STT لا يدعم العربية | موديل محلي لم يُربط مع speech_to_text | الميزة معطلة |
| 🟠 3 | Use after dispose | StateNotifier بدون فحص mounted | Crash عشوائي |
| 🟡 4 | ANR عند فك الضغط | 258MB على main thread | تجربة سيئة |

---

## 🔴 المشكلة #1: Connection aborted في just_audio

### السبب الجذري:
```
InteractiveShadowController.playAudio()
  ↓
AudioController.playAudio(url) ← يستدعي load()
  ↓
ExoPlayer يُدمَّر قبل انتهاء load() ← CRASH!
  ↓
HifzAudioSessionManager بدون guard
```

### الحل - المرحلة 1: إضافة Guards في AudioController

**ملف**: `sila_app/lib/features/quran/presentation/riverpod/audio_controller.dart`

```dart
Future<void> playAudio(
  String url, {
  String? surahName,
  int? surahNumber,
  int? ayahNumber,
}) async {
  // ✅ الفحص الأول: تحقق من حالة الـ player
  if (_singleton.isDisposed || _singleton.player == null) {
    debugPrint('⚠️ Player غير متاح - تم تجاهل playAudio');
    return;
  }

  if (_singleton.isLoading) {
    debugPrint('⚠️ تحميل جاري - تم تجاهل playAudio الثاني');
    return;
  }

  _singleton.isLoading = true;

  try {
    // ✅ الفحص الثاني: تحقق قبل كل استدعاء
    if (_singleton.isDisposed) {
      debugPrint('❌ Player تم تدميره');
      return;
    }

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);

    await _singleton.player.stop();

    // ✅ الفحص الثالث: قبل العملية الطويلة (setAudioSource)
    if (_singleton.isDisposed) {
      debugPrint('❌ Player تم تدميره قبل load');
      return;
    }

    debugPrint('🎵 تحميل: $url');
    await _singleton.player.setAudioSource(
      AudioSource.uri(Uri.parse(url)),
      preload: false,
    );

    // ✅ الفحص الرابع: قبل play
    if (_singleton.isDisposed) {
      debugPrint('❌ Player تم تدميره قبل play');
      return;
    }

    await _singleton.player.play();
    
    if (surahNumber != null && ayahNumber != null) {
      state = state.copyWith(
        currentPlayingSurah: surahNumber,
        playing: true,
      );
    }

  } on PlayerException catch (e) {
    // ✅ معالجة خاصة لـ Connection aborted
    if (e.message?.contains('Connection aborted') ?? false) {
      debugPrint('⚠️ Connection aborted - تجاهل (player ربما تم تدميره)');
      return; // ابتلع الخطأ بهدوء
    }
    
    debugPrint('❌ خطأ في التشغيل: ${e.message}');
    rethrow;
    
  } catch (e) {
    debugPrint('❌ خطأ غير متوقع: $e');
    rethrow;
    
  } finally {
    _singleton.isLoading = false;
  }
}
```

### الحل - المرحلة 2: إضافة Guard في HifzAudioSessionManager

**ملف**: `sila_app/lib/features/hifz/services/hifz_audio_session_manager.dart`

```dart
class HifzAudioSessionManager {
  // ✅ أضف هذا الـ flag
  bool _isCancelled = false;

  /// استدعاء هذا عند إغلاق الجلسة
  Future<void> cancel() async {
    _isCancelled = true;
    await _audioSession?.setActive(false);
  }

  /// الطريقة الرئيسية - مع الحماية
  Future<void> playAudioThenWait(
    String url,
    int durationMs,
  ) async {
    // ✅ Guard 1: فحص الإلغاء
    if (_isCancelled) {
      debugPrint('⚠️ جلسة ملغاة - تم تجاهل playAudioThenWait');
      return;
    }

    try {
      // تشغيل الصوت
      await audioController.playAudio(url);

      // ✅ Guard 2: فحص قبل الانتظار
      if (_isCancelled) {
        await audioController.stopAudio();
        return;
      }

      // الانتظار
      await Future.delayed(Duration(milliseconds: durationMs));

      // ✅ Guard 3: فحص بعد الانتظار
      if (_isCancelled) {
        await audioController.stopAudio();
        return;
      }

      // متابعة إلى الـ ayah التالي
      await _playNextAyah();

    } catch (e) {
      if (e.toString().contains('Connection aborted')) {
        debugPrint('⚠️ Connection aborted في HifzAudioSessionManager - تجاهل');
        return;
      }
      rethrow;
    }
  }

  /// عند تغيير الآية
  Future<void> switchToAyah(int surahNumber, int ayahNumber) async {
    // ✅ Guard: تحقق من عدم الإلغاء
    if (_isCancelled) {
      debugPrint('⚠️ جلسة ملغاة');
      return;
    }

    await audioController.playAyah(surahNumber, ayahNumber);
  }
}
```

### الحل - المرحلة 3: تحديث InteractiveShadowController

**ملف**: `sila_app/lib/features/hifz/presentation/controllers/interactive_shadow_controller.dart`

```dart
/// عند إغلاق الـ page
Future<void> dispose() async {
  try {
    // ✅ إلغاء جميع الجلسات الجارية
    await _hifzAudioSessionManager?.cancel();
    await audioController.stopAudio();
    
    debugPrint('✅ تم إغلاق InteractiveShadowController بنجاح');
  } catch (e) {
    debugPrint('⚠️ خطأ عند الإغلاق: $e');
  }
}
```

---

## 🔴 المشكلة #2: STT لا يدعم العربية

### السبب الجذري:
```
تطبيق ينزل موديل: arabic_stt_temp.tar.bz2 (258MB)
  ↓
لكن speech_to_text package لا يستخدمه
  ↓
يحاول استخدام STT النظام (Android/iOS built-in)
  ↓
النظام لا يدعم العربية → الموديل المحلي مهدر!
```

### الحل - المرحلة 1: فحص اللغات المدعومة

**ملف**: `sila_app/lib/core/services/stt_service.dart`

```dart
class SttService {
  final SpeechToText _speech = SpeechToText();

  /// فحص إذا كانت اللغة مدعومة
  Future<bool> isArabicSupported() async {
    try {
      final locales = await _speech.locales();
      final arabicSupported = locales.any(
        (locale) => locale.localeId.startsWith('ar'),
      );
      
      debugPrint(
        arabicSupported 
          ? '✅ العربية مدعومة في STT' 
          : '❌ العربية غير مدعومة - سيتم استخدام موديل محلي'
      );
      
      return arabicSupported;
    } catch (e) {
      debugPrint('⚠️ خطأ عند الفحص: $e');
      return false;
    }
  }

  /// بدء الاستماع - مع الحماية
  Future<String?> listen() async {
    try {
      // ✅ فحص قبل البدء
      final supported = await isArabicSupported();
      
      if (!supported) {
        debugPrint('ℹ️ العربية غير مدعومة - الرجاء الإدخال اليدوي');
        return null; // أرجع null لإشارة عدم الدعم
      }

      final available = await _speech.initialize(
        onError: (error) => debugPrint('❌ خطأ STT: $error'),
        onStatus: (status) => debugPrint('📢 حالة STT: $status'),
      );

      if (!available) {
        debugPrint('❌ STT غير متاح');
        return null;
      }

      // استدعاء listen() مع الإشارة الصحيحة
      await _speech.listen(
        localeId: 'ar', // طلب العربية
        onResult: (result) {
          if (result.finalResult) {
            // تم النتيجة النهائية
            debugPrint('✅ النتيجة: ${result.recognizedWords}');
          }
        },
      );

      return null; // النتائج تأتي عبر callback
      
    } catch (e) {
      debugPrint('❌ خطأ عند الاستماع: $e');
      return null;
    }
  }

  /// إيقاف الاستماع
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
```

### الحل - المرحلة 2: استخدام الموديل المحلي (Whisper/Vosk)

**ملف**: `sila_app/lib/core/services/local_stt_service.dart` (ملف جديد)

```dart
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// خدمة STT محلية باستخدام Whisper or Vosk
class LocalSttService {
  // FFI binding للموديل المحلي
  late final ffi.DynamicLibrary _lib;
  late final _InitModel _initModel;
  late final _TranscribeAudio _transcribeAudio;

  Future<void> initialize() async {
    try {
      // ✅ تحميل المكتبة المحلية
      _lib = ffi.DynamicLibrary.open('libstt.so'); // أو .dylib على iOS
      
      _initModel = _lib.lookup<ffi.NativeFunction<InitModelNative>>('stt_init')
          .asFunction();
      _transcribeAudio = _lib
          .lookup<ffi.NativeFunction<TranscribeAudioNative>>('stt_transcribe')
          .asFunction();

      debugPrint('✅ تم تحميل موديل STT المحلي');
    } catch (e) {
      debugPrint('❌ فشل تحميل STT المحلي: $e');
      rethrow;
    }
  }

  /// نسخ الموديل من assets وفك ضغطه
  Future<String> _extractModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/stt_model');
      
      if (!await modelDir.exists()) {
        // ✅ فك الضغط في Isolate منفصل
        await compute(_decompressModelInBackground, modelDir.path);
      }
      
      return modelDir.path;
    } catch (e) {
      debugPrint('❌ خطأ في استخراج الموديل: $e');
      rethrow;
    }
  }
}
```

---

## 🟠 المشكلة #3: Use after dispose

### السبب الجذري:
```
load() بدون فحص mounted بعد await الطويل
  ↓
State تم تغييره بعد تدمير Controller
  ↓
Crash!
```

### الحل:

**ملف**: `sila_app/lib/features/ibadah/presentation/controllers/ibadah_tracker_controller.dart`

```dart
@riverpod
class IbadahTrackerController extends _$IbadahTrackerController {
  @override
  IbadahTrackerState build() {
    return const IbadahTrackerState();
  }

  /// تحميل البيانات - مع حماية mounted
  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true);

      // ✅ العملية الطويلة
      final data = await ref.read(ibadahRepositoryProvider).fetchData();

      // ✅ فحص mounted بعد كل await
      if (!mounted) {
        debugPrint('⚠️ Controller تم تدميره - تم تجاهل النتيجة');
        return;
      }

      state = state.copyWith(
        data: data,
        isLoading: false,
      );

    } catch (e) {
      // ✅ فحص mounted عند الخطأ أيضاً
      if (!mounted) {
        debugPrint('⚠️ Controller تم تدميره - تم تجاهل الخطأ');
        return;
      }

      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// أي عملية async أخرى
  Future<void> updateItem(int id) async {
    try {
      await ref.read(ibadahRepositoryProvider).update(id);

      // ✅ الفحص الإلزامي
      if (!mounted) return;

      state = state.copyWith(
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      
      state = state.copyWith(error: e.toString());
    }
  }

  /// تنظيف عند تدمير Controller
  @override
  Future<void> dispose() async {
    await super.dispose();
    debugPrint('✅ تم تنظيف IbadahTrackerController');
  }
}
```

---

## 🟡 المشكلة #4: ANR عند فك الضغط

### السبب الجذري:
```
فك ضغط 258MB على main thread
  ↓
UI مجمدة
  ↓
ANR (Application Not Responding) بعد 5 ثواني
```

### الحل - نقل العملية إلى Isolate:

**ملف**: `sila_app/lib/core/services/model_download_service.dart`

```dart
class ModelDownloadService {
  /// فك الضغط الصحيح - في Isolate منفصل
  Future<void> decompressModel(String filePath) async {
    try {
      debugPrint('📦 بدء فك الضغط في Isolate منفصل...');

      // ✅ استخدم compute() لنقل العملية الثقيلة
      final result = await compute(
        _decompressInBackground,
        filePath,
      );

      debugPrint('✅ تم فك الضغط بنجاح: $result');

    } catch (e) {
      debugPrint('❌ خطأ في فك الضغط: $e');
      rethrow;
    }
  }

  /// هذه الدالة تعمل في Isolate منفصل
  static Future<String> _decompressInBackground(String filePath) async {
    try {
      debugPrint('🔄 فك الضغط جاري في Isolate...');

      final file = File(filePath);
      
      if (!await file.exists()) {
        throw FileSystemException('الملف غير موجود: $filePath');
      }

      // ✅ فك الضغط بالكامل (لا يسبب ANR)
      final output = filePath.replaceAll('.tar.bz2', '');
      
      // استخدم BZip2 + Tar
      await _extractBZip2AndTar(file, output);

      debugPrint('✅ انتهى فك الضغط: $output');
      return output;

    } catch (e) {
      debugPrint('❌ خطأ في _decompressInBackground: $e');
      rethrow;
    }
  }

  /// استخراج BZip2 ثم Tar
  static Future<void> _extractBZip2AndTar(
    File bz2File,
    String outputPath,
  ) async {
    // استخدم مكتبة archive
    final bytes = await bz2File.readAsBytes();
    
    // فك BZip2
    final uncompressed = BZip2Decoder().decodeBytes(bytes);
    
    // فك Tar
    final tar = TarDecoder();
    tar.decodeBytes(uncompressed).forEach((file) {
      final output = File('$outputPath/${file.name}');
      output.createSync(recursive: true);
      output.writeAsBytesSync(file.content);
    });
  }
}
```

---

## ✅ ملخص سريع للحلول

| # | المشكلة | الحل السريع |
|---|--------|-----------|
| 1 | Connection aborted | أضف guards في playAudio() + معالجة الخطأ |
| 2 | STT العربية | فحص اللغات + fallback يدوي |
| 3 | Use after dispose | mounted check بعد كل await |
| 4 | ANR | استخدم compute() لفك الضغط |

---

## 📋 خطوات التطبيق

### اليوم 1:
1. [ ] تطبيق Guards في AudioController (أولوية عاجلة)
2. [ ] تطبيق mounted checks في IbadahTrackerController
3. [ ] نقل فك الضغط إلى compute()

### اليوم 2-3:
4. [ ] تطبيق فحص STT
5. [ ] إضافة UI fallback للإدخال اليدوي

### الاختبار:
- [ ] اختبر على جهاز Xiaomi (MIUI)
- [ ] راقب logcat لـ "Connection aborted"
- [ ] تأكد من عدم وجود ANR
- [ ] اختبر STT بالعربية

---

## 🎯 النتيجة المتوقعة

بعد تطبيق هذه الحلول:
- ✅ لا "Connection aborted" errors
- ✅ STT يعمل أو يعرض fallback
- ✅ لا crashes من use after dispose  
- ✅ لا ANR screens
- ✅ تجربة مستخدم سلسة على جميع الأجهزة
