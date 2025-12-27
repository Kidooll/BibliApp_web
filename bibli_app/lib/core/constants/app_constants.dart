import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF005954);
  static const complementary = Color(0xFF338b85);
  static const analogous = Color(0xFF5dc1b9);
  static const triadic = Color(0xFF9ce0db);
  static const tetradic = Color(0xFFFFFFFF);
  
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecondary = Colors.grey;
}

class XpValues {
  // Dificuldade 3x: reduzimos os ganhos aproximando para inteiros
  static const devotionalRead = 3;       // era 8
  static const dailyBonus = 2;           // era 5
  static const chapterRead = 2;          // era 5
  static const streak3Days = 5;          // era 15
  static const streak7Days = 12;         // era 35
  static const streak30Days = 50;        // era 150
  static const missionCompleted = 3;     // era 10
  static const achievementUnlocked = 7;  // era 20
  static const shareQuote = 2;           // era 5
}

class LevelRequirements {
  // Níveis conforme PRD (ajustados +50% para aumentar dificuldade)
  static const level1 = 0;      // Novato na Fé (0-150)
  static const level2 = 450;    // Buscador (450-1349)
  static const level3 = 1350;   // Discípulo (1350-2699)
  static const level4 = 2700;   // Servo Fiel (2700-4499)
  static const level5 = 4500;   // Estudioso (4500-6749)
  static const level6 = 6750;   // Sábio (6750-9449)
  static const level7 = 9450;   // Mestre (9450-12599)
  static const level8 = 12600;  // Líder Espiritual (12600-16199)
  static const level9 = 16200;  // Mentor (16200-20249)
  static const level10 = 20250; // Gigante da Fé (20250+)
  
  static const requirements = [
    level1, level2, level3, level4, level5,
    level6, level7, level8, level9, level10,
  ];
  
  // Nomes dos níveis
  static const levelNames = [
    'Novato na Fé',
    'Buscador', 
    'Discípulo',
    'Servo Fiel',
    'Estudioso',
    'Sábio',
    'Mestre',
    'Líder Espiritual',
    'Mentor',
    'Gigante da Fé',
  ];
  
  // Constantes para compatibilidade
  static const initialXpToNextLevel = level2;
  static const defaultXpToNextLevel = 900;
}

class HttpStatusCodes {
  static const ok = 200;
  static const created = 201;
  static const badRequest = 400;
  static const unauthorized = 401;
  static const notFound = 404;
  static const serverError = 500;
}

class AppDimensions {
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
  static const paddingXLarge = 32.0;
  static const borderRadius = 12.0;
  static const borderRadiusLarge = 16.0;
}

class ReminderDefaults {
  static const hour = 8;
  static const minute = 0;
  static const time = TimeOfDay(hour: hour, minute: minute);
}

class ReadingPlanRewards {
  static int xpForDuration(int duration) {
    if (duration <= 14) return 100;
    if (duration <= 30) return 150;
    if (duration <= 40) return 175;
    if (duration <= 60) return 200;
    if (duration <= 90) return 250;
    return 300;
  }

  static int talentsForXp(int xp) {
    if (xp <= 110) return 5;
    if (xp <= 160) return 7;
    if (xp <= 190) return 9;
    if (xp <= 230) return 11;
    return 15;
  }
}

class ChallengeTypes {
  static const reading = 'reading';
  static const devotionals = 'devotionals';
  static const sharing = 'sharing';
  static const note = 'note';
  static const favorite = 'favorite';
  static const plan = 'plan';
  static const study = 'study';
  static const goal = 'goal';

  // Legacy/compat
  static const legacyReadingTypo = 'lreading';
  static const legacyShare = 'share';
  static const legacyDevotional = 'devotional';
}
