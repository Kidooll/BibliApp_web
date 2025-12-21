class ReadingPlan {
  final int id;
  final String title;
  final String description;
  final int duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration_days'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ReadingProgress {
  final int planId;
  final int totalDays;
  final Set<int> completedDays;
  final DateTime? rewardClaimedAt;

  ReadingProgress({
    required this.planId,
    required this.totalDays,
    required this.completedDays,
    this.rewardClaimedAt,
  });

  int get completedCount => completedDays.length;

  int get currentDay =>
      (completedCount + 1).clamp(1, totalDays == 0 ? 1 : totalDays);

  double get percentage =>
      totalDays == 0 ? 0.0 : (completedCount / totalDays) * 100;

  bool isDayCompleted(int day) => completedDays.contains(day);
  bool get rewardClaimed => rewardClaimedAt != null;

  factory ReadingProgress.fromRows(
    List<dynamic> rows, {
    required int planId,
    required int totalDays,
    DateTime? rewardClaimedAt,
  }) {
    final completed = <int>{};
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final completedFlag = map['completed'] == true;
      final dayNumber = (map['day_number'] as num?)?.toInt();
      if (completedFlag && dayNumber != null) {
        completed.add(dayNumber);
      }
    }
    return ReadingProgress(
      planId: planId,
      totalDays: totalDays,
      completedDays: completed,
      rewardClaimedAt: rewardClaimedAt,
    );
  }
}

class ReadingPlanNextChapter {
  final int planId;
  final int dayNumber;
  final int? bookId;
  final String bookName;
  final int chapterNumber;

  ReadingPlanNextChapter({
    required this.planId,
    required this.dayNumber,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
  });
}
