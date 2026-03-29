# Audio Playback Device Error Fix

## Problem Summary
App logs show:
- `E/LB ( 7852): fail to open file: No such file or directory`
- `E/la.app.sila_app( 7852): FrameInsert open fail: No such file or directory`
- Audio not playing on device (Xiaomi MIUI)

## Root Cause Analysis

### 1. Manual Path Construction Issues
Current code in `audio_controller.dart` line 116:
```dart
final fileName = '${surahNumber.toString().padLeft(3, '0')}${ayahNumber.toString().padLeft(3, '0')}.mp3';
// Produces: "001001.mp3" (no separator)
```

Problems:
- No path separator between surah and ayah
- Inconsistent with filename validation in download service
- Doesn't match `AudioPathHelper` format

### 2. AudioPathHelper Not Integrated
- `AudioPathHelper` exists but is never imported or used
- Creates path mismatch between download and playback
- Leads to file-not-found errors

### 3. MIUI-Specific Issues
- Xiaomi devices have strict file access requirements
- MIUI uses different permission model
- "FrameInsert open fail" is MIUI system attempting to index files

## Solution

### Step 1: Import AudioPathHelper
Add to imports in `audio_controller.dart`:
```dart
import 'package:sila_app/core/services/audio_path_helper.dart';
```

### Step 2: Update playAyah() Method
Replace manual path construction with AudioPathHelper:

**Before:**
```dart
Future<void> playAyah(int surahNumber, int ayahNumber) async {
  final reciter = ref.read(reciterControllerProvider).valueOrNull ??
      ReciterService.getById(ReciterService.defaultReciterId);
  final fileName =
      '${surahNumber.toString().padLeft(3, '0')}${ayahNumber.toString().padLeft(3, '0')}.mp3';
  final url = '${reciter.baseUrl}${reciter.folderName}/$fileName';
  
  await playAudio(url, surahName: ..., surahNumber: ..., ayahNumber: ...);
}
```

**After:**
```dart
Future<void> playAyah(int surahNumber, int ayahNumber) async {
  final reciter = ref.read(reciterControllerProvider).valueOrNull ??
      ReciterService.getById(ReciterService.defaultReciterId);
  
  // Try local cached file first
  final localFile = await AudioPathHelper.findAyahFile(
    reciter,
    surahNumber,
    ayahNumber,
  );
  
  if (localFile != null && await localFile.exists()) {
    // Play from cache
    final fileSize = await localFile.length();
    if (fileSize >= 10240) { // >= 10KB = valid
      debugPrint('🎵 Playing cached: ${localFile.path}');
      await playAudio(
        localFile.path,
        surahName: quran.getSurahNameArabic(surahNumber),
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      return;
    }
  }
  
  // Fallback to streaming
  final fileName = AudioPathHelper.getAyahFilePatterns(surahNumber, ayahNumber).first;
  final url = '${reciter.baseUrl}${reciter.folderName}/$fileName';
  
  await playAudio(
    url,
    surahName: quran.getSurahNameArabic(surahNumber),
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
  );
}
```

### Step 3: Update isSurahDownloaded() Method
Use AudioPathHelper for consistent path handling:

```dart
Future<bool> isSurahDownloaded(int surahNumber, [ReciterModel? targetReciter]) async {
  final reciter = targetReciter ?? 
      ref.read(reciterControllerProvider).valueOrNull ??
      ReciterService.getById(ReciterService.defaultReciterId);
  
  return AudioDownloadService.verifySurahDownloaded(reciter, surahNumber);
}
```

## MIUI-Specific Optimization

### Add File Permissions for MIUI
In `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Add after existing permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

### Disable MIUI Optimization (if needed)
In app's `MainActivity` (Kotlin):
```kotlin
// Inside onCreate or application init
if (Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)) {
    // Request ignore battery optimization
    val intent = Intent().apply {
        action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
        data = Uri.parse("package:" + packageName)
    }
    startActivity(intent)
}
```

## Testing Steps

1. **Download Surah 1** with Turkish reciter
   - Should create files in: `/Documents/audio_cache/{reciter_folder}/001_001.mp3`
   - Each file should be >= 10KB

2. **Play Ayah** - should use cache first
   - Check logcat: `🎵 Playing cached:` appears before playback

3. **Verify File Paths**
   - Debug logs should show correct underscore format (`001_001.mp3`)
   - Never show colon format (`001:001.mp3`)

4. **Test on MIUI Device**
   - No "fail to open file" errors in logcat
   - Audio plays smoothly
   - Volume up/down keys control audio volume

## Performance Impact
- Cache-first playback = instant play for downloaded files
- No streaming overhead for cached content
- Reduced battery usage on MIUI devices

## Backward Compatibility
AudioPathHelper supports all filename formats:
- New: `001_001.mp3` (underscore - preferred)
- Old: `001:001.mp3` (colon - supported)
- Old: `001001.mp3` (no separator - supported)

Files can be migrated gradually or left as-is.

