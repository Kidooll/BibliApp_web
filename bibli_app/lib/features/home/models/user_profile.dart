import 'package:bibli_app/core/constants/app_constants.dart';

class UserProfile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int totalDevotionalsRead;
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final int coins;
  final int weeklyGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.totalDevotionalsRead,
    required this.totalXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    required this.coins,
    required this.weeklyGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      totalDevotionalsRead: json['total_devotionals_read'] ?? 0,
      totalXp: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      xpToNextLevel:
          json['xp_to_next_level'] ?? LevelRequirements.initialXpToNextLevel,
      coins: json['coins'] ?? 0,
      weeklyGoal: json['weekly_goal'] ?? 7,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'total_devotionals_read': totalDevotionalsRead,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'xp_to_next_level': xpToNextLevel,
      'coins': coins,
      'weekly_goal': weeklyGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 
