# 🎯 خطوات تطبيق إضافة اللغة التركية (خطوة بخطوة)

## 📋 الملخص السريع

نريد أن يختار المستخدم اللغة، ويصبح **كل شيء** في التطبيق باللغة المختارة (كل الشاشات، كل الميزات، كل الأزرار).

---

## ✅ القائمة الكاملة للخطوات

### المرحلة 1️⃣: توسيع ملفات الترجمة

#### الخطوة 1.1: مقارنة الملفات الحالية

**الملف الحالي**: `tr-TR.json` ← 54 مفتاح فقط  
**المطلوب**: إضافة 6 مفاتيح ناقصة لتصبح 60 مفتاح

**المفاتيح الناقصة** (موجودة في ar-SA.json ولا توجد في tr-TR.json):

```json
"vefa_list_desc": "Sevabını hediye etmek için sevdiklerinizi ekleyin.",
"duaa_suggested_title": "Sevab Hediye Etme ve Dua",
"duaa_suggested_desc": "Okuduğunuzun veya hayır yaptığınızın sevabını ölüye hediye edebilirsiniz. İşte sevab hediye etmek için bir dua:",
"duaa_safe_template": "Allah'ım bunu benden kabul et ve bu işin sevabını {} için kıl, ona mağfir ve rahmet et",
"copy_duaa": "Duayı Kopyala",
"share_duaa": "Paylaş"
```

#### الخطوة 1.2: تحديث tr-TR.json

**المكان**: `sila_app/assets/translations/tr-TR.json`

**العملية**:
1. فتح الملف
2. إضافة المفاتيح الناقصة
3. حفظ الملف

---

### المرحلة 2️⃣: تفعيل اللغة في الكود

#### الخطوة 2.1: التحقق من main.dart

**الملف**: `lib/main.dart` - سطر 57-61

**الحالة الحالية**:
```dart
EasyLocalization(
  supportedLocales: const [
    Locale('ar', 'SA'),
    Locale('tr', 'TR'),  // ✅ موجودة بالفعل!
  ],
  ...
)
```

**الحالة المطلوبة**: ✅ **لا تغيير مطلوب** - اللغة التركية مضافة بالفعل!

---

### المرحلة 3️⃣: إضافة واجهة تبديل اللغة

#### الخطوة 3.1: إنشاء Language Switcher Widget

**المكان**: إنشاء ملف جديد
```
lib/core/presentation/widgets/language_switcher.dart
```

**الكود**:
```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String languageCode) {
        if (languageCode == 'ar') {
          context.setLocale(const Locale('ar', 'SA'));
        } else if (languageCode == 'tr') {
          context.setLocale(const Locale('tr', 'TR'));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'ar',
          child: Row(
            children: [
              const Text('العربية'),
              const SizedBox(width: 8),
              context.locale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: Colors.green)
                  : const SizedBox(width: 24),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'tr',
          child: Row(
            children: [
              const Text('Türkçe'),
              const SizedBox(width: 8),
              context.locale.languageCode == 'tr'
                  ? const Icon(Icons.check, color: Colors.green)
                  : const SizedBox(width: 24),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.language),
    );
  }
}
```

#### الخطوة 3.2: إضافة الـ Widget في AppBar

**الملف**: `lib/core/presentation/widgets/sila_app_bar.dart` أو `lib/core/presentation/main_layout.dart`

**الكود المطلوب إضافته**:
```dart
import 'package:sila_app/core/presentation/widgets/language_switcher.dart';

// في AppBar
AppBar(
  actions: [
    const LanguageSwitcher(),
    const SizedBox(width: 8),
  ],
)
```

---

### المرحلة 4️⃣: حفظ اختيار اللغة (اختياري لكن موصى به)

#### الخطوة 4.1: إنشاء Locale Provider

**المكان**: إنشاء ملف جديد
```
lib/core/providers/locale_provider.dart
```

**الكود**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar', 'SA')) {
    _initLocale();
  }

  Future<void> _initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ar';
    final countryCode = languageCode == 'ar' ? 'SA' : 'TR';
    state = Locale(languageCode, countryCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }
}
```

#### الخطوة 4.2: تحديث main.dart لحفظ الاختيار

**الملف**: `lib/main.dart` - في الـ startLocale

```dart
// قبل
startLocale: const Locale('ar', 'SA'),

