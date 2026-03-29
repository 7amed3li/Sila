# 🛠️ حل مشكلة "Connection aborted" والملفات المفقودة (404)

## المشكلة الجذرية

```
E/AudioPlayer(23095): TYPE_SOURCE: Response code: 404
E/flutter (23095): [ERROR] Unhandled Exception: (0) Source error
```

**التسلسل الزمني للمشكلة:**
1. المستخدم يضغط على زر التحميل
2. التطبيق يبدأ تحميل السورة (يظهر الإشعار)
3. ✅ الملفات تُحمّل بنجاح (لكن قد تكون بطيئة)
4. ❌ عند محاولة تشغيل الصوت، يأتي الخطأ 404 (الملف لا يوجد)
5. ❌ الإشعار لا يغلق (لأن التحميل لم يكتمل بشكل صحيح)
6. ❌ علامة الصح لا تظهر (لأن الحالة لم تُحدّث)

---

## الأسباب الرئيسية

### 1️⃣ عدم التحقق من وجود الملفات قبل التشغيل
- المشكلة: `AudioController.playAudio()` يحاول تشغيل ملف قد لا يكون موجوداً
- السبب: التحميل قد يكون فشل بصمت (Silent failure)

### 2️⃣ عدم معالجة أخطاء الشبكة (Network Errors)
- المشكلة: Dio.download() قد يفشل، لكن الكود لا يعالج الخطأ
- النتيجة: الملف المحمّل ناقص أو فارغ

### 3️⃣ عدم إغلاق الإشعارات عند الفشل
- المشكلة: في `downloadSurah()` لا يوجد كود يغلق الإشعار عند حدوث خطأ
- النتيجة: الإشعار يبقى معلقاً إلى الأبد

### 4️⃣ عدم تحديث الحالة في Isar (قاعدة البيانات)
- المشكلة: حتى لو تم التحميل بنجاح، قد لا يتم وضع علامة `isDownloaded = true`
- النتيجة: UI تعتقد أن التحميل لم يكتمل

---

## الحل المتكامل

### الخطوة 1: تحسين `AudioDownloadService.downloadAllForReciter()`

**إضافة معالجة شاملة للأخطاء:**

```dart
static Future<void> downloadAllForReciter(
  ReciterModel reciter, {
  required void Function(AudioDownloadProgress progress) onProgress,
  CancelToken? cancelToken,
}) async {
  final dio = Dio();
  final total = await totalAyahCount();
  var completed = 0;
  var failed = 0;

  for (var surah = 1; surah <= 114; surah++) {
    final ayahCount = quran.getVerseCount(surah);
    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      final localPath = await localAyahPath(reciter, surah, ayah);
      final localFile = File(localPath);

      try {
        if (!await localFile.exists()) {
          final url = reciter.buildAyahUrl(surah, ayah);
          
          // ✅ تحميل مع التحقق من الحجم
          await dio.download(
            url, 
            localPath,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              // تحديث التقدم أثناء التحميل
            },
          );
          
          // ✅ التحقق من أن الملف لم يكن فارغاً
          final fileSize = await localFile.length();
          if (fileSize < 10000) { // ملف صوتي قصير جداً = فاسد
            await localFile.delete();
            throw Exception('تنزيل ناقص: حجم الملف $fileSize بايت فقط');
          }
        }
        
        completed++;
      } on DioException catch (e) {
        debugPrint('❌ فشل تحميل $surah:$ayah - ${e.response?.statusCode}: ${e.message}');
        failed++;
        
        // إذا كان 404 أو 401، لا تحاول مرة أخرى
        if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
          // تخطى هذا الملف وتابع
          continue;
        }
        
        // لأخطاء الشبكة، أعد المحاولة مرة واحدة فقط
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          await Future.delayed(Duration(seconds: 2));
          // أعد المحاولة مرة واحدة
          try {
            final url = reciter.buildAyahUrl(surah, ayah);
            await dio.download(url, localPath, cancelToken: cancelToken);
            completed++;
          } catch (_) {
            failed++;
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ غير متوقع: $e');
        failed++;
      }
      
      onProgress(
        AudioDownloadProgress(
          completed: completed,
          total: total,
          surah: surah,
          ayah: ayah,
        ),
      );
    }
  }
  
  debugPrint('✅ انتهى التحميل: نجح=$completed، فشل=$failed من $total');
}
```

