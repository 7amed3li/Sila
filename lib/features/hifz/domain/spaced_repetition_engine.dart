class ReviewSchedule {
  const ReviewSchedule({
    required this.nextIntervalDays,
    required this.newEasinessFactor,
    required this.nextReviewDate,
  });
  final int nextIntervalDays;
  final double newEasinessFactor;
  final DateTime nextReviewDate;
}

class SpacedRepetitionEngine {
  static ReviewSchedule calculateNext({
    required int currentIntervalDays,
    required double easinessFactor,
    required int quality,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final q = quality.clamp(0, 5);

    var newEf = easinessFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEf < 1.3) {
      newEf = 1.3;
    }

    late final int nextInterval;
    if (q < 3) {
      nextInterval = 1;
    } else if (currentIntervalDays == 1) {
      nextInterval = 6;
    } else {
      nextInterval = (currentIntervalDays * newEf).round();
    }

    return ReviewSchedule(
      nextIntervalDays: nextInterval,
      newEasinessFactor: newEf,
      nextReviewDate: now.add(Duration(days: nextInterval)),
    );
  }
}
