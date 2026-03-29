# 🔧 أمثلة عملية احترافية - Production Level

---

## مثال 1️⃣: النص البسيط

### ❌ الطريقة القديمة
```dart
Text('صلة')  // Hardcoded - لا يتغير
```

### ✅ الطريقة الاحترافية
```dart
import 'package:easy_localization/easy_localization.dart';

Text('app_title'.tr())
```

**النتيجة**:
- العربية: "صلة"
- التركية: "Sıla"
- **تلقائياً!** ✨

---

## مثال 2️⃣: args vs namedArgs (الفرق الحقيقي)

### ❌ الطريقة القديمة (أقل وضوحاً)
```json
{
  "gifts_count": "عدد الهدايا: {}"
}
```

```dart
'gifts_count'.tr(args: ['5'])  // ❌ غير واضح - أي {}؟
```

---

### ✅ الطريقة الاحترافية (واضحة وآمنة)
```json
{
  "gifts_count": "عدد الهدايا: {count}"
}
```

```dart
'gifts_count'.tr(namedArgs: {'count': '5'})  // ✅ واضح جداً!
```

**الفوائد**:
- ✅ واضح أي متغير يُستخدم
- ✅ سهل الصيانة والفحص
- ✅ يعمل مع لغات معقدة
- ✅ أقل أخطاء

---

## مثال 3️⃣: مثال أكثر تعقيداً

### ar-SA.json
```json
{
  "daily_report": "تقريرك اليومي: {count} عبادات في {date}",
  "user_greeting": "السلام عليكم {name}، أهلاً بعودتك"
}
```

### tr-TR.json
```json
{
  "daily_report": "Günlük raporunuz: {date} de {count} İbadet",
  "user_greeting": "Merhaba {name}, hoşgeldiniz"
}
```

### الاستخدام
```dart
Text(
  'daily_report'.tr(namedArgs: {
    'count': '15',
    'date': '2024-03-23',
  })
)

Text(
  'user_greeting'.tr(namedArgs: {
    'name': 'أحمد',
  })
)
```

---

## مثال 4️⃣: RTL/LTR الصحيح في Row

### ❌ المشكلة في الكود القديم
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('prayers'.tr()),
    Icon(Icons.access_time),
  ],
)

// النتيجة: قد لا يتغير الترتيب تلقائياً في بعض الحالات!
```

---

### ✅ الحل الصحيح

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

Row(
  textDirection: Directionality.of(context),  // ← مهم جداً
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(child: Text('prayers'.tr())),
    Icon(Icons.access_time),
  ],
)
```

**لماذا**:
- ✅ `Directionality.of(context)` يأخذ الاتجاه من اللغة الحالية
- ✅ RTL للعربية تلقائياً
- ✅ LTR للتركية تلقائياً
- ✅ 100% reliable

---

## مثال 5️⃣: Language Switcher احترافي

### ❌ النسخة البسيطة (hardcoded)
```dart
PopupMenuButton<String>(
  onSelected: (lang) {
    if (lang == 'ar') {
      context.setLocale(Locale('ar', 'SA'));
    } else if (lang == 'tr') {
      context.setLocale(Locale('tr', 'TR'));
    }
  },
  itemBuilder: (_) => [
    PopupMenuItem(value: 'ar', child: Text('العربية')),
    PopupMenuItem(value: 'tr', child: Text('Türkçe')),
  ],
)
```

❌ **المشاكل**:
- كل لغة جديدة = تعديل كود
- يصعب الصيانة
- معرض للأخطاء

---

