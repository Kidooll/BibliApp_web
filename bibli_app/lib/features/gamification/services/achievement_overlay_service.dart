import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../widgets/achievement_notification.dart';

class AchievementOverlayService {
  static OverlayEntry? _currentOverlay;

  static void showAchievementNotification(
    BuildContext context,
    Achievement achievement,
  ) {
    // Remove overlay anterior se existir
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: AchievementNotification(
          achievement: achievement,
          onDismiss: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void showMultipleAchievements(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    if (achievements.isEmpty) return;
    
    // Mostra uma por vez com delay
    for (int i = 0; i < achievements.length; i++) {
      Future.delayed(Duration(milliseconds: i * 1000), () {
        if (context.mounted) {
          showAchievementNotification(context, achievements[i]);
        }
      });
    }
  }

  static void dispose() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}