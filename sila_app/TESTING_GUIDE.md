# 🧪 Complete Testing Guide

## 🚀 Quick Start

### 1. تشغيل جميع الاختبارات

```bash
cd sila_app
flutter test
```

### 2. تشغيل اختبار محدد

```bash
# Unit Tests
flutter test test/features/quran/presentation/riverpod/audio_controller_test.dart -v

# Widget Tests
flutter test test/features/quran/presentation/widgets/audio_button_test.dart -v

# Integration Tests
flutter test test/integration_tests/audio_download_integration_test.dart -v

# Performance Tests
flutter test test/performance_tests/audio_performance_test.dart -v
```

### 3. تشغيل اختبار محدد بـ keyword

```bash
flutter test -k "AudioState" # يشغل جميع اختبارات تحتوي على AudioState
flutter test -k "playback" # يشغل اختبارات Playback
```

### 4. إنشاء تقرير تغطية الاختبارات

```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 📦 Test Files Structure

```
test/
├── features/
│   ├── quran/
│   │   ├── presentation/
│   │   │   ├── riverpod/
│   │   │   │   └── audio_controller_test.dart (10 tests)
│   │   │   └── widgets/
│   │   │       └── audio_button_test.dart (8 tests)
│   └── hifz/
│       └── data/
│           └── repositories/
│               └── isar_hifz_repository_test.dart (12 tests)
├── integration_tests/
│   └── audio_download_integration_test.dart (15 tests)
└── performance_tests/
    └── audio_performance_test.dart (20 tests)
```

---

## 🎯 Test Descriptions

### Unit Tests (40 tests)

#### audio_controller_test.dart (10 tests)

| رقم | الاختبار | الوصف |
|-----|---------|-------|
| 1 | AudioState copyWith preserves values | التحقق من حفظ القيم عند نسخ الحالة |
| 2 | download progress maintenance | التحقق من حفظ تقدم التحميل |
| 3 | playing state tracking | تتبع حالة التشغيل |
| 4 | concurrent progress updates | التعامل مع التحديثات المتزامنة |
| 5 | default values | القيم الافتراضية |
| 6 | null handling | معالجة null values |
| 7 | progress updates | تحديث التقدم |
| 8 | batch download state | حالة التحميل الجماعي |
| 9 | updatePlayingState | تحديث حالة التشغيل |
| 10 | rapid state changes | التغييرات السريعة |

#### isar_hifz_repository_test.dart (12 tests)

| رقم | الاختبار | الوصف |
|-----|---------|-------|
| 1-6 | Limit parameter tests | اختبارات معامل الحد |
| 7-8 | Memory efficiency | كفاءة الذاكرة |
| 9-10 | Error handling | معالجة الأخطاء |
| 11-12 | Record integrity | سلامة البيانات |

### Widget Tests (8 tests)

#### audio_button_test.dart (8 tests)

| رقم | الاختبار | الوصف |
|-----|---------|-------|
| 1 | Play button display | عرض زر التشغيل |
| 2 | Icon change on play | تغيير الرمز عند التشغيل |
| 3 | Toggle between play/pause | التبديل بين تشغيل/إيقاف |
| 4 | Loading state | حالة التحميل |
| 5 | Icon based on state | الرمز حسب الحالة |
| 6 | Progress bar display | عرض شريط التقدم |
| 7 | Progress bar updates | تحديث شريط التقدم |
| 8 | Edge cases | الحالات الحدية |

### Integration Tests (15 tests)

#### audio_download_integration_test.dart (15 tests)

| رقم | الاختبار | الوصف |
|-----|---------|-------|
| 1 | Playback workflow | سير عمل التشغيل |
| 2 | Surah switching | التبديل بين السور |
| 3 | Different reciters | قراء مختلفون |
| 4 | Rapid operations | العمليات السريعة |
| 5 | Download workflow | سير عمل التحميل |
| 6 | Batch downloads | التحميل الجماعي |
| 7 | Error handling | معالجة الأخطاء |
| 8 | Concurrent downloads | التحميلات المتزامنة |
| 9 | Play while download | التشغيل أثناء التحميل |
| 10 | Memory efficiency | كفاءة الذاكرة |
| 11-15 | Additional scenarios | سيناريوهات إضافية |

### Performance Tests (20 tests)

#### audio_performance_test.dart (20 tests)

| رقم | الاختبار | الوصف |
|-----|---------|-------|
| 1-5 | Playback performance | أداء التشغيل |
| 6-8 | Download performance | أداء التحميل |
| 9-11 | Memory efficiency | كفاءة الذاكرة |
| 12-14 | Response time | وقت الاستجابة |
| 15-20 | Threshold validation | التحقق من الحدود |

---

## 📊 Expected Results

### Audio Controller Tests
```
✅ 10/10 tests passed
⏱ Execution time: ~500ms
📊 Coverage: ~85%
```

### Widget Tests
```
✅ 8/8 tests passed
⏱ Execution time: ~1000ms
📊 Coverage: ~80%
```

### Integration Tests
```
✅ 15/15 tests passed
⏱ Execution time: ~1500ms
📊 Coverage: ~75%
```

### Performance Tests
```
✅ 20/20 tests passed
⏱ Execution time: ~800ms
📊 All metrics within thresholds
```

---

## 🔍 Debug Tips

### تفعيل السجلات التفصيلية

```bash
flutter test -v --verbose-logging
```

### تشغيل اختبار واحد فقط

```bash
flutter test test/features/quran/presentation/riverpod/audio_controller_test.dart -k "copyWith"
```

### عرض المزيد من المعلومات أثناء الاختبار

```dart
// في داخل الاختبار
print('Debug info: $value');
debugPrint('Debug: $value');
```

### استخدام DevTools

```bash
# في نافذة أخرى
flutter pub global activate devtools
devtools
```

---

## ⚠️ Common Issues and Solutions

### 1. اختبار معلق (Hanging Test)

**المشكلة:**
```
The following TestFailure was thrown running a test:
Test timed out after 30 seconds.
```

**الحل:**
```dart
test('name', () async {
  // إضافة timeout
}, timeout: Timeout(Duration(seconds: 60)));
```

### 2. Mock غير صحيح

**المشكلة:**
```
MissingStubError: 'method' was not stubbed
```

**الحل:**
```dart
when(() => mockObject.method()).thenAnswer((_) async => value);
```

### 3. State Management Issues

**المشكلة:**
```
StateError: Found multiple debugFillProperties
```

**الحل:**
```dart
setUp(() {
  container = ProviderContainer();
});

