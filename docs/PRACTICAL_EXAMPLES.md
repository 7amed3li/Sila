# 🔧 أمثلة عملية: قبل وبعد

---

## مثال 1️⃣: النص البسيط

### ❌ الطريقة القديمة (hardcoded)
```dart
Text('صلة')  // نص ثابت - لا يتغير
```

**المشكلة**: النص لا يتغير أبداً، دائماً بالعربية

---

### ✅ الطريقة الجديدة (مع easy_localization)
```dart
import 'package:easy_localization/easy_localization.dart';

Text('app_title'.tr())  // مفتاح ترجمة
```

**النتيجة**:
- عند اختيار العربية: يظهر "صلة"
- عند اختيار التركية: يظهر "Sıla"
- **تلقائياً!** ✨

---

## مثال 2️⃣: الأزرار

### ❌ قبل
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('حفظ'),  // نص ثابت
)
```

### ✅ بعد
```dart
import 'package:easy_localization/easy_localization.dart';

ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr()),  // يتغير حسب اللغة
)
```

**النتيجة**:
- العربية: "حفظ"
- التركية: "Kaydet"

---

## مثال 3️⃣: أسماء الصلوات

### ❌ قبل
```dart
Column(
  children: [
    Text('الفجر'),
    Text('الظهر'),
    Text('العصر'),
  ],
)
```

### ✅ بعد
```dart
Column(
  children: [
    Text('fajr'.tr()),
    Text('dhuhr'.tr()),
    Text('asr'.tr()),
  ],
)
```

**النتيجة**:
- العربية: الفجر، الظهر، العصر
- التركية: İmsak، Öğle، İkindi

---

## مثال 4️⃣: الرسائل الديناميكية

### ❌ قبل
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('نجحت العملية'),
    content: Text('تم الحفظ بنجاح'),
  ),
)
```

### ✅ بعد
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('success_title'.tr()),
    content: Text('saved_successfully'.tr()),
  ),
)
```

---

## مثال 5️⃣: الرسائل مع متغيرات

### ❌ قبل
```dart
Text('عدد الهدايا: 5')  // محاصر في الكود
```

### ✅ بعد
```dart
// في JSON
// "gifts_count": "عدد الهدايا: {}"

Text('gifts_count'.tr(args: ['5']))
```

---

## مثال 6️⃣: تبديل اللغة من الزر

### ❌ قبل (لا يمكن التبديل)
```dart
// التطبيق بالعربية دائماً
```

### ✅ بعد
```dart
import 'package:easy_localization/easy_localization.dart';

ElevatedButton(
  onPressed: () {
    // تبديل للتركية
    context.setLocale(const Locale('tr', 'TR'));
  },
  child: Text('switch_to_turkish'.tr()),
)
```

---

## مثال 7️⃣: الشاشة الكاملة

### ❌ قبل
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صلة'),  // ❌ ثابت
      ),
      body: Column(
        children: [
          Text('مواقيت الصلاة'),  // ❌ ثابت
          Text('الصلاة القادمة'),  // ❌ ثابت
          ElevatedButton(
            onPressed: () {},
            child: Text('متابعة'),  // ❌ ثابت
          ),
        ],
      ),
    );
  }
}
```

### ✅ بعد
```dart
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),  // ✅ يتغير
      ),
      body: Column(
        children: [
          Text('prayers'.tr()),  // ✅ يتغير
          Text('next_prayer'.tr()),  // ✅ يتغير
          ElevatedButton(
            onPressed: () {},
            child: Text('continue_reading'.tr()),  // ✅ يتغير
          ),
        ],
      ),
    );
  }
}
```

---

## مثال 8️⃣: مع Language Switcher

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (lang) {
              if (lang == 'ar') {
                context.setLocale(const Locale('ar', 'SA'));
              } else {
                context.setLocale(const Locale('tr', 'TR'));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'ar',
                child: Text('العربية'),
              ),
              PopupMenuItem(
                value: 'tr',
                child: Text('Türkçe'),
              ),
            ],
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Column(
        children: [
          Text('prayers'.tr()),
          ElevatedButton(
            onPressed: () {},
            child: Text('continue_reading'.tr()),
          ),
        ],
      ),
    );
  }
}
```

**عند الضغط على اللغة واختيار "Türkçe":**
- Title تتغير: "صلة" → "Sıla"
- البطاقة تتغير: "مواقيت الصلاة" → "Namaz Vakitleri"
- الزر يتغير: "متابعة" → "Okumaya Devam Et"
- **كل شيء يتحول فوراً!** ✨

---

## مثال 9️⃣: JSON Files

### ar-SA.json
```json
{
  "app_title": "صلة",
  "prayers": "مواقيت الصلاة",
  "next_prayer": "الصلاة القادمة",
  "continue_reading": "تابِع القراءة",
  "fajr": "الفجر",
  "dhuhr": "الظهر",
  "asr": "العصر",
  "gifts_count": "مرة: {}",
  "save": "حفظ",
  "add": "إضافة"
}
```

### tr-TR.json
```json
{
  "app_title": "Sıla",
  "prayers": "Namaz Vakitleri",
  "next_prayer": "Sonraki Vakit",
  "continue_reading": "Okumaya Devam Et",
  "fajr": "İmsak",
  "dhuhr": "Öğle",
  "asr": "İkindi",
  "gifts_count": "Hediye: {}",
  "save": "Kaydet",
  "add": "Ekle"
}
```

**ملاحظة**: نفس المفاتيح في الملفين!

---

## مثال 🔟: RTL/LTR التلقائي

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PrayersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('prayers'.tr()),    // النص
        Icon(Icons.access_time),  // الأيقونة
      ],
    );
  }
}
```

**النتيجة**:

**عند اختيار العربية (RTL)**:
```
أيقونة ← النص
```

**عند اختيار التركية (LTR)**:
```
النص → أيقونة
```

**الترتيب يتغير تلقائياً!** ✨

---

## ملخص الأمثلة

| المثال | قبل | بعد | الفائدة |
|--------|------|-----|----------|
| 1 | `Text('صلة')` | `Text('app_title'.tr())` | يتغير حسب اللغة |
| 2 | `Text('حفظ')` | `Text('save'.tr())` | دعم لغات متعددة |
| 3 | أسماء ثابتة | `Text('fajr'.tr())` | جميع الأسماء تتغير |
| 4 | رسائل ثابتة | `Text('success'.tr())` | رسائل ديناميكية |
| 5 | نص مع أرقام ثابتة | مع args | نصوص مرنة |
| 6 | لا يمكن التبديل | `setLocale()` | تبديل فوري |
| 7 | شاشة بنص ثابت | شاشة بترجمات | تطبيق دولي |
| 8 | بدون تبديل | مع Language Switcher | واجهة سهلة |
| 9 | لا توجد ترجمات | JSON files | إدارة ترجمات |
| 10 | اتجاه ثابت | RTL/LTR تلقائي | تصميم دقيق |

---

## ✅ الخلاصة

**الفرق الرئيسي**:
- ❌ **قبل**: `Text('نص ثابت')`
- ✅ **بعد**: `Text('key'.tr())`

**الفائدة**:
- جميع النصوص تتحول فوراً
- دعم لغات غير محدود
- تصميم يدعم RTL/LTR
- تجربة مستخدم احترافية

**الوقت**: 40 دقيقة فقط لإكمال كل شيء! ⏱️

---

**الآن أنت جاهز لفهم كيفية عمل كل شيء!** 🚀
