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

  // Normaliza nome de livros longos/variantes (ex.: Apocalipse)
  String _normalizeBookName(String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();

    // Normalizações específicas para NTLH e variantes longas
    const ntlhMap = {
      'primeira carta de paulo aos coríntios': '1 Coríntios',
      'segunda carta de paulo aos coríntios': '2 Coríntios',
      'primeira carta de paulo aos tessalonicenses': '1 Tessalonicenses',
      'segunda carta de paulo aos tessalonicenses': '2 Tessalonicenses',
      'primeira carta de paulo aos tesselonicenses': '1 Tessalonicenses',
      'segunda carta de paulo aos tesselonicenses': '2 Tessalonicenses',
    };
    if (ntlhMap.containsKey(lower)) {
      return ntlhMap[lower]!;
    }

    final apoc = RegExp(r'apocalipse|revelação\s+de\s+deus\s+a\s+joão',
        caseSensitive: false);
    if (apoc.hasMatch(lower)) return 'Apocalipse';
    // Remove parênteses e subtítulos
    var normalized = text.replaceAll(RegExp(r'\s*\(.*?\)'), '');
    normalized = normalized.split(':').first;
    // Colapsa espaços
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? text : normalized;
  }

  // Encurta nomes muito longos para evitar overflow em qualquer tela.
  String _shortenBookName(String name, {int maxChars = 22}) {
    if (name.length <= maxChars) return name;
    final idx = name.lastIndexOf(' ', maxChars);
    if (idx > 0) {
      return '${name.substring(0, idx)}...';
    }
    return '${name.substring(0, maxChars)}...';
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
      final String rawName = (m['name'] ?? '').toString();
      final String name = _normalizeBookName(rawName);
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
      return {
        'verse': m['verse'],
        'text': _stripHtml(m['text'] ?? ''),
        // pk é o ID do verso na API; usamos para fallback quando não há verse_id no Supabase.
        if (m.containsKey('pk')) 'pk': m['pk'],
        if (m.containsKey('id')) 'api_id': m['id'],
      };
    }).toList();
  }

  /// Formata nome para headers (ex.: VersesScreen), encurtando e inserindo quebra de linha.
  static String formatBookNameForHeader(String raw, {int maxChars = 18}) {
    final normalized = _normalizeBookNameStatic(raw);
    if (normalized.length <= maxChars) return normalized;
    final idx = normalized.lastIndexOf(' ', maxChars);
    if (idx > 0) {
      return '${normalized.substring(0, idx)}\n${normalized.substring(idx).trim()}';
    }
    return '${normalized.substring(0, maxChars)}...';
  }

  static String _normalizeBookNameStatic(String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();
    final apoc = RegExp(r'apocalipse|revelação\s+de\s+deus\s+a\s+joão',
        caseSensitive: false);
    if (apoc.hasMatch(lower)) return 'Apocalipse';

    // Normalizações específicas NTLH para cartas longas
    const ntlhMap = {
      'primeira carta de paulo aos coríntios': '1 Coríntios',
      'segunda carta de paulo aos coríntios': '2 Coríntios',
      'primeira carta de paulo aos tesselonicenses': '1 Tessalonicenses',
      'segunda carta de paulo aos tesselonicenses': '2 Tessalonicenses',
      'primeira carta de paulo aos tessalonicenses': '1 Tessalonicenses',
      'segunda carta de paulo aos tessalonicenses': '2 Tessalonicenses',
    };
    for (final entry in ntlhMap.entries) {
      if (lower == entry.key) return entry.value;
    }

    var normalized = text.replaceAll(RegExp(r'\s*\(.*?\)'), '');
    normalized = normalized.split(':').first;
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? text : normalized;
  }
}
