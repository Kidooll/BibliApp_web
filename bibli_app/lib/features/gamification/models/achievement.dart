class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final AchievementType type;
  final int targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.type,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      xpReward: xpReward,
      type: type,
      targetValue: targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'xpReward': xpReward,
      'type': type.name,
      'targetValue': targetValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      xpReward: json['xpReward'] as int? ?? 0,
      type: AchievementType.values.byName(json['type'] as String? ?? 'special'),
      targetValue: json['targetValue'] as int? ?? 1,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String) 
          : null,
    );
  }
}

enum AchievementType {
  streak,
  totalXp,
  devotionalCount,
  firstTime,
  special,
}