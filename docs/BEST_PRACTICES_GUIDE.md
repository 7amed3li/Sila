# 🏆 Best Practices للـ Localization - Senior Level

---

## 1. 🔑 استخدام Code Generation (LocaleKeys)

### ❌ الطريقة العادية
```dart
Text('continue_reading'.tr())  // خطأ: string magic
// إذا حدث خطأ في الكتابة → لن تكتشفه إلا وقت التشغيل
```

### ✅ Best Practice
```dart
import 'package:sila_app/generated/locale_keys.g.dart';

Text(LocaleKeys.continue_reading.tr())  // ✅ آمن
// Compile error إذا كان المفتاح غير موجود
```

---

## 2. 📋 استخدام Named Arguments (بدل Positional)

### ❌ قديم وغير واضح
```json
{
  "greeting": "مرحباً {}"
}
```
```dart
'greeting'.tr(args: ['أحمد'])  // أي {} هذا؟
```

### ✅ الأفضل والوضيح
```json
{
  "greeting": "مرحباً {name}، أهلاً في {app}",
  "count_items": "لديك {count} عنصر"
}
```
```dart
'greeting'.tr(namedArgs: {
  'name': 'أحمد',
  'app': 'صلة',
})

'count_items'.tr(namedArgs: {'count': '5'})
```

---

## 3. 🎯 RTL/LTR صحيح

### ❌ خطأ شائع
```dart
Row(
  children: [
    Icon(Icons.arrow_back),
    Text('back'.tr()),
  ],
)
// في العربية: يجب أن يكون النص قبل الأيقونة
// لكن قد لا يتحول تلقائياً
```

### ✅ الطريقة الصحيحة
```dart
Row(
  textDirection: Directionality.of(context),
  children: [
    Icon(Icons.arrow_back),
    SizedBox(width: 8),
    Expanded(child: Text('back'.tr())),
  ],
)
```

---

## 4. 🔄 Dynamic Locale Selection

### ❌ Hardcoded (تقليدي)
```dart
if (languageCode == 'ar') {
  context.setLocale(Locale('ar', 'SA'));
} else if (languageCode == 'tr') {
  context.setLocale(Locale('tr', 'TR'));
}
```

### ✅ Dynamic (احترافي)
```dart
final locale = Locale(languageCode, countryCode);
context.setLocale(locale);
```

---

## 5. 💾 حفظ وتحميل اختيار اللغة

### ✅ Best Practice
```dart
// حفظ الاختيار
Future<void> setLanguage(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language_code', languageCode);
}

// تحميل الاختيار عند البدء
Future<Locale> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('language_code') ?? 'ar';
  return Locale(code, code == 'ar' ? 'SA' : 'TR');
}
```

---

## 6. 🛡️ Fallback Translations

### ✅ التكوين الآمن
```dart
EasyLocalization(
  supportedLocales: [Locale('ar', 'SA'), Locale('tr', 'TR')],
  fallbackLocale: Locale('ar', 'SA'),
  useFallbackTranslations: true,  // ← مهم!
  child: App(),
)
```

**النتيجة**:
- لو فقد مفتاح في tr-TR.json → سيستخدم ar-SA.json
- التطبيق لن ينهار

---

## 7. ⚡ Lazy Translation (أداء)

### في ListViews الكبيرة
```dart
class OptimizedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ترجمة واحدة عند البناء
    final itemLabel = LocaleKeys.item.tr();
    
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('$itemLabel #${index + 1}'),
          // بدون rebuild كل مرة
        );
      },
    );
  }
}
```

---

## 8. 🧪 Testing

