# 🏗️ معمارية نظام الترجمة في التطبيق

## 📐 معمارية easy_localization

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App Start                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│        EasyLocalization Widget (في main.dart)              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ supportedLocales: [ar-SA, tr-TR, en-US...]          │  │
│  │ path: 'assets/translations'                          │  │
│  │ fallbackLocale: ar-SA                                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┬──────────────────┐
        ↓                   ↓                  ↓
    ┌────────────┐   ┌─────────────┐  ┌──────────────┐
    │ ar-SA.json │   │ tr-TR.json  │  │ en-US.json   │
    │ (60 keys)  │   │ (54 keys)   │  │ (future)     │
    └────────────┘   └─────────────┘  └──────────────┘
        ↓                   ↓                  ↓
    ┌────────────────────────────────────────────────┐
    │     يختار المستخدم اللغة (Select Locale)      │
    └────────────────────────────────────────────────┘
                            ↓
    ┌────────────────────────────────────────────────┐
    │  BuildContext يوفر الترجمات الصحيحة للـ Widgets│
    └────────────────────────────────────────────────┘
                            ↓
    ┌────────────────────────────────────────────────┐
    │  'key'.tr() → تحويل المفتاح للنص في اللغة      │
    └────────────────────────────────────────────────┘
```

---

## 🔄 دورة تبديل اللغة

```
المستخدم يختار اللغة
        ↓
context.setLocale(Locale('tr', 'TR'))
        ↓
    Easy Localization يعيد تحميل اللغة
        ↓
    BuildContext يُحدّث
        ↓
    Consumer widgets تُعاد بناؤها
        ↓
    Text('key'.tr()) يعرض النص الجديد
        ↓
    ✨ التطبيق كله باللغة الجديدة
```

---

## 📁 ملفات الترجمة - هيكل JSON

### ar-SA.json (العربية)
```json
{
  "app_title": "صلة",
  "prayers": "مواقيت الصلاة",
  "fajr": "الفجر",
  "dhuhr": "الظهر",
  ...
}
```

### tr-TR.json (التركية)
```json
{
  "app_title": "Sıla",
  "prayers": "Namaz Vakitleri",
  "fajr": "İmsak",
  "dhuhr": "Öğle",
  ...
}
```

### en-US.json (الإنجليزية - مستقبلاً)
```json
{
  "app_title": "Sila",
  "prayers": "Prayer Times",
  "fajr": "Fajr",
  "dhuhr": "Dhuhr",
  ...
}
```

**القاعدة الذهبية**: 
✅ جميع الملفات يجب أن تحتوي على **نفس المفاتيح**
❌ إذا فقد مفتاح → سيظهر المفتاح نفسه أو fallback

---

## 🎯 حالات الاستخدام في الكود

### 1️⃣ نص بسيط
```dart
Text('app_title'.tr())
// ينتج: "صلة" (عربي) أو "Sıla" (تركي)
```

### 2️⃣ نص مع متغيرات
```dart
Text('gifts_count'.tr(args: ['5']))
// ينتج: "مرة: 5" أو "Hediye: 5"
// (يتطلب استخدام {} في JSON: "gifts_count": "مرة: {}")
```

### 3️⃣ تغيير اللغة الديناميكي
```dart
// تبديل للتركية
context.setLocale(const Locale('tr', 'TR'));

// تبديل للعربية
context.setLocale(const Locale('ar', 'SA'));
```

### 4️⃣ الحصول على اللغة الحالية
```dart
final currentLocale = context.locale;
// ينتج: Locale('tr', 'TR') إذا كانت التركية مختارة
```

### 5️⃣ فحص اتجاه النص
```dart
final isRTL = context.locale.languageCode == 'ar';
// ينتج: true للعربية (RTL)
// ينتج: false للتركية (LTR)
```

---

## 🔐 نقاط التحكم الرئيسية

### 1. في main.dart (نقطة البداية)
```dart
void main() async {
  await EasyLocalization.ensureInitialized();  // تحميل الملفات
  
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('ar', 'SA'), Locale('tr', 'TR')],
      path: 'assets/translations',
      child: SilaApp(),
    ),
  );
}
```

### 2. في pubspec.yaml (تسجيل المجلد)
```yaml
flutter:
  assets:
    - assets/translations/
```

### 3. في أي Stateless Widget
```dart
import 'package:easy_localization/easy_localization.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('app_title'.tr());
  }
}
```

### 4. في أي Stateful Widget
```dart
class MyStatefulWidget extends StatefulWidget {
  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Text('app_title'.tr());
  }
}
```

### 5. حفظ الاختيار (في Riverpod مثلاً)
```dart
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'ar';
    return Locale(code, code == 'ar' ? 'SA' : 'TR');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = AsyncValue.data(locale);
  }
}
```

---

## 🧩 كيفية عمل RTL/LTR التلقائي

### النظام يكتشف تلقائياً:

```
ar-SA (العربية)     ← RTL (Right-to-Left)
tr-TR (التركية)     ← LTR (Left-to-Right)
en-US (الإنجليزية)  ← LTR (Left-to-Right)
```

### المحرك يطبق تلقائياً:
```
- محاذاة النص (Alignment)
- اتجاه الأيقونات (Icon Direction)
- ترتيب الـ Row و Column
- padding و margin التلقائي
- اتجاه القائمة المنسدلة
```

---

## ⚠️ الأخطاء الشائعة وحلولها

### ❌ الخطأ 1: عدم استيراد easy_localization
```dart
// ❌ خطأ
Text('app_title')

// ✅ صحيح
import 'package:easy_localization/easy_localization.dart';
Text('app_title'.tr())
```

### ❌ الخطأ 2: مفتاح غير موجود
```dart
// ❌ سيظهر المفتاح نفسه
Text('non_existing_key'.tr())  // ينتج: "non_existing_key"

// ✅ تأكد من وجود المفتاح في جميع ملفات JSON
```

### ❌ الخطأ 3: نسيان التحديث في pubspec.yaml
```yaml
# ❌ خطأ: مجلد الترجمات غير مسجل
flutter:
  assets:
    - assets/images/

# ✅ صحيح
flutter:
  assets:
    - assets/translations/
    - assets/images/
```

### ❌ الخطأ 4: استخدام hardcoded strings
```dart
// ❌ خطأ: النص لن يتغير
Text('السلام عليكم')

// ✅ صحيح: استخدم المفاتيح
Text('welcome_message'.tr())
```

---

## 🚀 مثال عملي كامل

### الخطوة 1: إضافة نص في ar-SA.json
```json
{
  "greeting": "السلام عليكم ورحمة الله وبركاته"
}
```

### الخطوة 2: إضافة نفس النص في tr-TR.json
```json
{
  "greeting": "Assalaamu alaykum wa rahmatullahi wa barakatuh"
}
```

### الخطوة 3: استخدام في الشاشة
```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GreetingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('greeting'.tr()),  // سيعرض النص بحسب اللغة المختارة
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // تبديل اللغة
                if (context.locale.languageCode == 'ar') {
                  context.setLocale(const Locale('tr', 'TR'));
                } else {
                  context.setLocale(const Locale('ar', 'SA'));
                }
              },
              child: Text('Change Language'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📊 جدول مقارنة الطرق

| الطريقة | السهولة | المرونة | الأداء | التوصية |
|--------|--------|--------|--------|----------|
| easy_localization | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ الأفضل |
| Intl package | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | مرقعات معقدة |
| كود يدوي | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | لا توصى به |

---

**الخلاصة**: easy_localization هو الحل المثالي للتطبيق! 🎯