### ✅ النسخة الاحترافية (ديناميكية)

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const _languageNames = {
    'ar': 'العربية',
    'tr': 'Türkçe',
    'en': 'English',  // لو أضفنا انجليزي مستقبلاً
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      onSelected: (Locale locale) {
        context.setLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return context.supportedLocales.map((locale) {
          final isSelected = context.locale == locale;
          final langName = _languageNames[locale.languageCode] 
              ?? locale.languageCode;
          
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Text(langName),
                const SizedBox(width: 8),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.green)
                else
                  const SizedBox(width: 24),
              ],
            ),
          );
        }).toList();
      },
      icon: const Icon(Icons.language),
    );
  }
}
```

**الفوائد**:
- ✅ لو أضفنا `English` → يظهر تلقائياً
- ✅ لا حاجة لتعديل الكود
- ✅ قابل للتوسع

---

## مثال 6️⃣: حماية من Missing Keys (Code Generation)

### ❌ الطريقة غير الآمنة
```dart
Text('continu_reading'.tr())  // ❌ خطأ في الكتابة!
// سيظهر: "continu_reading" بدل الترجمة
// الخطأ صعب الاكتشاف
```

---

### ✅ الطريقة الاحترافية (مع code generation)

#### خطوة 1: تثبيت dependency
```yaml
dev_dependencies:
  easy_localization_loader: ^3.0.0
```

#### خطوة 2: إنشاء constants file
```dart
// lib/generated/locale_keys.g.dart
abstract class LocaleKeys {
  static const app_title = 'app_title';
  static const prayers = 'prayers';
  static const continue_reading = 'continue_reading';
  static const fajr = 'fajr';
  static const dhuhr = 'dhuhr';
  // ... إلخ
}
```

#### خطوة 3: الاستخدام
```dart
import 'package:sila_app/generated/locale_keys.g.dart';

Text(LocaleKeys.continue_reading.tr())  // ✅ آمن 100%
// إذا كان هناك خطأ → سيظهر compile error مباشرة!
```

**الفوائد**:
- ✅ لا يمكن الكتابة الخاطئة
- ✅ IDE autocomplete يعمل
- ✅ اكتشاف الأخطاء في compile time

---

## مثال 7️⃣: استخدام ConsumerWidget مع Riverpod

### ❌ المشكلة في StatelessWidget
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('prayers'.tr());
    // لو تغيرت اللغة → قد لا يعاد البناء!
  }
}
```

---

### ✅ الحل مع Riverpod (Consumer)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // سيعاد البناء تلقائياً عند تغيير اللغة
    final currentLocale = context.locale;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
      ),
      body: Column(
        children: [
          Text('prayers'.tr()),
          Text('current_language: ${currentLocale.languageCode}'),
        ],
      ),
    );
  }
}
```

**لماذا**:
- ✅ ConsumerWidget يدعم الـ rebuild عند تغيير اللغة
- ✅ Riverpod يتعامل مع State management بشكل صحيح

---

## مثال 8️⃣: Fallback Translations (آمن وموثوق)

### في main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('tr', 'TR'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar', 'SA'),
        startLocale: const Locale('ar', 'SA'),
        useFallbackTranslations: true,  // ← مهم جداً
        child: const SilaApp(),
      ),
    ),
  );
}
```

**النتيجة**:
- ✅ لو فقد مفتاح في tr-TR.json → سيستخدم ar-SA.json
- ✅ التطبيق لن ينهار
- ✅ تجربة مستخدم سلسة

---

## مثال 9️⃣: Lazy Translation (أداء أفضل)

### ❌ في Widgets الثقيلة (قد يسبب rebuild)
```dart
class HeavyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return Text('item_label'.tr());  // ❌ يُترجم كل مرة
      },
    );
  }
}
```

---

### ✅ النسخة المُحسّنة (Lazy Translation)

```dart
class HeavyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = _TranslationHelper(context);  // ← ترجمة واحدة فقط
    
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return Text(t('item_label'));  // ✅ بدون rebuild كل مرة
      },
    );
  }
}

class _TranslationHelper {
  final BuildContext context;
  
  _TranslationHelper(this.context);
  
  String call(String key, {Map<String, String>? namedArgs}) {
    return key.tr(namedArgs: namedArgs);
  }
}
```

---

