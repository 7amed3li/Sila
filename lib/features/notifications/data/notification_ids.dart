class NotificationIds {
  NotificationIds._();

  static const int fajr = 1;
  static const int dhuhr = 2;
  static const int asr = 3;
  static const int maghrib = 4;
  static const int isha = 5;

  static const int azkarSabah = 100;
  static const int azkarSabahUrgent = 101;
  static const int azkarMasa = 102;
  static const int azkarMasaUrgent = 103;
  static const int wird = 104;
  static const int hifz = 105;
  static const int tasmi = 106;
  static const int tasbih = 107;
  static const int goldenFajr = 108;
  static const int fridaySpecial = 109;
  static const int streakMilestone = 110;
  static const int salahPreFajr = 111;
  static const int salahPreDhuhr = 112;
  static const int salahPreAsr = 113;
  static const int salahPreMaghrib = 114;
  static const int salahPreIsha = 115;
  static const int fridayKahf = 116;
  static const int fridaySalawatA = 117;
  static const int fridaySalawatB = 118;
  static const int fridayResponseHour = 119;
  static const int dailyReport = 120;

  // Daily Smart Slots
  static const int dailySlot1 = 201; // After Fajr (Azkar Sabah)
  static const int dailySlot2 = 202; // 09:00
  static const int dailySlot3 = 203; // 12:00
  static const int dailySlot4 = 204; // 15:00
  static const int dailySlot5 = 205; // 17:00
  static const int dailySlot6 = 206; // After Asr (Azkar Masa)

  // ─── Centralized Hardcoded IDs ──────────────────────────────
  static const int hifzReminderFixedId = 7001;
  static const int downloadServiceFixedId = 9000;
  static const int adhanPlaybackFixedId = 9090;
  static const int testNotificationFixedId = 9901;
  static const int testNotificationStandaloneId = 9902;
  static const int postPrayerDhuhrFixedId = 9002;
  static const int reEngagementFixedId = 9999;

  // ─── Dynamic Offsets & Formulas ────────────────────────────
  /// صياغة (Formula): ID الخاص بالصلاة + 10000
  /// مثال: الفجر (1) = 10001
  static const int prayerReminderOffset = 10000;

  /// صياغة (Formula): 9100 + index (من 0 إلى 4 لـ 5 صلوات)
  /// مثال: الفجر (Index 0) = 9100, الظهر (Index 1) = 9101
  static const int smartPrayerActionOffset = 9100;

  /// صياغة (Formula): 2000 + User Setting ID
  /// مثال: التذكير رقم 5 = 2005
  static const int userCustomDailyOffset = 2000;

  // ─── Reserved Empty Ranges (For Future Use) ─────────────────
  // تم تخصيص هذه الجداول للإضافات المستقبلية لضمان عدم التداخل:
  // - 7002 مخصص لـ Hifz/Tasmi الإضافي.
  // - 9001, 9003 إلى 9089: مخصصة للتحديثات الخلفية والتنبيهات النظامية الجديدة.
  // - 9091 إلى 9099: مخصصة لأصوات الخلفية ومزايا التلاوة الصوتية المتزامنة.
  // - 9105 إلى 9899: مخصصة للعبادات الإضافية والمناسبات (رمضان/عشر ذي الحجة).
  // - 10006 فما فوق: مخصصة للتذكيرات القبلية للإيفنتات الخاصة.
}
