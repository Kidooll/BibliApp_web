import 'dart:convert';
import 'dart:io';

/// Gera um script SQL (stdout) para popular:
/// - reading_plans (title/description/duration_days)
/// - reading_plan_items (book_name/chapter_number/day_number)
///
/// Lê todos os JSONs em `bibli_app/assets/reading_plans`.
/// Uso:
///   dart supabase/reading_plans/generate_seed_from_assets.dart \
///     > supabase/reading_plans/seed_from_assets.sql
/// Depois execute o SQL gerado no Supabase (SQL editor ou psql).
void main() async {
  final assetsDir = Directory(
    '${Directory.current.path}/bibli_app/assets/reading_plans',
  );
  if (!assetsDir.existsSync()) {
    stderr.writeln('Pasta de assets não encontrada: ${assetsDir.path}');
    exit(1);
  }

  final files = assetsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer()
    ..writeln('-- Gerado automaticamente a partir dos assets de planos')
    ..writeln('-- Data: ${DateTime.now().toIso8601String()}')
    ..writeln('begin;');

  for (final file in files) {
    final content = await file.readAsString();
    final map = json.decode(content) as Map<String, dynamic>;
    final title = _escape(map['title'] ?? 'Plano sem título');
    final description = _escape(map['description'] ?? '');
    final duration = (map['duration_days'] as num?)?.toInt() ?? 0;

    buffer
      ..writeln('\n-- $title')
      ..writeln(
          "insert into reading_plans (title, description, duration_days) values ('$title', '$description', $duration)")
      ..writeln(
          "on conflict(title) do update set description = excluded.description, duration_days = excluded.duration_days, updated_at = now();")
      ..writeln(
          "delete from reading_plan_items where reading_plan_id = (select id from reading_plans where title = '$title');");

    final chapters = (map['chapters'] as List<dynamic>? ?? []);
    final values = <String>[];

    for (final entry in chapters) {
      final e = entry as Map<String, dynamic>;
      final day = (e['dia'] as num?)?.toInt();
      final bookName = _escape(e['book_name'] ?? '');
      final start = (e['chapter_start'] as num?)?.toInt();
      final end = (e['chapter_end'] as num?)?.toInt() ?? start;
      if (day == null || bookName.isEmpty || start == null) continue;
      for (var chapter = start; chapter <= (end ?? start); chapter++) {
        values.add(
          "((select id from reading_plans where title = '$title'), $day, '$bookName', $chapter, now(), now())",
        );
      }
    }

    if (values.isNotEmpty) {
      buffer
        ..writeln('insert into reading_plan_items')
        ..writeln(
            '(reading_plan_id, day_number, book_name, chapter_number, created_at, updated_at)')
        ..writeln('values')
        ..writeln(values.join(',\n') + ';');
    }
  }

  buffer.writeln('commit;');
  stdout.write(buffer.toString());
}

String _escape(String value) => value.replaceAll("'", "''");