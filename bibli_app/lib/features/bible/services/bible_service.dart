import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bibli_app/core/constants/app_constants.dart';

class BibleService {
  static const String _base = 'https://bolls.life';

  static const Map<String, String> translations = {
    'NVIPT': 'NVIPT',
    'NAA': 'NAA',
    'NTLH': 'NTLH',
  };

  // Utilitário simples para limpar HTML retornado pela API
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<List<Map<String, dynamic>>> getBooks(String translation) async {
    final t = translations[translation] ?? 'NVIPT';
    final uri = Uri.parse('$_base/get-books/$t/');
    final res = await http.get(uri);
    if (res.statusCode != HttpStatusCodes.ok) return [];
    final List data = json.decode(res.body) as List;

    // A resposta contém: bookid, chronorder, name, chapters
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final int id = (m['bookid'] as num).toInt();
      final String name = (m['name'] ?? '').toString();
      final int chapters = (m['chapters'] as num).toInt();
      final String testament = id <= 39 ? 'OT' : 'NT'; // heuristic
      return {
        'id': id,
        'name': name,
        'chapters': chapters,
        'testament': testament,
      };
    }).toList();
  }

  // Não precisamos mais buscar contagem de capítulos; vem em getBooks
  Future<List<Map<String, dynamic>>> getChapterVerses(
    String translation,
    int bookId,
    int chapter,
  ) async {
    final t = translations[translation] ?? 'NVIPT';
    final uri = Uri.parse('$_base/get-text/$t/$bookId/$chapter/');
    final res = await http.get(uri);
    if (res.statusCode != HttpStatusCodes.ok) return [];
    final List data = json.decode(res.body) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {'verse': m['verse'], 'text': _stripHtml(m['text'] ?? '')};
    }).toList();
  }
}
