import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/bookmarks/services/bookmarks_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

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
    final verse = item['verses'] as Map<String, dynamic>?;
    final devo = item['devotionals'] as Map<String, dynamic>?;

    String title;
    String subtitle = '';
    if (type == 'devotional') {
      title = devo?['title']?.toString() ?? 'Devocional #${item['devotional_id']}';
      subtitle = 'Favorito';
    } else if (type == 'note') {
      final ref = _verseRef(verse) ?? 'Verso ${item['verse_id']}';
      title = 'Nota • $ref';
      subtitle = note ?? '';
    } else {
      final ref = _verseRef(verse) ?? 'Verso ${item['verse_id']}';
      title = ref;
      subtitle = colorHex != null ? 'Destaque $colorHex' : 'Favorito';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF6B7480),
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _typeChip(type, colorHex),
            const SizedBox(height: 6),
            if (createdAt.isNotEmpty)
              Text(
                createdAt,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF9AA3AF),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE15B5B)),
              onPressed: () async {
                final ok = await _service.deleteBookmark(item['id'] as int);
                if (ok) {
                  _load();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível remover'),
                    ),
                  );
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
    Color bg = const Color(0xFFE8EDF2);
    Color fg = const Color(0xFF425466);

    switch (type) {
      case 'note':
        label = 'Nota';
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF2F5E5B);
        break;
      case 'devotional':
        label = 'Devocional';
        bg = const Color(0xFFF2E8FF);
        fg = const Color(0xFF5E2F5C);
        break;
      default:
        label = 'Verso';
        if (colorHex != null) {
          bg = _parseColor(colorHex).withOpacity(0.28);
          fg = const Color(0xFF2F5E5B);
        }
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

  String? _verseRef(Map<String, dynamic>? verse) {
    if (verse == null) return null;
    final book = verse['books'] as Map<String, dynamic>?;
    final bookName = book?['name']?.toString();
    final chapter = (verse['chapter_number'] as num?)?.toInt();
    final number = (verse['verse_number'] as num?)?.toInt();
    if (bookName == null || chapter == null || number == null) return null;
    return '$bookName $chapter:$number';
  }

  Future<void> _addNoteManually() async {
    final tituloController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Nova nota',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
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
        const SnackBar(content: Text('Escreva o texto da nota.')),
      );
      return;
    }

    final composed = title.isNotEmpty ? '$title\n$noteText' : noteText;
    final ok = await _service.upsertNote(noteText: composed);
    if (!mounted) return;
    if (ok) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota adicionada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a nota')),
      );
    }
  }
}
