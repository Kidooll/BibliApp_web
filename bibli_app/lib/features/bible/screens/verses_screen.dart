import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/reading_plans/services/reading_plans_service.dart';
import 'package:bibli_app/features/bookmarks/services/bookmarks_service.dart';

import '../services/bible_service.dart';

class VersesScreen extends StatefulWidget {
  final BibleService service;
  final String translation;
  final int bookId;
  final String bookName;
  final int initialChapter;
  final int chapterCount;
  final int? readingPlanId;
  final int? readingPlanBookId;
  final String? readingPlanBookName;

  const VersesScreen({
    super.key,
    required this.service,
    required this.translation,
    required this.bookId,
    required this.bookName,
    required this.initialChapter,
    required this.chapterCount,
    this.readingPlanId,
    this.readingPlanBookId,
    this.readingPlanBookName,
  });

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  final ScrollController _scrollController = ScrollController();
  final ReadingPlansService _readingPlansService =
      ReadingPlansService(Supabase.instance.client);
  final BookmarksService _bookmarksService =
      BookmarksService(Supabase.instance.client);
  final Set<int> _markedChapters = {};

  bool _loading = true;
  bool _autoAdvancing = false;
  double _fontScale = 1.0;
  int _chapter = 1;
  List<Map<String, dynamic>> _verses = [];
  Map<int, int> _verseIdsByNumber = {}; // verseNumber -> verseId (Supabase)
  final Set<int> _highlightedVerses = {};
  final Set<int> _noteVerses = {};
  final Map<int, String> _highlightColors = {};
  static const List<String> _highlightPalette = [
    '#FFF9C4', // amarelo
    '#FFE0E0', // vermelho
    '#C8E6C9', // verde
    '#BBDEFB', // azul
    '#E1BEE7', // roxo
    '#F8BBD0', // rosa
  ];

  String get _displayBookName =>
      BibleService.formatBookNameForHeader(widget.bookName, maxChars: 18);

