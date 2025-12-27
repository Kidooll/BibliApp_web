import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/features/auth/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(
        url: 'http://localhost',
        anonKey: 'test',
      );
    });

    testWidgets('deve exibir campos de email e senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('deve exibir botão de login', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Entrar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('deve exibir link para cadastro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('CRIAR'), findsOneWidget);
    });

    testWidgets('deve exibir link esqueci senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Esqueceu a Senha?'), findsOneWidget);
    });

    testWidgets('deve alternar visibilidade da senha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final visibilityButton = find.byIcon(Icons.visibility_off);

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

      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Email é obrigatório'), findsOneWidget);
      expect(find.text('Por favor, insira sua senha'), findsOneWidget);
    });
  });
}
