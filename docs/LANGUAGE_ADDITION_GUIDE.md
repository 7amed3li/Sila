# 🌍 دليل إضافة اللغات للتطبيق

## 📋 الوضع الحالي

التطبيق يستخدم **easy_localization v3.0.3** ويدعم حالياً:
- ✅ العربية (ar-SA)
- ✅ التركية (tr-TR)

---

## 🔧 كيفية عمل نظام الترجمة الحالي

### 1️⃣ ملفات الترجمة (JSON)
```
assets/translations/
├── ar-SA.json  (60 مفتاح ترجمة)
└── tr-TR.json  (54 مفتاح ترجمة)
```

### 2️⃣ التكوين في main.dart
```dart
EasyLocalization(
  supportedLocales: const [
    Locale('ar', 'SA'),
    Locale('tr', 'TR'),
  ],
  path: 'assets/translations',
  fallbackLocale: const Locale('ar', 'SA'),
  startLocale: const Locale('ar', 'SA'),
  child: const SilaApp(),
)
```

### 3️⃣ استخدام الترجمة في الكود
في أي شاشة أو widget:
```dart
import 'package:easy_localization/easy_localization.dart';

Text('app_title'.tr())  // سيعرض "صلة" أو "Sıla" حسب اللغة المختارة
```

### 4️⃣ تغيير اللغة من التطبيق
```dart
// في أي مكان في التطبيق
context.setLocale(const Locale('ar', 'SA'));  // تبديل للعربية
context.setLocale(const Locale('tr', 'TR'));  // تبديل للتركية
```

---

## ✨ السهولة في إضافة لغات جديدة

### لماذا إضافة لغات سهلة جداً؟

1. **لا حاجة لتعديل الكود** - كل شيء يعتمد على ملفات JSON
2. **لا حاجة لإعادة بناء** - تغيير الملف والتطبيق يعمل
3. **تلقائي التطبيق** - easy_localization يتولى كل شيء
4. **دعم RTL وLTR** - التطبيق يدعم الكتابة من اليمين واليسار تلقائياً

---

## 🚀 خطة إضافة التركية بشكل كامل

### المرحلة 1: إنشاء ملف الترجمة الكامل
**الحالة الحالية**: ملف tr-TR.json يحتوي على 54 مفتاح فقط
**المطلوب**: توسيع الملف ليشمل جميع المفاتيح (مثل ar-SA.json)

### المرحلة 2: تحديث main.dart
```dart
// main.dart - لا تغيير مطلوب! اللغة التركية مضافة بالفعل
supportedLocales: const [
  Locale('ar', 'SA'),
  Locale('tr', 'TR'),  // ✅ موجودة
]
```

### المرحلة 3: إضافة واجهة تبديل اللغة
- إضافة settings/preferences page
- زر لتبديل اللغة
- حفظ الخيار في SharedPreferences

### المرحلة 4: اختبار على جميع الشاشات
التأكد من أن جميع النصوص تظهر باللغة الصحيحة على:
- ✅ الشاشة الرئيسية
- ✅ شاشات القرآن
- ✅ شاشات الصلاة
- ✅ شاشات الحفظ
- ✅ جميع الشاشات الأخرى

---

## 📊 الخطوات التفصيلية

### ✅ الخطوة 1: فحص وتوسيع ملفات الترجمة

**المشكلة الحالية**:
- ar-SA.json: 60 مفتاح
- tr-TR.json: 54 مفتاح فقط (ناقصة 6 مفاتيح)

**الحل**:
1. مقارنة ar-SA.json و tr-TR.json
2. إضافة المفاتيح الناقصة في tr-TR.json

### ✅ الخطوة 2: إضافة واجهة تبديل اللغة

**المكان الموصى به**: إضافة أيقونة اللغة في AppBar أو قائمة الإعدادات

```dart
PopupMenuButton(
  itemBuilder: (context) => [
    PopupMenuItem(
      child: Text('العربية'),
      onTap: () => context.setLocale(const Locale('ar', 'SA')),
    ),
    PopupMenuItem(
      child: Text('Türkçe'),
      onTap: () => context.setLocale(const Locale('tr', 'TR')),
    ),
  ],
)
```

