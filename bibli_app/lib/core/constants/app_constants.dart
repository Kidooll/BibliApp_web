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
  static const devotionalRead = 8;
  static const dailyBonus = 5;
  static const chapterRead = 5;
  static const streak3Days = 15;
  static const streak7Days = 35;
  static const streak30Days = 150;
  static const missionCompleted = 10;
  static const achievementUnlocked = 20;
  static const shareQuote = 5;
}

class LevelRequirements {
  // Níveis conforme PRD
  static const level1 = 0;     // Novato na Fé (0-100)
  static const level2 = 101;   // Buscador (101-250)
  static const level3 = 251;   // Discípulo (251-500)
  static const level4 = 501;   // Servo Fiel (501-800)
  static const level5 = 801;   // Estudioso (801-1200)
  static const level6 = 1201;  // Sábio (1201-1700)
  static const level7 = 1701;  // Mestre (1701-2300)
  static const level8 = 2301;  // Líder Espiritual (2301-3000)
  static const level9 = 3001;  // Mentor (3001-4000)
  static const level10 = 4001; // Gigante da Fé (4001+)
  
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
  static const initialXpToNextLevel = 100;
  static const defaultXpToNextLevel = 200;
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
