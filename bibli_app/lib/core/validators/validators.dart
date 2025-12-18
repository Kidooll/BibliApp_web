class EmailValidator {
  static final _regex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }

    final trimmed = email.trim();

    if (!_regex.hasMatch(trimmed)) {
      return 'Email inválido';
    }

    if (trimmed.length > 254) {
      return 'Email muito longo';
    }

    return null;
  }

  static bool isValid(String email) {
    return validate(email) == null;
  }
}

class PasswordValidator {
  static const int minLength = 8;

  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (password.length < minLength) {
      return 'Senha deve ter pelo menos $minLength caracteres';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Senha deve conter pelo menos uma letra minúscula';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Senha deve conter pelo menos um número';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Senha deve conter pelo menos um caractere especial';
    }

    return null;
  }

  static bool isStrong(String password) {
    return validate(password) == null;
  }
}
