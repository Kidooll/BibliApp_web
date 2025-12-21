import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/config.dart';

class BibleService {
  String _normalizeBase(String base) {
    var normalized = base.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

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
    final base = _normalizeBase(AppConfig.bollsApiUrl);
    final uri = Uri.parse('$base/get-books/$t/');
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
    final base = _normalizeBase(AppConfig.bollsApiUrl);
    final uri = Uri.parse('$base/get-text/$t/$bookId/$chapter/');
    final res = await http.get(uri);
    if (res.statusCode != HttpStatusCodes.ok) return [];
    final List data = json.decode(res.body) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {'verse': m['verse'], 'text': _stripHtml(m['text'] ?? '')};
    }).toList();
  }
}