## مثال 🔟: صفحة Settings احترافية

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          // ── Language Section ──
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(context.locale.languageCode == 'ar'
                ? 'العربية'
                : 'Türkçe'),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          
          // ── Current Language Info ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'current_language_info'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('language_code: ${context.locale.languageCode}'),
                    Text('country_code: ${context.locale.countryCode}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: context.supportedLocales.map((locale) {
            final isSelected = context.locale == locale;
            final name = locale.languageCode == 'ar' 
                ? 'العربية' 
                : 'Türkçe';
            
            return ListTile(
              title: Text(name),
              trailing: isSelected 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                context.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
```

---

## مثال 1️⃣1️⃣: شاشة كاملة احترافية (كل ميزات متقدمة)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/generated/locale_keys.g.dart';

class AdvancedHomePage extends ConsumerWidget {
  const AdvancedHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.app_title.tr()),  // ✅ Code generation
        actions: [
          PopupMenuButton<Locale>(
            onSelected: (locale) async {
              // ✅ حفظ الاختيار
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', locale.languageCode);
              
              context.setLocale(locale);
            },
            itemBuilder: (_) {
              return context.supportedLocales.map((locale) {
                return PopupMenuItem(
                  value: locale,
                  child: Text(locale.languageCode == 'ar' 
                      ? 'العربية' 
                      : 'Türkçe'),
                );
              }).toList();
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Prayer Card مع Named Args ──
            PrayerCard(
              prayerName: LocaleKeys.dhuhr.tr(),
              remainingTime: '02:30',
            ),
            
            // ── Report Card مع namedArgs ──
            ReportCard(
              count: 15,
              date: DateTime.now().toString().split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget يوضح namedArgs
class ReportCard extends StatelessWidget {
  final int count;
  final String date;

  const ReportCard({
    required this.count,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ namedArgs - واضح ومرن
            Text(
              LocaleKeys.daily_report.tr(
                namedArgs: {
                  'count': count.toString(),
                  'date': date,
                },
              ),
            ),
            const SizedBox(height: 8),
            
            // ✅ RTL/LTR صحيح
            Row(
              textDirection: Directionality.of(context),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${'times'.tr()}: $count'),
                const Icon(Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerCard extends StatelessWidget {
  final String prayerName;
  final String remainingTime;

  const PrayerCard({
    required this.prayerName,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(prayerName),
            Text(remainingTime),
          ],
        ),
      ),
    );
  }
}
```

---

## 📋 JSON Files المحدثة (مع namedArgs)

### ar-SA.json
```json
{
  "app_title": "صلة",
  "settings": "الإعدادات",
  "language": "اللغة",
  "language_code": "رمز اللغة",
  "country_code": "رمز الدولة",
  "current_language_info": "معلومات اللغة الحالية",
  "select_language": "اختر اللغة",
  "prayers": "مواقيت الصلاة",
  "dhuhr": "الظهر",
  "daily_report": "تقريرك اليومي: {date} - {count} عبادات",
  "times": "المرات",
  "gifts_count": "عدد الهدايا: {count}"
}
```

### tr-TR.json
```json
{
  "app_title": "Sıla",
  "settings": "Ayarlar",
  "language": "Dil",
  "language_code": "Dil Kodu",
  "country_code": "Ülke Kodu",
  "current_language_info": "Geçerli Dil Bilgileri",
  "select_language": "Dil Seçin",
  "prayers": "Namaz Vakitleri",
  "dhuhr": "Öğle",
  "daily_report": "{date} tarihinde {count} ibadet",
  "times": "Sayı",
  "gifts_count": "{count} hediye"
}
```

---

## ✅ Checklist - Production Ready

- ✅ Code generation مع LocaleKeys
- ✅ namedArgs بدل args
- ✅ RTL/LTR صحيح مع `textDirection`
- ✅ Dynamic language switcher
- ✅ Fallback translations
- ✅ Settings page للغة
- ✅ ConsumerWidget مع Riverpod
- ✅ حفظ الاختيار في SharedPreferences
- ✅ Lazy translation في widgets الثقيلة

---

## 🎯 النتيجة النهائية

**Production-Level Localization System** ✨

- 🔥 آمن (code generation)
- 🔥 سريع (lazy translation)
- 🔥 مرن (dynamic locales)
- 🔥 موثوق (fallback translations)
- 🔥 سهل الصيانة (namedArgs)

---

**الآن أنت جاهز لـ Senior-Level Implementation!** 🚀