// بعد (مع Riverpod)
// ستستخدم الـ Provider لتحميل الاختيار المحفوظ
```

---

### المرحلة 5️⃣: اختبار شامل

#### الخطوة 5.1: فحص الشاشات الرئيسية

اختبر بدقة على كل شاشة:

```
التطبيق:
☑️ الشاشة الرئيسية (HomePage)
☑️ شاشات القرآن (QuranPage, SurahDetailPage)
☑️ شاشات الصلاة (PrayersPage, QiblahPage)
☑️ شاشات الحفظ (HifzHomePage, InteractiveShadowPage)
☑️ شاشات الأذكار (AzkarPage, AzkarDetailPage)
☑️ شاشات الورد (WirdReaderPage, WirdSetupPage)
☑️ شاشات التسميع (TasmiPage)
☑️ شاشات الفيفا (VefaPage)
☑️ الإشعارات (NotificationHubPage)
☑️ التقارير (DailyReportPage)

النصوص:
☑️ أسماء الصلوات (الفجر، الظهر، إلخ)
☑️ الأزرار (حفظ، إضافة، حذف)
☑️ الرسائل (مرحباً، تهانينا)
☑️ الأخطاء والتحذيرات
☑️ الإشعارات والنبهات

الاتجاهات:
☑️ النص من اليمين لليسار (RTL) للعربية
☑️ النص من اليسار لليمين (LTR) للتركية
☑️ الأيقونات في الاتجاه الصحيح
☑️ الأزرار والعناصر محاذية بشكل صحيح
```

#### الخطوة 5.2: اختبار التبديل السريع

```dart
// اختبر هذا الإجراء:
1. افتح التطبيق (يجب أن يكون باللغة الافتراضية - العربية)
2. اختر اللغة التركية من الأيقونة
3. تحقق من أن كل شيء تغير للتركية
4. اختر اللغة العربية من جديد
5. تحقق من أن كل شيء عاد للعربية
6. أغلق التطبيق وأعد فتحه
7. تحقق من أن اللغة المحفوظة تم استرجاعها
```

---

## 🎁 الملفات التي سيتم تعديلها

### إضافة/تعديل:

```
1. ✏️ sila_app/assets/translations/tr-TR.json
   └─ إضافة 6 مفاتيح ناقصة

2. ✨ lib/core/presentation/widgets/language_switcher.dart (ملف جديد)
   └─ Widget لتبديل اللغة

3. ✏️ lib/core/presentation/widgets/sila_app_bar.dart (أو main_layout.dart)
   └─ إضافة LanguageSwitcher في AppBar

4. 🎁 lib/core/providers/locale_provider.dart (اختياري - ملف جديد)
   └─ Riverpod provider لحفظ اختيار اللغة
```

---

## 🚀 كود يمكنك تشغيله فوراً

### اختبار ترجمة بسيطة:

```dart
// أضف هذا في أي Stateless Widget للاختبار
import 'package:easy_localization/easy_localization.dart';

class TestTranslation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('app_title'.tr()),          // صلة / Sıla
        Text('prayers'.tr()),            // مواقيت الصلاة / Namaz Vakitleri
        Text('fajr'.tr()),               // الفجر / İmsak
        Text('azkar'.tr()),              // الأذكار / Zikirler
        Text('quran'.tr()),              // القرآن الكريم / Kuran-ı Kerim
      ],
    );
  }
}
```

---

## 📊 الجدول الزمني

```
اليوم 1:
├─ فحص الملفات الحالية
└─ إضافة المفاتيح الناقصة

اليوم 2:
├─ إنشاء Language Switcher
└─ إضافة الـ Widget في AppBar

اليوم 3:
├─ إضافة Locale Provider (اختياري)
└─ اختبار أساسي

اليوم 4:
├─ اختبار شامل على جميع الشاشات
├─ فحص RTL/LTR
└─ تصحيح أي مشاكل
```

---

## ⚙️ ملخص التكوين النهائي

### main.dart (بعد التعديل)
```dart
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ar', 'SA'),  // العربية
          Locale('tr', 'TR'),  // التركية ✨
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar', 'SA'),
        startLocale: const Locale('ar', 'SA'),
        child: const SilaApp(),
      ),
    ),
  );
}

class SilaApp extends StatelessWidget {
  const SilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sıla',
      localizationsDelegates: context.localizationDeleg
