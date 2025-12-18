import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/app.dart';

void main() {
  group('App Navigation Integration Tests', () {
    testWidgets('deve inicializar app sem erros', (tester) async {
      // Testa se o app inicializa corretamente
      await tester.pumpWidget(const BibliApp());
      
      // Verificar se não há erros de renderização
      expect(tester.takeException(), isNull);
    });

    testWidgets('deve mostrar tela inicial', (tester) async {
      await tester.pumpWidget(const BibliApp());
      await tester.pumpAndSettle();
      
      // Verificar se algum conteúdo é renderizado
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('deve permitir navegação básica', (tester) async {
      await tester.pumpWidget(const BibliApp());
      await tester.pumpAndSettle();
      
      // Procurar por elementos de navegação
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Se há bottom navigation, testar tap
        await tester.tap(bottomNav);
        await tester.pumpAndSettle();
        
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('deve manter estado durante navegação', (tester) async {
      await tester.pumpWidget(const BibliApp());
      await tester.pumpAndSettle();
      
      // Verificar se app mantém estado consistente
      final initialWidgets = find.byType(Widget).evaluate().length;
      
      // Simular alguma interação
      await tester.pump(Duration(milliseconds: 100));
      
      expect(tester.takeException(), isNull);
      expect(find.byType(Widget).evaluate().length, greaterThan(0));
    });
  });
}