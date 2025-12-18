import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bibli_app/features/auth/screens/login_screen.dart';
import 'package:bibli_app/core/constants/app_strings.dart';
import '../../mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: LoginScreen(),
      );
    }

    testWidgets('deve renderizar todos os elementos da tela', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('deve mostrar erro para email inválido', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'email-invalido');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Assert
      expect(find.text(AppStrings.invalidEmail), findsOneWidget);
    });

    testWidgets('deve mostrar erro para senha inválida', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Assert
      expect(find.text(AppStrings.weakPassword), findsOneWidget);
    });

    testWidgets('deve alternar visibilidade da senha', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      final passwordField = find.byKey(const Key('password_field'));

      // Act - Senha deve estar oculta inicialmente
      TextFormField initialField = tester.widget(passwordField);
      expect(initialField.obscureText, isTrue);

      // Tap no ícone de visibilidade
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Assert - Senha deve estar visível
      TextFormField updatedField = tester.widget(passwordField);
      expect(updatedField.obscureText, isFalse);
    });

    testWidgets('deve navegar para signup quando link clicado', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      // Assert
      // Verificar se navegou (implementar quando SignupScreen estiver pronto)
    });

    testWidgets('deve mostrar loading durante login', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Test123!');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}