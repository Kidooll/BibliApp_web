class Achievement {
  final int id;
  final String achievementCode;
  final String title;
  final String description;
  final String? iconName;
  final int xpReward;
  final String requirementType;
  final int requirementValue;
  final bool isActive;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.achievementCode,
    required this.title,
    required this.description,
    this.iconName,
    required this.xpReward,
    required this.requirementType,
    required this.requirementValue,
    required this.isActive,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      achievementCode: json['achievement_code'],
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
      xpReward: json['xp_reward'],
      requirementType: json['requirement_type'],
      requirementValue: json['requirement_value'],
      isActive: json['is_active'],
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievement_code': achievementCode,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'xp_reward': xpReward,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'is_active': isActive,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({
    int? id,
    String? achievementCode,
    String? title,
    String? description,
    String? iconName,
    int? xpReward,
    String? requirementType,
    int? requirementValue,
    bool? isActive,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      achievementCode: achievementCode ?? this.achievementCode,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      xpReward: xpReward ?? this.xpReward,
      requirementType: requirementType ?? this.requirementType,
      requirementValue: requirementValue ?? this.requirementValue,
      isActive: isActive ?? this.isActive,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
