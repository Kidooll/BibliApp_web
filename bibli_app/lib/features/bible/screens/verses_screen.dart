import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/reading_plans/services/reading_plans_service.dart';

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
  final Set<int> _markedChapters = {};

  bool _loading = true;
  bool _autoAdvancing = false;
  double _fontScale = 1.0;
  int _chapter = 1;
  List<Map<String, dynamic>> _verses = [];

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
    final verses = await widget.service.getChapterVerses(
      widget.translation,
      widget.bookId,
      chapter,
    );
    if (!mounted) return;
    setState(() {
      _verses = verses;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text(
                  'Copiar',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () async {
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
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text(
                  'Compartilhar',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.share(
                    '${widget.bookName} $_chapter:$verseNumber\n\n$text',
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
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
                                    color: const Color(0xFFE15B5B),
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
}
