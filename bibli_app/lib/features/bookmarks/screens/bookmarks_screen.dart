import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/bookmarks/services/bookmarks_service.dart';
import 'package:bibli_app/features/bible/services/bible_service.dart';
import 'package:bibli_app/features/bible/screens/verses_screen.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/widgets/custom_snackbar.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _service = BookmarksService(Supabase.instance.client);
  String _filter = 'all';
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final type = _filter == 'all' ? null : _filter;
    final items = await _service.listBookmarks(type: type, limit: 50);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF2D2D2D),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F6F2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNoteManually,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.note_add_outlined, color: Colors.white),
        label: const Text(
          'Adicionar nota',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    const Text(
                      'Nenhum favorito encontrado.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF6B7480),
                      ),
                    )
                  else
                    ..._items.map(_buildItemCard),
                ],
              ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _filterChip('Todos', 'all'),
        const SizedBox(width: 8),
        _filterChip('Versos', 'highlight'),
        const SizedBox(width: 8),
        _filterChip('Notas', 'note'),
        const SizedBox(width: 8),
        _filterChip('Devocionais', 'devotional'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () {
        setState(() => _filter = value);
        _load();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F5E5B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3B5E5C),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final type = (item['bookmark_type'] ?? '').toString();
    final createdAt = item['created_at']?.toString().split('T').first ?? '';
    final note = item['note_text']?.toString();
    final colorHex = item['highlight_color']?.toString();
    final verseId = item['verse_id'];
    final devoId = item['devotional_id'];
    final bookName = item['book_name']?.toString();
    final chapter = item['chapter_number'];
    final verseNum = item['verse_number'];
    final verseText = item['verse_text']?.toString();

    String title;
    String subtitle = '';
    IconData icon;
    Color cardColor;
    
    if (type == 'devotional') {
      title = 'Devocional #$devoId';
      subtitle = 'Favorito';
      icon = Icons.auto_stories;
      cardColor = const Color(0xFFF2E8FF);
    } else if (type == 'note') {
      if (bookName != null && chapter != null && verseNum != null) {
        title = '$bookName $chapter:$verseNum';
      } else {
        title = verseId != null ? 'Verso #$verseId' : 'Nota';
      }
      subtitle = note ?? '';
      icon = Icons.note;
      cardColor = const Color(0xFFEAF2FF);
    } else {
      if (bookName != null && chapter != null && verseNum != null) {
        title = '$bookName $chapter:$verseNum';
      } else {
        title = 'Verso #$verseId';
      }
      subtitle = verseText ?? 'Destaque';
      icon = Icons.bookmark;
      cardColor = colorHex != null ? _parseColor(colorHex).withOpacity(0.15) : const Color(0xFFFFF9E6);
    }

    return GestureDetector(
      onTap: type == 'highlight' && bookName != null && chapter != null
          ? () => _navigateToVerse(bookName, chapter)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2F5E5B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3F3D),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF6B7480),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _typeChip(type, colorHex),
                      const Spacer(),
                      if (createdAt.isNotEmpty)
                        Text(
                          createdAt,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF9AA3AF),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE15B5B)),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await _service.deleteBookmark(item['id'] as int);
                if (!mounted) return;
                if (ok) {
                  await _load();
                  messenger.showSnackBar(CustomSnackBar.success('Removido'));
                } else {
                  messenger.showSnackBar(CustomSnackBar.error('Não foi possível remover'));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type, String? colorHex) {
    String label;
    Color bg;
    Color fg = const Color(0xFF2F5E5B);

    switch (type) {
      case 'note':
        label = 'Nota';
        bg = const Color(0xFFEAF2FF);
        break;
      case 'devotional':
        label = 'Devocional';
        bg = const Color(0xFFF2E8FF);
        break;
      default:
        label = 'Verso';
        bg = colorHex != null ? _parseColor(colorHex).withOpacity(0.28) : const Color(0xFFFFF9E6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    if (value.length == 8) {
      return Color(int.parse(value, radix: 16));
    }
    return const Color(0xFF2F5E5B);
  }

  Future<void> _navigateToVerse(String bookName, int chapter) async {
    try {
      final bibleService = BibleService();
      final books = await bibleService.getBooks('NVIPT');
      final book = books.cast<Map<String, dynamic>>().firstWhere(
        (b) => b['name'].toString().toLowerCase() == bookName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      
      if (book.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error('Livro não encontrado'),
        );
        return;
      }
      
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VersesScreen(
            service: bibleService,
            translation: 'NVIPT',
            bookId: book['id'] as int,
            bookName: book['name'] as String,
            initialChapter: chapter,
            chapterCount: book['chapters'] as int,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.error('Erro ao abrir versículo'),
      );
    }
  }

  Future<void> _addNoteManually() async {
    final tituloController = TextEditingController();
    final noteController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Nova nota',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                    hintText: 'Ex: Minha reflexão',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Texto da nota',
                    hintText: 'Escreva sua anotação',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final noteText = noteController.text.trim();
      final title = tituloController.text.trim();
      if (noteText.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error('Escreva o texto da nota.'),
        );
        return;
      }

      final composed = title.isNotEmpty ? '$title\n$noteText' : noteText;
      final ok = await _service.upsertNote(noteText: composed);
      if (!mounted) return;
      if (ok) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.success('Nota adicionada', icon: Icons.note_add),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error('Não foi possível salvar a nota'),
        );
      }
    } finally {
      tituloController.dispose();
      noteController.dispose();
    }
  }
}
