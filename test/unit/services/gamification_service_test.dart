import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

void main() {
  group('Gamification Logic Tests', () {
    test('deve calcular XP corretamente', () {
      // Testa valores de XP definidos nas constantes
      expect(XpValues.devotionalRead, 8);
      expect(XpValues.dailyBonus, 5);
      expect(XpValues.streak3Days, 15);
      expect(XpValues.streak7Days, 35);
    });

    test('deve ter níveis progressivos', () {
      final levels = LevelRequirements.requirements;
      
      // Verificar se níveis são progressivos
      for (int i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
    });

    test('deve calcular progresso de nível', () {
      const currentXp = 100;
      const level1Requirement = LevelRequirements.level1;
      const level2Requirement = LevelRequirements.level2;
      
      // Usuário com 100 XP deve estar no nível 1
      expect(currentXp, greaterThanOrEqualTo(level1Requirement));
      expect(currentXp, lessThan(level2Requirement));
    });

    test('deve validar valores de XP positivos', () {
      expect(XpValues.devotionalRead, greaterThan(0));
      expect(XpValues.dailyBonus, greaterThan(0));
      expect(XpValues.streak3Days, greaterThan(0));
      expect(XpValues.streak7Days, greaterThan(0));
    });

    test('deve ter streak crescente', () {
      expect(XpValues.streak7Days, greaterThan(XpValues.streak3Days));
      expect(XpValues.streak3Days, greaterThan(XpValues.dailyBonus));
    });
  });
}