### ✅ Unit Test للترجمات
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  group('Localization Tests', () {
    setUp(() async {
      await EasyLocalization.ensureInitialized();
    });

    test('Arabic translation exists', () {
      expect('app_title'.tr(), equals('صلة'));
    });

    test('Turkish translation exists', () {
      EasyLocalization.ensureInitialized();
      // تبديل اللغة
      // ثم اختبار
    });
  });
}
```

---

## 9. 📱 Platform-Specific

### iOS/Android Languages
```dart
// تحميل لغة الجهاز تلقائياً
Future<void> initializeWithDeviceLocale() async {
  final deviceLocale = ui.window.locale;
  
  if (deviceLocale.languageCode == 'ar') {
    await context.setLocale(Locale('ar', 'SA'));
  } else if (deviceLocale.languageCode == 'tr') {
    await context.setLocale(Locale('tr', 'TR'));
  }
}
```

---

## 10. 🎨 Theme + Localization

### ✅ معاً
```dart
class ThemedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: context.locale,  // ← اللغة
      theme: context.locale.languageCode == 'ar'
          ? arabicTheme
          : turkishTheme,        // ← الثيم يتغير أيضاً
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
    );
  }
}
```

---

## 📋 JSON Structure - Best Practice

### ✅ منظم وواضح
```json
{
  "_comment": "General",
  "app_title": "صلة",
  "app_version": "النسخة: {}",
  
  "_comment2": "Navigation",
  "tab_home": "الرئيسية",
  "tab_quran": "القرآن",
  
  "_comment3": "Prayers",
  "prayer_fajr": "الفجر",
  "prayer_dhuhr": "الظهر",
  "prayer_time_remaining": "متبقي: {time}",
  
  "_comment4": "Errors",
  "error_network": "خطأ في الاتصال",
  "error_not_found": "{item} غير موجود"
}
```

---

## 🔐 Security Best Practice

### لا تضع معلومات حساسة في JSON
```json
// ❌ خطأ - معلومات حساسة
{
  "api_key": "xyz123"
}

// ✅ صحيح - نصوص فقط
{
  "api_error": "خطأ في الخادم"
}
```

---

## 📊 Performance Tips

### 1. Context Caching
```dart
final context = this.context;  // cache
return Text(LocaleKeys.title.tr());  // استخدم
```

### 2. Const Widgets
```dart
const SizedBox(height: 16),  // لا rebuild
```

### 3. RepaintBoundary
```dart
RepaintBoundary(
  child: Text(LocaleKeys.expensive.tr()),
)
```

---

## 🚀 Deployment Best Practices

### 1. قبل النشر
```
☑ اختبر جميع الترجمات
☑ تحقق من RTL/LTR
☑ اختبر على أجهزة حقيقية
☑ تحقق من المفاتيح المفقودة
```

### 2. Release Notes
```
Updated language support:
- Added complete Turkish localization
- Fixed RTL layout issues
- Improved performance
```

---

## 📚 Project Structure (Best)

```
lib/
├── generated/
│   └── locale_keys.g.dart         (Code generation)
├── core/
│   ├── localization/
│   │   ├── app_localization.dart
│   │   └── locale_provider.dart
│   └── widgets/
│       └── language_switcher.dart
├── features/
│   └── settings/
│       └── presentation/
│           └── pages/
│               └── settings_page.dart

assets/
└── translations/
    ├── ar-SA.json
    ├── tr-TR.json
    └── en-US.json (مستقبلاً)
```

---

## 🎓 التطور المستقبلي

### Level 1: Basic
```dart
Text('key'.tr())
```

### Level 2: Advanced (أنت هنا)
```dart
Text(LocaleKeys.key.tr(namedArgs: {...}))
```

### Level 3: Enterprise
```dart
// مع Plural forms, Gender forms, Date formatting
'items_count'.plural(count)
```

---

## ✅ Checklist - Production Ready

- ✅ Code generation مع LocaleKeys
- ✅ Named arguments للمتغيرات
- ✅ RTL/LTR صحيح تماماً
- ✅ Fallback translations
- ✅ حفظ اختيار اللغة
- ✅ Dynamic locale selection
- ✅ Settings page احترافية
- ✅ Testing شامل
- ✅ Performance optimized
- ✅ Error handling

---

## 🎯 الخلاصة

**من Basic لـ Enterprise-Level**

```
String magic        ❌
↓
Code generation     ✅
↓
Full i18n system    🚀
```

---

**أنت الآن جاهز لأي تطبيق دولي احترافي!** 🌍
