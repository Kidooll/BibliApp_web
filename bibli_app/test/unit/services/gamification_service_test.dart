import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

void main() {
  group('LevelRequirements', () {
    test('deve ter 10 níveis conforme PRD', () {
      expect(LevelRequirements.requirements.length, equals(10)); // 10 níveis
    });

    test('deve seguir progressão correta do PRD', () {
      expect(LevelRequirements.requirements[0], equals(0));    // Nível 1: 0-100
      expect(LevelRequirements.requirements[1], equals(101));  // Nível 2: 101-250
      expect(LevelRequirements.requirements[2], equals(251));  // Nível 3: 251-500
      expect(LevelRequirements.requirements[3], equals(501));  // Nível 4: 501-800
      expect(LevelRequirements.requirements[4], equals(801));  // Nível 5: 801-1200
      expect(LevelRequirements.requirements[5], equals(1201)); // Nível 6: 1201-1700
      expect(LevelRequirements.requirements[6], equals(1701)); // Nível 7: 1701-2300
      expect(LevelRequirements.requirements[7], equals(2301)); // Nível 8: 2301-3000
      expect(LevelRequirements.requirements[8], equals(3001)); // Nível 9: 3001-4000
      expect(LevelRequirements.requirements[9], equals(4001)); // Nível 10: 4001+
    });

    test('deve ter progressão crescente', () {
      for (int i = 1; i < LevelRequirements.requirements.length; i++) {
        expect(
          LevelRequirements.requirements[i],
          greaterThan(LevelRequirements.requirements[i - 1]),
          reason: 'Nível $i deve ter mais XP que nível ${i - 1}',
        );
      }
    });

    test('deve ter defaultXpToNextLevel positivo', () {
      expect(LevelRequirements.defaultXpToNextLevel, greaterThan(0));
    });
  });

  group('XpValues', () {
    test('deve ter valores corretos conforme PRD', () {
      expect(XpValues.devotionalRead, equals(8));
      expect(XpValues.dailyBonus, equals(5));
      expect(XpValues.streak3Days, equals(15));
      expect(XpValues.streak7Days, equals(35));
    });

    test('valores devem ser positivos', () {
      expect(XpValues.devotionalRead, greaterThan(0));
      expect(XpValues.dailyBonus, greaterThan(0));
      expect(XpValues.streak3Days, greaterThan(0));
      expect(XpValues.streak7Days, greaterThan(0));
    });

    test('streak 7 dias deve dar mais XP que 3 dias', () {
      expect(XpValues.streak7Days, greaterThan(XpValues.streak3Days));
    });
  });

  group('AppColors', () {
    test('deve ter cores primárias definidas', () {
      expect(AppColors.primary.value, equals(0xFF005954));
      expect(AppColors.complementary.value, equals(0xFF338b85));
    });
  });
}