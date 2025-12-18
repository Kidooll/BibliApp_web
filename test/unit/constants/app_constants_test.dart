import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

void main() {
  group('AppColors', () {
    test('deve ter cores corretas definidas', () {
      expect(AppColors.primary, const Color(0xFF005954));
      expect(AppColors.complementary, const Color(0xFF338b85));
      expect(AppColors.background, const Color(0xFFFFFFFF));
    });
  });

  group('XpValues', () {
    test('deve ter valores de XP corretos', () {
      expect(XpValues.devotionalRead, 8);
      expect(XpValues.dailyBonus, 5);
      expect(XpValues.streak3Days, 15);
      expect(XpValues.streak7Days, 35);
    });
  });

  group('AppDimensions', () {
    test('deve ter dimensões corretas', () {
      expect(AppDimensions.paddingSmall, 8.0);
      expect(AppDimensions.paddingMedium, 16.0);
      expect(AppDimensions.paddingLarge, 24.0);
      expect(AppDimensions.borderRadius, 12.0);
    });
  });

  group('LevelRequirements', () {
    test('deve ter requirements array válido', () {
      expect(LevelRequirements.requirements, isA<List<int>>());
      expect(LevelRequirements.requirements.length, greaterThan(0));
      expect(LevelRequirements.requirements.first, 0);
    });

    test('deve ter valores corretos para cada nível', () {
      expect(LevelRequirements.level1, 0);
      expect(LevelRequirements.level2, 150);
      expect(LevelRequirements.level3, 400);
      expect(LevelRequirements.level4, 750);
      expect(LevelRequirements.level5, 1200);
    });

    test('deve ter valores padrão corretos', () {
      expect(LevelRequirements.defaultXpToNextLevel, 200);
      expect(LevelRequirements.initialXpToNextLevel, 100);
    });
  });

  group('HttpStatusCodes', () {
    test('deve ter códigos HTTP corretos', () {
      expect(HttpStatusCodes.ok, 200);
      expect(HttpStatusCodes.created, 201);
      expect(HttpStatusCodes.badRequest, 400);
      expect(HttpStatusCodes.unauthorized, 401);
      expect(HttpStatusCodes.notFound, 404);
      expect(HttpStatusCodes.serverError, 500);
    });
  });
}