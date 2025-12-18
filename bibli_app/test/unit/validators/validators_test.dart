import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/validators/validators.dart';

void main() {
  group('EmailValidator', () {
    test('deve aceitar emails válidos', () {
      expect(EmailValidator.validate('test@example.com'), isNull);
      expect(EmailValidator.validate('user.name@domain.co.uk'), isNull);
      expect(EmailValidator.validate('test123@gmail.com'), isNull);
    });

    test('deve rejeitar emails inválidos', () {
      expect(EmailValidator.validate(''), isNotNull);
      expect(EmailValidator.validate('invalid'), isNotNull);
      expect(EmailValidator.validate('test@'), isNotNull);
      expect(EmailValidator.validate('@domain.com'), isNotNull);
      expect(EmailValidator.validate('test.domain.com'), isNotNull);
    });

    test('isValid deve retornar boolean correto', () {
      expect(EmailValidator.isValid('test@example.com'), isTrue);
      expect(EmailValidator.isValid('invalid'), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
    });
  });

  group('PasswordValidator', () {
    test('deve aceitar senhas fortes', () {
      expect(PasswordValidator.validate('MinhaSenh@123'), isNull);
      expect(PasswordValidator.validate('Teste123!'), isNull);
      expect(PasswordValidator.validate('Password1@'), isNull);
    });

    test('deve rejeitar senhas fracas', () {
      expect(PasswordValidator.validate(''), isNotNull);
      expect(PasswordValidator.validate('123'), isNotNull);
      expect(PasswordValidator.validate('password'), isNotNull);
      expect(PasswordValidator.validate('PASSWORD'), isNotNull);
      expect(PasswordValidator.validate('Password'), isNotNull);
      expect(PasswordValidator.validate('password123'), isNotNull);
      expect(PasswordValidator.validate('PASSWORD123'), isNotNull);
    });

    test('isStrong deve retornar boolean correto', () {
      expect(PasswordValidator.isStrong('MinhaSenh@123'), isTrue);
      expect(PasswordValidator.isStrong('password'), isFalse);
      expect(PasswordValidator.isStrong(''), isFalse);
    });

    test('deve exigir pelo menos 8 caracteres', () {
      expect(PasswordValidator.validate('Abc1@'), isNotNull);
      expect(PasswordValidator.validate('Abc123@a'), isNull);
    });

    test('deve exigir maiúscula, minúscula, número e especial', () {
      expect(PasswordValidator.validate('abcdefgh'), isNotNull); // sem maiúscula, número, especial
      expect(PasswordValidator.validate('ABCDEFGH'), isNotNull); // sem minúscula, número, especial
      expect(PasswordValidator.validate('Abcdefgh'), isNotNull); // sem número, especial
      expect(PasswordValidator.validate('Abcdefg1'), isNotNull); // sem especial
      expect(PasswordValidator.validate('Abcdefg@'), isNotNull); // sem número
    });
  });
}