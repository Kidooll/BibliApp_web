import 'package:flutter/material.dart';
import 'package:bibli_app/features/bible/services/bible_service.dart';
import 'package:share_plus/share_plus.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleService _service = BibleService();

  String _translation = 'NVIPT';
  List<Map<String, dynamic>> _books = [];
  int? _selectedBookId;
  String? _selectedBookName;
  int _chapterCount = 0;
  int? _selectedChapter;
  List<Map<String, dynamic>> _verses = [];
  bool _loading = true;

  // UI: abas e busca
  bool _showOldTestament = true; // true=AT, false=NT
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  double _fontScale = 1.0;
  void _decreaseFont() {
    setState(() {
      _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6);
    });
  }

  void _increaseFont() {
    setState(() {
      _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    final books = await _service.getBooks(_translation);
    setState(() {
      _books = books;
      _selectedBookId = null;
      _selectedBookName = null;
      _chapterCount = 0;
      _selectedChapter = null;
      _verses = [];
      _loading = false;
    });
  }

  Future<void> _selectBook(int id, String name, int chapters) async {
    setState(() {
      _selectedBookId = id;
      _selectedBookName = name;
      _selectedChapter = null;
      _verses = [];
      _chapterCount = chapters;
    });
  }

  Future<void> _selectChapter(int chapter) async {
    final id = _selectedBookId;
    if (id == null) return;
    setState(() {
      _selectedChapter = chapter;
      _loading = true;
    });
    final verses = await _service.getChapterVerses(_translation, id, chapter);
    setState(() {
      _verses = verses;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _filteredBooks() {
    List<Map<String, dynamic>> list = _books;

    // Filtrar por testamento se info existir
    list = list.where((b) {
      final testament = (b['testament'] ?? b['group'] ?? '')
          .toString()
          .toUpperCase();
      final isOT =
          testament.contains('OLD') ||
          testament.contains('OT') ||
          testament.contains('ANTIGO');
      final isNT =
          testament.contains('NEW') ||
          testament.contains('NT') ||
          testament.contains('NOVO');
      if (_showOldTestament) {
        return isOT || (!isOT && !isNT); // se não houver info, exibe por padrão
      } else {
        return isNT || (!isOT && !isNT);
      }
    }).toList();

    // Filtro por busca
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final abbr = (b['abbrev'] ?? b['abbreviation'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(q) || abbr.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFF005954), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Bíblia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _translation,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'NVIPT', child: Text('NVIPT')),
                    DropdownMenuItem(value: 'NAA', child: Text('NAA')),
                    DropdownMenuItem(value: 'NTLH', child: Text('NTLH')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _translation = v);
                    await _loadBooks();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Abas AT/NT
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showOldTestament = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showOldTestament
                            ? const Color(0xFF005954)
                            : const Color(0xFFE9EEEE),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Antigo Testamento',
                        style: TextStyle(
                          color: _showOldTestament
                              ? Colors.white
                              : const Color(0xFF2D2D2D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showOldTestament = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showOldTestament
                            ? const Color(0xFF005954)
                            : const Color(0xFFE9EEEE),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Novo Testamento',
                        style: TextStyle(
                          color: !_showOldTestament
                              ? Colors.white
                              : const Color(0xFF2D2D2D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Digite o nome do livro',
                filled: true,
                fillColor: const Color(0xFFE9EEEE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF005954),
                      ),
                    )
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedBookId == null) {
      final books = _filteredBooks();
      return ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          final name = (book['name'] ?? '').toString();
          final id = (book['id'] as num).toInt();
          final chapters = (book['chapters'] as num).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCD3D3)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.menu_book_outlined,
                color: Color(0xFF005954),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _selectBook(id, name, chapters),
            ),
          );
        },
      );
    }

    if (_selectedChapter == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedBookId = null;
                  _selectedBookName = null;
                  _chapterCount = 0;
                }),
              ),
              Text(
                _selectedBookName ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_chapterCount Capítulos',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _chapterCount,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCCD3D3)),
                  ),
                  child: ListTile(
                    title: Text(
                      'Capítulo $chapter',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _selectChapter(chapter),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _selectedChapter = null;
                _verses = [];
              }),
            ),
            Expanded(
              child: Text(
                '${_selectedBookName ?? ''} ${_selectedChapter ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _decreaseFont,
                  tooltip: 'Diminuir fonte',
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: _increaseFont,
                  tooltip: 'Aumentar fonte',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _verses.length,
            itemBuilder: (context, index) {
              final v = _verses[index];
              final num = v['verse'] ?? v['number'] ?? (index + 1);
              final text = v['text'] ?? v['content'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$num',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFFB46E5A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: const Color(0xFF6B7480),
                          height: 1.6,
                          fontSize: 16 * _fontScale,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'copy') {
                          await Share.share(text);
                        } else if (value == 'share') {
                          await Share.share(text);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'copy', child: Text('Copiar')),
                        PopupMenuItem(
                          value: 'share',
                          child: Text('Compartilhar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