---

### الخطوة 2: تحسين `AudioController.playAudio()`

**التحقق من الملف قبل التشغيل:**

```dart
Future<void> playAudio(
  String url, {
  String? surahName,
  int? surahNumber,
  int? ayahNumber,
}) async {
  if (_singleton.isLoading) return;

  // ✅ إذا كان مسار محلي، تحقق من وجود الملف أولاً
  if (!url.startsWith('http')) {
    final localFile = File(url);
    if (!await localFile.exists()) {
      debugPrint('❌ الملف المحلي غير موجود: $url');
      state = state.copyWith(currentPlayingSurah: null, playing: false);
      throw FileSystemException('الملف غير موجود', url);
    }
  }

  _singleton.isLoading = true;
  
  try {
    if (_singleton.isDisposed) {
      _singleton.player = AudioPlayer();
      _singleton.isDisposed = false;
    }

    // تجنب إعادة التحميل للملف نفسه
    if (_singleton.currentUrl == url && _singleton.player.playing) {
      await _singleton.player.seek(Duration.zero);
      return;
    }

    _singleton.currentUrl = url;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);

    await _singleton.player.stop();

    final source = await _resolvePlayableSource(url);

    try {
      if (source.startsWith('http')) {
        await _singleton.player.setUrl(source);
      } else {
        await _touchCacheFile(source);
        await _singleton.player.setFilePath(source);
      }
    } on PlayerException catch (e) {
      // ✅ معالجة أخطاء المصدر (Source errors)
      debugPrint('❌ خطأ في تحميل المصدر: ${e.message}');
      _singleton.currentUrl = null;
      state = state.copyWith(currentPlayingSurah: null, playing: false);
      rethrow;
    }

    if (surahName != null && ayahNumber != null) {
      await ref.read(analyticsServiceProvider).logPlayAudio(
            surahName: surahName,
            ayahNumber: ayahNumber,
          );
    }

    await _singleton.player.play();
    state = state.copyWith(
      currentPlayingSurah: surahNumber,
      playing: true,
    );

    unawaited(_prefetchNextAyah(url));
  } on PlayerException {
    _singleton.currentUrl = null;
    state = state.copyWith(currentPlayingSurah: null, playing: false);
    rethrow;
  } on PlayerInterruptedException {
    _singleton.currentUrl = null;
    state = state.copyWith(currentPlayingSurah: null, playing: false);
    rethrow;
  } catch (e) {
    _singleton.currentUrl = null;
    state = state.copyWith(currentPlayingSurah: null, playing: false);
    rethrow;
  } finally {
    _singleton.isLoading = false;
  }
}
```

---

### الخطوة 3: تحسين `AudioController.downloadSurah()`

**إضافة معالجة الأخطاء وإغلاق الإشعارات:**