tearDown(() {
  container.dispose();
});
```

---

## 📈 Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: dart run coverage:format_coverage --lcov --in=coverage/lcov.info
```

---

## 🎓 Best Practices

### 1. اختبر الحالات الحدية

```dart
test('handles zero value', () {
  expect(calculateValue(0), equals(0));
});

test('handles negative value', () {
  expect(calculateValue(-1), isNegative);
});

test('handles large value', () {
  expect(calculateValue(999999), lessThan(1000000));
});
```

### 2. استخدم مقارنات واضحة

```dart
// ✅ جيد
expect(value, equals(5));
expect(list.length, lessThan(10));
expect(text, contains('error'));

// ❌ سيء
expect(value == 5, isTrue);
expect(list.length < 10, isTrue);
```

### 3. اختبر الأخطاء

```dart
test('throws exception on invalid input', () {
  expect(
    () => functionUnderTest(invalidInput),
    throwsException,
  );
});
```

### 4. استخدم Arrange-Act-Assert Pattern

```dart
test('example', () {
  // Arrange - تحضير البيانات
  final input = 5;
  
  // Act - تنفيذ العملية
  final result = function(input);
  
  // Assert - التحقق من النتيجة
  expect(result, equals(10));
});
```

---

## 📱 Device Testing

### أجهزة التطوير المدعومة

```bash
# عرض الأجهزة المتصلة
flutter devices

# تشغيل الاختبارات على جهاز معين
flutter test -d <device_id>
```

### اختبار على أنظمة تشغيل مختلفة

```bash
# Android
flutter test -d <android_device_id>

# iOS
flutter test -d <ios_device_id>

# Web
flutter test -d chrome

# Desktop
flutter test -d linux
```

---

## 🎯 Performance Testing

### تحليل الأداء

```bash
# إنشاء تقرير الأداء
flutter test test/performance_tests/audio_performance_test.dart \
  -v \
  --trace-startup

# فتح التقرير
flutter analyze
```

### مراقبة الموارد

```bash
# في جهاز حقيقي
adb logcat | grep "memory\|cpu"

# معلومات الذاكرة
adb shell dumpsys meminfo com.example.sila
```

---

## ✅ Pre-Release Checklist

```
[ ] جميع الاختبارات تمر
[ ] لا توجد تحذيرات
[ ] تغطية الاختبار > 70%
[ ] الأداء ضمن الحدود المقبولة
[ ] لا توجد memory leaks
[ ] الأجهزة الحقيقية تعمل بشكل صحيح
[ ] التوثيق محدث
[ ] النسخة محدثة
```

---

## 📞 Support

للمساعدة في الاختبارات:

1. **قراءة التوثيق:** https://flutter.dev/docs/testing
2. **البحث عن أمثلة:** https://github.com/flutter/samples
3. **الإبلاغ عن المشاكل:** GitHub Issues

---

**آخر تحديث:** 29 مارس 2026  
**الإصدار:** 2.1.1
