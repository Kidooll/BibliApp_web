import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';
import 'package:bibli_app/core/validators/validators.dart';
import 'package:bibli_app/core/constants/app_strings.dart';

void main() {
  group('AuthService Logic Tests', () {
    test('deve validar email antes de processar', () {
      // Testa a lógica de validação sem dependências externas
      const invalidEmail = 'invalid-email';
      const validEmail = 'test@example.com';
      
      expect(EmailValidator.validate(invalidEmail), isNotNull);
      expect(EmailValidator.validate(validEmail), isNull);
    });

    test('deve validar senha antes de processar', () {
      const weakPassword = '123';
      const strongPassword = 'Test123!';
      
      expect(PasswordValidator.validate(weakPassword), isNotNull);
      expect(PasswordValidator.validate(strongPassword), isNull);
    });

    test('deve ter mensagens de erro apropriadas', () {
      expect(AppStrings.errorEmailInvalid, isNotEmpty);
      expect(AppStrings.errorPasswordWeak, isNotEmpty);
      expect(AppStrings.errorAuth, isNotEmpty);
    });

    test('deve validar parâmetros obrigatórios', () {
      expect(EmailValidator.validate(''), isNotNull);
      expect(PasswordValidator.validate(''), isNotNull);
    });
  });
}