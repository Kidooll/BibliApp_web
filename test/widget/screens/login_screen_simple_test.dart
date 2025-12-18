import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: LoginScreen(),
      );
    }

    testWidgets('deve renderizar elementos básicos da tela', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verificar se elementos essenciais estão presentes
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('deve ter campos de email e senha', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Procurar por hints ou labels relacionados
      expect(find.textContaining('mail'), findsAtLeastNWidgets(1));
      expect(find.textContaining('senha'), findsAtLeastNWidgets(1));
    });

    testWidgets('deve ter botão de submit', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verificar se há botão para submeter
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsAtLeastNWidgets(1));
    });

    testWidgets('deve permitir entrada de texto nos campos', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(2));

      // Testar se consegue inserir texto
      await tester.enterText(textFields.first, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}