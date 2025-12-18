import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/validators/validators.dart';

void main() {
  group('EmailValidator', () {
    test('deve retornar null para email válido', () {
      expect(EmailValidator.validate('test@example.com'), null);
      expect(EmailValidator.validate('user.name+tag@domain.co.uk'), null);
      expect(EmailValidator.validate('test123@test-domain.com'), null);
    });

    test('deve retornar erro para email inválido', () {
      expect(EmailValidator.validate(''), isNotNull);
      expect(EmailValidator.validate('invalid'), isNotNull);
      expect(EmailValidator.validate('test@'), isNotNull);
      expect(EmailValidator.validate('@domain.com'), isNotNull);
      expect(EmailValidator.validate('test.domain.com'), isNotNull);
    });

    test('deve retornar erro para null', () {
      expect(EmailValidator.validate(null), isNotNull);
    });
  });

  group('PasswordValidator', () {
    test('deve retornar null para senha válida', () {
      expect(PasswordValidator.validate('Test123!'), null);
      expect(PasswordValidator.validate('MyPass@123'), null);
      expect(PasswordValidator.validate('Secure#Pass1'), null);
    });

    test('deve retornar erro para senha muito curta', () {
      expect(PasswordValidator.validate('Test1!'), isNotNull);
      expect(PasswordValidator.validate('123'), isNotNull);
    });

    test('deve retornar erro para senha sem maiúscula', () {
      expect(PasswordValidator.validate('test123!'), isNotNull);
    });

    test('deve retornar erro para senha sem minúscula', () {
      expect(PasswordValidator.validate('TEST123!'), isNotNull);
    });

    test('deve retornar erro para senha sem número', () {
      expect(PasswordValidator.validate('TestPass!'), isNotNull);
    });

    test('deve retornar erro para senha sem caractere especial', () {
      expect(PasswordValidator.validate('TestPass123'), isNotNull);
    });

    test('deve retornar erro para null ou vazio', () {
      expect(PasswordValidator.validate(null), isNotNull);
      expect(PasswordValidator.validate(''), isNotNull);
    });
  });
}