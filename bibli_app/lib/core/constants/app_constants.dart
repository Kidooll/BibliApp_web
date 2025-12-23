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
  static const level2 = 150;    // Buscador (150-375)
  static const level3 = 375;    // Discípulo (375-750)
  static const level4 = 750;    // Servo Fiel (750-1200)
  static const level5 = 1200;   // Estudioso (1200-1800)
  static const level6 = 1800;   // Sábio (1800-2550)
  static const level7 = 2550;   // Mestre (2550-3450)
  static const level8 = 3450;   // Líder Espiritual (3450-4500)
  static const level9 = 4500;   // Mentor (4500-6000)
  static const level10 = 6000;  // Gigante da Fé (6000+)
  
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