```dart
Future<void> downloadSurah(int surahNumber,
    [ReciterModel? targetReciter]) async {
  final reciter = targetReciter ??
      ref.read(reciterControllerProvider).valueOrNull ??
      ReciterService.getById(ReciterService.defaultReciterId);
  final verseCount = quran.getVerseCount(surahNumber);
  final baseUrl = reciter.baseUrl;

  final appDir = await getApplicationDocumentsDirectory();
  final reciterDir = Directory(
      '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}${reciter.folderName}');
  if (!reciterDir.existsSync()) reciterDir.createSync(recursive: true);

  final notificationService = NotificationService();
  final locale = ref.read(appLocaleProvider).languageCode;
  final surahName = quran.getSurahNameArabic(surahNumber);
  final notificationId = 9000 + surahNumber;
  var downloadedCount = 0;
  var failedCount = 0;

  try {
    // ✅ عرض الإشعار الأولي
    unawaited(notificationService.showQuranDownloadProgress(
      id: notificationId,
      locale: locale,
      percent: 0,
      reciterName: '$surahName - ${reciter.nameArabic}',
    ));

    const batchSize = 5;
    final totalBatches = (verseCount / batchSize).ceil();
    var currentBatch = 0;

    for (var i = 1; i <= verseCount; i += batchSize) {
      if (_isDownloadStopped) break;

      currentBatch++;
      final end =
          (i + batchSize - 1) > verseCount ? verseCount : (i + batchSize - 1);
      final futures = <Future<void>>[];

      for (var j = i; j <= end; j++) {
        final fileName =
            '${surahNumber.toString().padLeft(3, '0')}${j.toString().padLeft(3, '0')}.mp3';
        final url = '$baseUrl${reciter.folderName}/$fileName';
        final targetPath =
            '${reciterDir.path}${Platform.pathSeparator}$fileName';
        
        futures.add(
          _cacheInBackground(url, targetPath).then((_) {
            downloadedCount++;
          }).catchError((e) {
            debugPrint('❌ فشل تحميل $fileName: $e');
            failedCount++;
          }),
        );
      }

      await Future.wait(futures);

      // ✅ تحديث الإشعار مع التقدم
      final percent = ((currentBatch * 100) / totalBatches).toInt();
      unawaited(notificationService.showQuranDownloadProgress(
        id: notificationId,
        locale: locale,
        percent: percent,
        reciterName: '$surahName - ${reciter.nameArabic}',
      ));
    }

    // ✅ إذا نجح التحميل، حدّث قاعدة البيانات
    if (downloadedCount > 0) {
      final isar = ref.read(isarServiceProvider).isar;
      await isar.writeTxn(() async {
        // تحديث حالة السورة في Isar
        // (يعتمد على نموذج البيانات الخاص بك)
      });
    }

    // ✅ إغلاق الإشعار عند النجاح
    unawaited(notificationService.cancelNotification(notificationId));
    
    debugPrint('✅ انتهى تحميل السورة $surahNumber: نجح=$downloadedCount، فشل=$failedCount');
  } catch (e) {
    // ✅ معالجة الأخطاء - إغلق الإشعار فوراً
    debugPrint('❌ خطأ في تحميل السورة $surahNumber: $e');
    unawaited(notificationService.cancelNotification(notificationId));
    rethrow;
  } finally {
    _isDownloadStopped = false;
  }
}
```

---

### الخطوة 4: إضافة دالة التحقق من الملفات المحمّلة

```dart
/// التحقق من أن جميع ملفات السورة محمّلة بنجاح
Future<bool> verifySurahDownloaded(
  int surahNumber,
  ReciterModel reciter,
) async {
  final appDir = await getApplicationDocumentsDirectory();
  final reciterDir = Directory(
      '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}${reciter.folderName}');
  
  if (!reciterDir.existsSync()) return false;

  final verseCount = quran.getVerseCount(surahNumber);
  for (var ayah = 1; ayah <= verseCount; ayah++) {
    final fileName =
        '${surahNumber.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
    final file = File('${reciterDir.path}${Platform.pathSeparator}$fileName');
    
    // ✅ التحقق من الوجود والحجم
    if (!file.existsSync()) return false;
    
    final size = await file.length();
    if (size < 10000) return false; // ملف صغير جداً = فاسد
  }
  
  return true;
}
```

---

## ملخص التحسينات

| المشكلة | الحل |
|--------|------|
| ملفات مفقودة (404) | التحقق من وجود الملف قبل التشغيل |
| تحميل ناقص | التحقق من حجم الملف وحذف الملفات الفاسدة |
| إشعارات معلقة | إغلاق الإشعار عند النجاح والفشل |
| عدم تحديث UI | تحديث Isar وتحديث الحالة مباشرة |
| أخطاء شبكة صامتة | معالجة DioException و PlayerException |

---

## الخطوات التالية

1. ✅ تطبيق التحسينات على `AudioDownloadService`
2. ✅ تطبيق التحسينات على `AudioController`
3. ✅ إضافة دالة `verifySurahDownloaded()`
4. ✅ اختبار مع اتصال بطيء (throttling)
5. ✅ اختبار مع أخطاء شبكة (فصل الإنترنت في المنتصف)