  @override
  void initState() {
    super.initState();
    _chapter = widget.initialChapter;
    _loadChapter(_chapter);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter(int chapter) async {
    setState(() {
      _loading = true;
    });
    final versesFuture = widget.service.getChapterVerses(
      widget.translation,
      widget.bookId,
      chapter,
    );
    final verseIdsFuture = _loadVerseIds(chapter);

    final verses = await versesFuture;
    final verseIds = await verseIdsFuture;
    await _loadBookmarksForChapter(verseIds.values.toList());
    if (!mounted) return;
    setState(() {
      _verses = verses;
      _verseIdsByNumber = verseIds;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  Future<Map<int, int>> _loadVerseIds(int chapter) async {
    try {
      final rows = await Supabase.instance.client
          .from('verses')
          .select('id, verse_number')
          .eq('book_id', widget.bookId)
          .eq('chapter_number', chapter);
      final map = <int, int>{};
      for (final row in rows as List<dynamic>) {
        final verseNumber = (row['verse_number'] as num?)?.toInt();
        final verseId = (row['id'] as num?)?.toInt();
        if (verseNumber != null && verseId != null) {
          map[verseNumber] = verseId;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> _loadBookmarksForChapter(List<int> verseIds) async {
    try {
      _highlightedVerses.clear();
      _noteVerses.clear();
      _highlightColors.clear();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || verseIds.isEmpty) return;
      final rows = await Supabase.instance.client
          .from('bookmarks')
          .select('bookmark_type, verse_id, highlight_color')
          .eq('user_profile_id', user.id)
          .inFilter('verse_id', verseIds);
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final verseId = (map['verse_id'] as num?)?.toInt();
        final type = map['bookmark_type']?.toString();
        final color = map['highlight_color']?.toString();
        if (verseId == null) continue;
        if (type == 'highlight') {
          _highlightedVerses.add(verseId);
          if (color != null) {
            _highlightColors[verseId] = color;
          }
        } else if (type == 'note') {
          _noteVerses.add(verseId);
        }
      }
    } catch (_) {
      // ignora falha de carregamento
    }
  }

  Future<void> _maybeAdvanceChapter() async {
    if (_autoAdvancing || _loading) return;
    await _markChapterAsRead();
    if (_chapter >= widget.chapterCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você chegou ao fim do livro.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _autoAdvancing = true;
    final next = _chapter + 1;
    setState(() {
      _chapter = next;
    });
    try {
      await _loadChapter(next);
    } finally {
      _autoAdvancing = false;
    }
  }

  Future<void> _markChapterAsRead() async {
    final planId = widget.readingPlanId;
    final planBookId = widget.readingPlanBookId;
    final planBookName = widget.readingPlanBookName;
    if (planId == null ||
        (planBookId == null &&
            (planBookName == null || planBookName.trim().isEmpty))) {
      return;
    }
    if (_markedChapters.contains(_chapter)) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _readingPlansService.markChapterAsRead(
      userId: user.id,
      planId: planId,
      bookId: planBookId,
      bookName: planBookName,
      chapterNumber: _chapter,
    );
    _markedChapters.add(_chapter);
  }

  void _decreaseFont() {
    setState(() {
      _fontScale = (_fontScale - 0.1).clamp(0.9, 1.6);
    });
  }

  void _increaseFont() {
    setState(() {
      _fontScale = (_fontScale + 0.1).clamp(0.9, 1.6);
    });
  }

  Future<void> _showVerseActions({
    required int verseNumber,
    required String text,
  }) async {
    final verseId = _verseIdsByNumber[verseNumber];
    final currentColor = verseId != null ? _highlightColors[verseId] : null;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Opções do versículo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerencie destaques, notas e ações rápidas.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                if (verseId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6F5),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Destacar / Favoritar',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2F5E5B),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                final ok = await _bookmarksService.toggleHighlight(
                                  verseId: verseId,
                                  colorHex: '#FFF9C4',
                                );
                                await _loadBookmarksForChapter(
                                  _verseIdsByNumber.values.toList(),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'Favorito atualizado' : 'Não foi possível salvar',
                                    ),
                                  ),
                                );
                                setState(() {});
                              },
                              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                              label: const Text(
                                'Padrão',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _highlightPalette.map((hex) {
                            final selected = currentColor == hex;
                            return GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                final ok = await _bookmarksService.setHighlight(
                                  verseId: verseId,
                                  colorHex: hex,
                                );
                                await _loadBookmarksForChapter(
                                  _verseIdsByNumber.values.toList(),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'Verso destacado' : 'Não foi possível salvar',
                                    ),
                                  ),
                                );
                                setState(() {});
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _colorFromHex(hex) ?? Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: const Color(0xFF2F5E5B), width: 2)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (currentColor != null) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final ok = await _bookmarksService.removeHighlight(verseId);
                              await _loadBookmarksForChapter(
                                _verseIdsByNumber.values.toList(),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok ? 'Destaque removido' : 'Não foi possível remover',
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline, color: Color(0xFF2F5E5B)),
                            label: const Text(
                              'Remover destaque',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF2F5E5B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (verseId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.note_add_outlined, color: Color(0xFF2F5E5B)),
                      title: const Text(
                        'Adicionar nota',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Salve um comentário rápido para este verso',
                        style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7480)),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final note = await _promptNote();
                        if (note == null || note.trim().isEmpty) return;
                        final ok = await _bookmarksService.upsertNote(
                          verseId: verseId,
                          noteText: note,
                        );
                        await _loadBookmarksForChapter(
                          _verseIdsByNumber.values.toList(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Nota salva' : 'Não foi possível salvar a nota',
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          Navigator.pop(context);
                          await Clipboard.setData(ClipboardData(text: text));
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Versículo copiado'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF2F5E5B)),
                        label: const Text(
                          'Copiar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF2F5E5B),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Share.share(
                            '${widget.bookName} $_chapter:$verseNumber\n\n$text',
                          );
                        },
                        icon: const Icon(Icons.share_rounded, color: Color(0xFF2F5E5B)),
                        label: const Text(
                          'Compartilhar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF2F5E5B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptNote() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Adicionar nota',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Digite sua anotação...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_displayBookName $_chapter',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _decreaseFont,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'T',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _increaseFont,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'T',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF005954)),
                ),
              )
            else
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.extentAfter == 0) {
                      _maybeAdvanceChapter();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                    itemCount: _verses.length,
                    itemBuilder: (context, index) {
                      final v = _verses[index];
                      final numRaw = v['verse'] ?? (index + 1);
                      final num = numRaw is int ? numRaw : (index + 1);
                      final text = v['text'] ?? '';
                      final verseId = _verseIdsByNumber[num];
                      final isHighlighted =
                          verseId != null && _highlightedVerses.contains(verseId);
                      final hasNote =
                          verseId != null && _noteVerses.contains(verseId);
                      final colorHex = verseId != null
                          ? _highlightColors[verseId]
                          : null;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () =>
                            _showVerseActions(verseNumber: num, text: text),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18,
                                child: Text(
                                  '$num',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: isHighlighted
                                        ? _colorFromHex(colorHex) ??
                                            const Color(0xFFE15B5B)
                                        : const Color(0xFFE15B5B),
                                    fontSize: 12 * _fontScale,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13.5 * _fontScale,
                                    height: 1.6,
                                    color: const Color(0xFF9AA3AF),
                                  ),
                                ),
                              ),
                              if (hasNote || isHighlighted)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6, top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isHighlighted)
                                        Icon(
                                          Icons.bookmark,
                                          size: 16,
                                          color: _colorFromHex(colorHex) ??
                                              const Color(0xFF2F5E5B),
                                        ),
                                      if (hasNote) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.note,
                                          size: 16,
                                          color: Color(0xFF2F5E5B),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final sanitized = hex.replaceAll('#', '');
    if (sanitized.length == 6) {
      return Color(int.parse('FF$sanitized', radix: 16));
    }
    if (sanitized.length == 8) {
      return Color(int.parse(sanitized, radix: 16));
    }
    return null;
  }
}
