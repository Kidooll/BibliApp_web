class Level {
  final int id;
  final int levelNumber;
  final String levelName;
  final int xpRequired;
  final String description;
  final String? badgeIcon;

  Level({
    required this.id,
    required this.levelNumber,
    required this.levelName,
    required this.xpRequired,
    required this.description,
    this.badgeIcon,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      levelNumber: json['level_number'],
      levelName: json['level_name'],
      xpRequired: json['xp_required'],
      description: json['description'],
      badgeIcon: json['badge_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_number': levelNumber,
      'level_name': levelName,
      'xp_required': xpRequired,
      'description': description,
      'badge_icon': badgeIcon,
    };
  }
}
