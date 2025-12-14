class UserStats {
  final int id;
  final String userId;
  final int totalDevotionalsRead;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalHighlights;
  final int chaptersReadCount;
  final DateTime? lastActivityDate;
  final DateTime lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStats({
    required this.id,
    required this.userId,
    required this.totalDevotionalsRead,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalHighlights,
    required this.chaptersReadCount,
    this.lastActivityDate,
    required this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'],
      userId: json['user_id'],
      totalDevotionalsRead: json['total_devotionals_read'],
      currentStreakDays: json['current_streak_days'],
      longestStreakDays: json['longest_streak_days'],
      totalHighlights: json['total_highlights'],
      chaptersReadCount: json['chapters_read_count'],
      lastActivityDate: json['last_activity_date'] != null 
          ? DateTime.parse(json['last_activity_date']) 
          : null,
      lastSyncAt: DateTime.parse(json['last_sync_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_devotionals_read': totalDevotionalsRead,
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'total_highlights': totalHighlights,
      'chapters_read_count': chaptersReadCount,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'last_sync_at': lastSyncAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserStats copyWith({
    int? totalDevotionalsRead,
    int? currentStreakDays,
    int? longestStreakDays,
    int? totalHighlights,
    int? chaptersReadCount,
    DateTime? lastActivityDate,
    DateTime? lastSyncAt,
  }) {
    return UserStats(
      id: id,
      userId: userId,
      totalDevotionalsRead: totalDevotionalsRead ?? this.totalDevotionalsRead,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      totalHighlights: totalHighlights ?? this.totalHighlights,
      chaptersReadCount: chaptersReadCount ?? this.chaptersReadCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
