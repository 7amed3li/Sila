# Sila | صلة

منصة إسلامية رقمية مبنية بـ Flutter لرفع جودة العبادة اليومية عبر تجربة حديثة، هادئة، وعملية.

`Sila` تركّز على أربع ركائز: القرآن، الصلاة، الأذكار، والحفظ/التسميع الذكي، مع بنية Offline-first ومتابعة يومية للمستخدم.

## Product Overview

- **Mission**: تحويل المداومة على العبادة من "مهمة متقطعة" إلى "رحلة يومية" واضحة وقابلة للقياس.
- **Audience**: المستخدم العربي (مع دعم التركية في أجزاء من التطبيق) الراغب في تجربة إسلامية متكاملة داخل تطبيق واحد.
- **Core Value**: تجربة روحانية + هندسة منتج عملية (تذكير، قياس، وتحسين تدريجي).

## Core Capabilities

### 1) Quran Experience
- قارئ قرآن بتصميم حديث ودعم تشغيل التلاوة لكل آية.
- إدارة القارئ (Reciter) مع تحميل/تخزين محلي وإدارة كاش الصوت.
- إعدادات قراءة مخصصة (الخط، الحجم، واجهة القراءة).

### 2) Smart Tasmi (التسميع الذكي)
- تقييم فوري للتلاوة مع تطبيع النص العربي والمقارنة الذكية.
- معالجة أخطاء STT ودمج أفضل بين الاستماع والتفاعل داخل الجلسة.
- شاشة نتائج واضحة تساعد المستخدم على معرفة نقاط القوة والتحسين.

### 3) Hifz (الحفظ)
- مسار Onboarding للحفظ وتوليد خطة يومية مبدئية.
- **Interactive Shadow** متعدد المراحل (استماع، ترديد، كتابة/اختبار).
- مقارنة الكلمات المخفية + تتبع الأداء + تسجيل لحظات إيمانية (Moments).
- إعدادات حفظ قابلة للتخصيص (الصرامة، عدد المحاولات، التلميحات، إلخ).

### 4) Prayer & Adhan
- جدولة تنبيهات الصلوات مع إدارة إعدادات الأذان لكل صلاة.
- اختبار صوت الأذان داخل التطبيق.
- تكامل مع نظام الإشعارات الذكية اليومي.

### 5) Azkar, Wird, Ibadah Tracking
- أذكار وورد يومي بتجربة متابعة مرئية.
- إشعارات سياقية وخطط تذكير يومية.
- تتبع نشاطات التعبد اليومية لرفع الاستمرارية.

## Architecture & Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (Codegen)
- **Persistence**: Isar (Local-first)
- **Audio**: just_audio + audioplayers
- **Notifications**: flutter_local_notifications
- **Speech**: speech_to_text
- **Localization**: easy_localization

## Repository Structure

```
.
├── sila_app/
│   ├── lib/
│   │   ├── core/                # Services, shared widgets, providers
│   │   ├── features/            # Feature-first modules (quran, hifz, tasmi...)
│   │   └── ...
│   ├── assets/                  # Fonts, audio, images
│   ├── scripts/                 # Automation scripts
│   └── pubspec.yaml
├── docs/                        # Documentation & guides
├── README.md                    # Project overview (this file)
├── LICENSE                      # MIT License
└── .gitignore
```

## Documentation

جميع ملفات التوثيق والأدلة موجودة في مجلد `docs/`:

### Implementation & Architecture
- `implementation_plan.md` - خطة التنفيذ الشاملة
- `IMPLEMENTATION_STEPS.md` - خطوات التنفيذ التفصيلية
- `IMPLEMENTATION_REPORT.md` - تقرير التنفيذ

### Audio System & Fixes
- `COMPLETE_AUDIO_ERROR_HANDLING.md` - نظام معالجة أخطاء الصوت الشامل
- `CONNECTION_ABORTED_COMPLETE_FIX.md` - حل مشكلة انقطاع الاتصال
- `CONNECTION_ABORTED_FIX.md` - تحليل وحل مفصل

### Localization & Language Support
- `README_LOCALIZATION.md` - دليل نظام التعريب
- `HOW_LOCALIZATION_WORKS.md` - شرح كيف يعمل التعريب
- `LANGUAGE_ADDITION_GUIDE.md` - دليل إضافة لغة جديدة
- `TURKISH_LOCALIZATION_COMPLETE.md` - دليل التركية
- `TURKISH_SUPPORT_STATUS.md` - حالة دعم اللغة التركية

### Best Practices & Guides
- `BEST_PRACTICES_GUIDE.md` - أفضل الممارسات البرمجية
- `PRACTICAL_EXAMPLES.md` - أمثلة عملية
- `PRODUCTION_LEVEL_EXAMPLES.md` - أمثلة على مستوى الإنتاج
- `QUICK_REFERENCE.txt` - مرجع سريع

### Analysis & Planning
- `COMPLETE_ANALYSIS_AND_PLAN.md` - تحليل شامل وخطة عمل
- `AUTO_PLAY_FIX_SUMMARY.md` - ملخص إصلاح التشغيل التلقائي
- `IMPROVEMENTS_SUMMARY.md` - ملخص التحسينات
- `LOCALIZATION_SUMMARY.md` - ملخص التعريب

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK (comes with Flutter)
- Android Studio / VS Code

### Local Run

```bash
git clone https://github.com/7amed3li/Sila.git
cd Sila/sila_app
flutter pub get
flutter run
```

### Quality Checks

```bash
cd sila_app
flutter analyze
flutter test
```

## Delivery & CI

- CI workflows موجودة لفحص الصياغة والتحليل والاختبارات.
- يوجد pre-push gate محلي ضمن السكربتات لضمان جودة الحد الأدنى قبل أي push.
- يدعم المشروع مسار إصدار مبني على tags للتحديثات.

## Roadmap (High-Level)

- استكمال طرق الحفظ المتقدمة (Smart Review / Repetition / Listening) بصفحات مخصصة.
- توسيع التخصيص في رحلات الحفظ والتسميع.
- تحسينات إضافية على الأداء وإدارة الوسائط على الأجهزة محدودة الموارد.

## License

هذا المشروع مرخص تحت رخصة MIT. انظر `LICENSE` للمزيد من التفاصيل.

## Contribution

- افتح Issue واضح مع خطوات إعادة إنتاج للمشكلات.
- استخدم فروع Feature قصيرة ووصف PR عملي ومباشر.
- مرّر `flutter analyze` و `flutter test` قبل طلب المراجعة.

## Dedication | إهداء وصدقة جارية

هذا العمل وقف لله تعالى وصدقة جارية عن أرواح:

- **صديقي وأخي/ محمود أحمد وهبة** (رحمه الله)
- **صديقي وأخي الدكتور/ محمود أحمد فرحات** (رحمه الله)
- **صديقي وأخي/ عبدالرحمن جمال** (رحمه الله)
- **خالي، وجدي، وجدتي** (غفر الله لهم)
- **وجميع موتانا المنسيين الذين انقطع عملهم ولا يجدون من يدعو لهم**

اللهم اجعل هذا العمل نورا وبشرى لهم في قبورهم، وثقّل به موازينهم، واجمعنا بهم في مستقر رحمتك.
