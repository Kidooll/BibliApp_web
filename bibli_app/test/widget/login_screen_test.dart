import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('deve exibir campos de email e senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('deve exibir botão de login', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('ENTRAR'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('deve exibir link para cadastro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Não tem uma conta?'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('deve exibir link esqueci senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Esqueci minha senha'), findsOneWidget);
    });

    testWidgets('deve alternar visibilidade da senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final passwordField = find.byKey(const Key('password_field'));
      final visibilityButton = find.byIcon(Icons.visibility_off);

      expect(passwordField, findsOneWidget);
      expect(visibilityButton, findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('deve validar campos obrigatórios', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final loginButton = find.text('ENTRAR');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Por favor insira seu email'), findsOneWidget);
      expect(find.text('Por favor insira sua senha'), findsOneWidget);
    });
  });
}