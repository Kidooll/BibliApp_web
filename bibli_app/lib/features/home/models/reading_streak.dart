class ReadingStreak {
  final int id;
  final DateTime? lastActiveDate;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userProfileId;

  ReadingStreak({
    required this.id,
    this.lastActiveDate,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.createdAt,
    required this.updatedAt,
    required this.userProfileId,
  });

  factory ReadingStreak.fromJson(Map<String, dynamic> json) {
    return ReadingStreak(
      id: json['id'],
      lastActiveDate: json['last_active_date'] != null 
          ? DateTime.parse(json['last_active_date']) 
          : null,
      currentStreakDays: json['current_streak_days'] ?? 0,
      longestStreakDays: json['longest_streak_days'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userProfileId: json['user_profile_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_active_date': lastActiveDate?.toIso8601String(),
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_profile_id': userProfileId,
    };
  }
} 