### ✅ الخطوة 3: حفظ اختيار اللغة

```dart
// حفظ اختيار المستخدم
final prefs = await SharedPreferences.getInstance();
await prefs.setString('language_code', 'tr');
await prefs.setString('country_code', 'TR');

// استرجاع اختيار المستخدم عند بدء التطبيق
final savedLocale = prefs.getString('language_code');
if (savedLocale != null) {
  context.setLocale(Locale(savedLocale, 'SA/TR'));
}
```

### ✅ الخطوة 4: اختبار شامل

```
☑️ تبديل من العربية للتركية
☑️ تبديل من التركية للعربية
☑️ فحص جميع الشاشات
☑️ فحص RTL/LTR في النصوص
☑️ فحص الأرقام والرموز
☑️ فحص الإشعارات
☑️ فحص أسماء الصلوات
☑️ فحص التواريخ والأوقات
```

---

## 🎯 إضافة لغات إضافية (مستقبلاً)

لإضافة لغة جديدة (مثل الإنجليزية)، ما عليك سوى:

1. **إنشاء ملف ترجمة جديد**:
   ```
   assets/translations/en-US.json
   ```

2. **نسخ نفس المفاتيح**:
   ```json
   {
     "app_title": "Sila",
     "welcome_message": "Welcome to Sila",
     ...
   }
   ```

3. **تحديث main.dart**:
   ```dart
   supportedLocales: const [
     Locale('ar', 'SA'),
     Locale('tr', 'TR'),
     Locale('en', 'US'),  // ✨ اللغة الجديدة
   ]
   ```

4. **Done! ✨** - التطبيق يدعم اللغة الجديدة تلقائياً

---

## 📝 ملخص الفوائد

| الميزة | الفائدة |
|--------|--------|
| **JSON files** | سهل التعديل والصيانة |
| **easy_localization** | لا حاجة لإعادة بناء |
| **RTL Support** | دعم تلقائي للعربية والتركية |
| **Nested Keys** | دعم الترجمات المتقدمة |
| **Context API** | تغيير اللغة مباشرة دون إعادة تشغيل |

---

## 🔍 المفاتيح المطلوبة (60 مفتاح)

```
1. app_title
2. welcome_message
3. quran
4. azkar
5. prayers
6. next_prayer
7. fajr
8. sunrise
9. dhuhr
10. asr
11. maghrib
12. isha
13. remaining_time
14. location_mock
15. last_read
16. continue_reading
17. daily_content
18. ayah_label
19. azkar_morning
20. azkar_evening
21. azkar_sleep
22. azkar_mosque
23. azkar_tasbih
24. location_settings
25. auto_location
26. enter_city
27. save
28. vefa_system
29. vefa_list
30. vefa_list_desc
31. add_new
32. add_loved_one
33. name
34. relation
35. optional
36. field_required
37. vefa_list_empty
38. thawab_gifted
39. gifts_count
40. gift_thawab
41. duaa_suggested_title
42. duaa_suggested_desc
43. duaa_safe_template
44. copy_duaa
45. share_duaa
46. vefa_reminder_title
47. vefa_reminder_body
48. tap_to_count
49. daily_wird
50. start_reading
51. great_job_wird_done
52. wird_completed_title
53. wird_completed_body
54. done_only
55. page
56. juz
57. sunan_mahjoura
58. sunan_mahjoura_desc
59. hifz (إضافي)
60. tasmi (إضافي)
... (المزيد حسب الحاجة)
```

---

## ⚡ الخطة السريعة

```
الأسبوع 1:
├─ ✅ توسيع tr-TR.json بكل المفاتيح
├─ ✅ إضافة واجهة تبديل اللغة
└─ ✅ اختبار الشاشات الرئيسية

الأسبوع 2:
├─ ✅ اختبار شامل لجميع الشاشات
├─ ✅ فحص RTL/LTR
└─ ✅ نشر النسخة الجديدة
```

---

**النتيجة النهائية**: 
✨ تطبيق يدعم اللغة التركية كاملة على جميع الشاشات والميزات!
