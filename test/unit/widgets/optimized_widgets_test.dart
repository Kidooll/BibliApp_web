import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibli_app/core/widgets/loading_states.dart';
import 'package:bibli_app/core/widgets/optimized_list.dart';

void main() {
  group('Optimized Widgets Tests', () {
    testWidgets('LoadingWidget deve renderizar corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'Carregando...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando...'), findsOneWidget);
    });

    testWidgets('EmptyStateWidget deve renderizar corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Nenhum item encontrado',
              icon: Icons.search,
            ),
          ),
        ),
      );

      expect(find.text('Nenhum item encontrado'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('OptimizedListView deve renderizar lista', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedListView<String>(
              items: items,
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });
}