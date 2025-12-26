import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/bible/services/bible_prefs.dart';
import 'package:bibli_app/features/bible/screens/verses_screen.dart';
import 'package:bibli_app/features/bible/services/bible_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/features/reading_plans/models/reading_plan.dart';
import 'package:bibli_app/features/reading_plans/services/reading_plans_service.dart';

class ReadingPlanDetailScreen extends StatefulWidget {
  final ReadingPlan plan;

  const ReadingPlanDetailScreen({super.key, required this.plan});

  @override
  State<ReadingPlanDetailScreen> createState() => _ReadingPlanDetailScreenState();
}

class _ReadingPlanDetailScreenState extends State<ReadingPlanDetailScreen> {
  final _service = ReadingPlansService(Supabase.instance.client);
  final _bibleService = BibleService();
  ReadingProgress? _progress;
  int _selectedDay = 1;
  Map<int, List<_PlanChapterItem>> _chaptersByDay = {};
  bool _rewardClaimed = false;
  bool _claimingReward = false;
  bool _loadingBibleBooks = false;
  Future<void>? _bibleBooksFuture;
  bool _openingChapter = false;
  List<Map<String, dynamic>> _bibleBooks = [];
  String _bibleBooksTranslation = 'NVIPT';

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadPlanChapters();
  }

  Future<void> _loadProgress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {});
    final progress = await _service.getPlanProgress(
      user.id,
      widget.plan.id,
      widget.plan.duration,
    );
    if (mounted) {
      setState(() {
        _progress = progress;
        _selectedDay = (progress?.currentDay ?? 1).clamp(1, widget.plan.duration);
        _rewardClaimed = progress?.rewardClaimed ?? false;
      });
    }
  }

  Future<void> _startPlan() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await _service.startPlan(user.id, widget.plan.id);
    await _loadProgress();
  }

  Future<void> _markDayAsRead(int day) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await _service.markDayAsRead(user.id, widget.plan.id, day);
    await _loadProgress();
  }

  Future<void> _claimReward() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _claimingReward) return;
    setState(() => _claimingReward = true);

    final xp = ReadingPlanRewards.xpForDuration(widget.plan.duration);
    final talents = ReadingPlanRewards.talentsForXp(xp);
    final success = await _service.claimPlanReward(
      userId: user.id,
      planId: widget.plan.id,
      xpAmount: xp,
      coinAmount: talents,
    );
    if (!mounted) return;
    setState(() {
      _claimingReward = false;
      if (success) {
        _rewardClaimed = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Recompensa resgatada com sucesso!'
              : 'Não foi possível resgatar a recompensa.',
        ),
      ),
    );
  }

  Future<void> _continueReading() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _openingChapter) return;
    setState(() => _openingChapter = true);
    final next = await _service.getNextUnreadChapter(user.id, widget.plan.id);
    if (!mounted) return;
    setState(() => _openingChapter = false);
    if (next == null) {
      final fallback = _findNextChapterFromLocal();
      if (fallback == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum capítulo pendente encontrado.'),
          ),
        );
        return;
      }
      final translation = await BiblePrefs.getTranslation();
      await _openChapter(
        bookName: fallback.bookName,
        bookId: fallback.bookId,
        chapter: fallback.chapterStart,
        translation: translation,
      );
      return;
    }
    setState(() => _selectedDay = next.dayNumber);
    final translation = await BiblePrefs.getTranslation();
    await _openChapter(
      bookName: next.bookName,
      bookId: next.bookId,
      chapter: next.chapterNumber,
      translation: translation,
    );
  }

  Future<void> _openChapter({
    required String bookName,
    required int? bookId,
    required int chapter,
    required String translation,
  }) async {
    final bibleBookId = await _bookIdForName(bookName, translation);
    final planBookId = bookId ?? await _resolvePlanBookId(bookName);
    if (bibleBookId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Livro não encontrado: $bookName'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VersesScreen(
          service: _bibleService,
          translation: translation,
          bookId: bibleBookId,
          bookName: bookName,
          initialChapter: chapter,
          chapterCount: _chapterCountForBook(bibleBookId),
          readingPlanId: widget.plan.id,
          readingPlanBookId: planBookId,
          readingPlanBookName: bookName,
        ),
      ),
    );
    await _loadProgress();
  }

  Future<int?> _bookIdForName(String bookName, String translation) async {
    await _ensureBibleBooks(translation);
    if (_bibleBooks.isEmpty) return null;
    final normalizedTarget = _normalizeBookName(bookName);
    for (final book in _bibleBooks) {
      final name = book['name']?.toString() ?? '';
      if (_normalizeBookName(name) == normalizedTarget) {
        return (book['id'] as num).toInt();
      }
    }
    for (final book in _bibleBooks) {
      final name = book['name']?.toString() ?? '';
      final normalized = _normalizeBookName(name);
      if (normalized.contains(normalizedTarget) ||
          normalizedTarget.contains(normalized)) {
        return (book['id'] as num).toInt();
      }
    }
    return null;
  }

  int _chapterCountForBook(int bookId) {
    for (final book in _bibleBooks) {
      final id = (book['id'] as num?)?.toInt();
      if (id == bookId) {
        return (book['chapters'] as num?)?.toInt() ?? 1;
      }
    }
    return 1;
  }

  Future<void> _ensureBibleBooks(String translation) async {
    if (_bibleBooks.isNotEmpty && _bibleBooksTranslation == translation) {
      return;
    }
    if (_bibleBooksFuture != null) {
      await _bibleBooksFuture;
      return;
    }
    _loadingBibleBooks = true;
    _bibleBooksFuture = _bibleService.getBooks(translation).then((books) {
      _bibleBooks = books;
      _bibleBooksTranslation = translation;
    }).whenComplete(() {
      _loadingBibleBooks = false;
      _bibleBooksFuture = null;
    });
    await _bibleBooksFuture;
  }

  Future<int?> _resolvePlanBookId(String bookName) async {
    try {
      final row = await Supabase.instance.client
          .from('books')
          .select('id, name')
          .ilike('name', bookName)
          .maybeSingle();
      if (row != null) {
        return (row['id'] as num?)?.toInt();
      }
      final fuzzy = await Supabase.instance.client
          .from('books')
          .select('id, name')
          .ilike('name', '%$bookName%')
          .maybeSingle();
      return (fuzzy?['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  String _normalizeBookName(String value) {
    var text = value.toLowerCase().trim();
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    map.forEach((key, replacement) {
      text = text.replaceAll(key, replacement);
    });
    text = text.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  _PlanChapterItem? _findNextChapterFromLocal() {
    if (_chaptersByDay.isEmpty) return null;
    final totalDays = widget.plan.duration;
    for (var day = 1; day <= totalDays; day += 1) {
      final chapters = _chaptersByDay[day];
      if (chapters == null || chapters.isEmpty) continue;
      final completed = _progress?.isDayCompleted(day) ?? false;
      if (!completed) {
        return chapters.first;
      }
    }
    return null;
  }

  Future<void> _loadPlanChapters() async {
    final fromDb = await _loadPlanChaptersFromDb();
    if (fromDb.isNotEmpty) {
      if (mounted) {
        setState(() => _chaptersByDay = fromDb);
      }
      return;
    }

    final asset = _assetForPlanTitle(widget.plan.title);
    if (asset == null) return;
    try {
      final raw = await rootBundle.loadString(asset);
      final data = json.decode(raw) as Map<String, dynamic>;
      final items = data['chapters'] as List<dynamic>? ?? [];
      final map = <int, List<_PlanChapterItem>>{};
      for (final item in items) {
        final entry = item as Map<String, dynamic>;
        final day = (entry['dia'] as num?)?.toInt();
        final bookName = entry['book_name']?.toString();
        final start = (entry['chapter_start'] as num?)?.toInt();
        final end = (entry['chapter_end'] as num?)?.toInt();
        if (day == null || bookName == null || start == null || end == null) {
          continue;
        }
        map.putIfAbsent(day, () => []);
        map[day]!.add(
          _PlanChapterItem(
            day: day,
            bookName: bookName,
            chapterStart: start,
            chapterEnd: end,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _chaptersByDay = map;
        });
      }
    } catch (_) {}
  }

  Future<Map<int, List<_PlanChapterItem>>> _loadPlanChaptersFromDb() async {
    try {
      final rows = await Supabase.instance.client
          .from('reading_plan_items')
          .select(
            'day_number, book_name, chapter_number, verses(book_id, chapter_number, books(id, name))',
          )
          .eq('reading_plan_id', widget.plan.id)
          .order('day_number', ascending: true)
          .order('chapter_number', referencedTable: 'verses', ascending: true);
      if (rows.isEmpty) {
        return {};
      }

      final grouped = <int, Map<String, _BookGroup>>{};
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final day = (map['day_number'] as num?)?.toInt();
        final verse = map['verses'] as Map<String, dynamic>?;
        final book = verse?['books'] as Map<String, dynamic>?;
        final bookName =
            map['book_name']?.toString() ?? book?['name']?.toString();
        final bookId = (verse?['book_id'] as num?)?.toInt();
        final chapter = (map['chapter_number'] as num?)?.toInt() ??
            (verse?['chapter_number'] as num?)?.toInt();
        if (day == null || bookName == null || chapter == null) {
          continue;
        }

        grouped.putIfAbsent(day, () => {});
        final key = bookId != null
            ? 'id:$bookId'
            : 'name:${_normalizeBookName(bookName)}';
        grouped[day]!.putIfAbsent(key, () => _BookGroup(bookName, bookId));
        grouped[day]![key]!.chapters.add(chapter);
      }

      final result = <int, List<_PlanChapterItem>>{};
      for (final entry in grouped.entries) {
        final day = entry.key;
        final items = <_PlanChapterItem>[];
        for (final bookEntry in entry.value.entries) {
          final group = bookEntry.value;
          final chapters = group.chapters.toList()..sort();
          items.addAll(
            _buildChapterRanges(day, group.name, group.bookId, chapters),
          );
        }
        result[day] = items;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  List<_PlanChapterItem> _buildChapterRanges(
    int day,
    String bookName,
    int? bookId,
    List<int> chapters,
  ) {
    if (chapters.isEmpty) return <_PlanChapterItem>[];
    final ranges = <_PlanChapterItem>[];
    var start = chapters.first;
    var end = chapters.first;
    for (var i = 1; i < chapters.length; i += 1) {
      final current = chapters[i];
      if (current == end + 1) {
        end = current;
      } else {
        ranges.add(
          _PlanChapterItem(
            day: day,
            bookName: bookName,
            bookId: bookId,
            chapterStart: start,
            chapterEnd: end,
          ),
        );
        start = current;
        end = current;
      }
    }
    ranges.add(
      _PlanChapterItem(
        day: day,
        bookName: bookName,
        bookId: bookId,
        chapterStart: start,
        chapterEnd: end,
      ),
    );
    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.plan.duration;
    final daysToShow = _daysToShow(totalDays);
    final isCompleted = (_progress?.percentage ?? 0) >= 100;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _circleIconButton(
                          icon: Icons.arrow_back,
                          iconSize: 32,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPlanHeader(),
                    const SizedBox(height: 16),
                    if (isCompleted) ...[
                      _buildCompletionCard(),
                      const SizedBox(height: 16),
                    ],
                    if (!isCompleted) ...[
                      _buildContinueButton(),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: Text(
                        'Dia $_selectedDay de $totalDays',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F5E5B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDaySelector(totalDays),
                    const SizedBox(height: 16),
                    if (_progress == null) _buildStartPlanButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final day = daysToShow[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildDayCard(day),
                  );
                },
                childCount: daysToShow.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    final iconAsset = _planIconAsset(widget.plan.title);
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: AssetImage('assets/images/reading_plans/card_fundo.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: iconAsset == null
                ? const Icon(
                    Icons.auto_stories,
                    color: Color(0xFF3B5E5C),
                    size: 36,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(iconAsset, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.plan.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F3F3D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.plan.description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF6B7480),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.plan.duration} dias de leitura',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3F3D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openingChapter ? null : _continueReading,
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Continuar leitura'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F5E5B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    final xp = ReadingPlanRewards.xpForDuration(widget.plan.duration);
    final talents = ReadingPlanRewards.talentsForXp(xp);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2F1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration, color: Color(0xFF2F5E5B)),
              SizedBox(width: 8),
              Text(
                'Parabéns! Plano concluído',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F3F3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Você terminou este plano. Aproveite sua recompensa!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF5F6A6A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                '$xp XP',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F5E5B),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.circle, size: 12, color: Color(0xFFD8B04E)),
              const SizedBox(width: 6),
              Text(
                '$talents Talentos',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F5E5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_rewardClaimed || _claimingReward) ? null : _claimReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F5E5B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                _rewardClaimed ? 'Recompensa resgatada' : 'Resgatar recompensas',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(int totalDays) {
    final window = _dayWindow(totalDays);
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.chevron_left,
          onTap: _selectedDay > 1
              ? () => setState(() => _selectedDay -= 1)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: window.length,
              itemBuilder: (context, index) {
                final day = window[index];
                final selected = day == _selectedDay;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2F5E5B)
                            : const Color(0xFFE6ECEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Dia $day',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF6B7480),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _circleIconButton(
          icon: Icons.chevron_right,
          onTap: _selectedDay < totalDays
              ? () => setState(() => _selectedDay += 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStartPlanButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _startPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F5E5B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Iniciar plano'),
      ),
    );
  }

  Widget _buildDayCard(int day) {
    final isCompleted = _progress?.isDayCompleted(day) ?? false;
    final chapters = _chaptersByDay[day] ?? [];
    final progress = isCompleted ? 1.0 : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/reading_plans/card_fundo.png',
              height: 64,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          _buildDayBadge(day),
          const SizedBox(height: 12),
          if (chapters.isEmpty)
            _buildChapterRow(
              day: day,
              title: 'Leitura do dia',
              completed: isCompleted,
              showDivider: false,
            )
          else
                ...chapters.asMap().entries.map(
                  (entry) => _buildChapterRow(
                    day: day,
                    title: _formatChapter(entry.value),
                    completed: isCompleted,
                    showDivider: entry.key != chapters.length - 1,
                    onTap: () async {
                      final translation = await BiblePrefs.getTranslation();
                      await _openChapter(
                        bookName: entry.value.bookName,
                        bookId: entry.value.bookId,
                        chapter: entry.value.chapterStart,
                        translation: translation,
                      );
                    },
                  ),
                ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _markDayAsRead(day),
              icon: const Icon(Icons.menu_book, size: 16),
              label: const Text('Marcar dia como lido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F5E5B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Progresso',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F5E5B),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE6ECEC),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F5E5B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterRow({
    required int day,
    required String title,
    required bool completed,
    required bool showDivider,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFF2F5E5B)
                      : const Color(0xFFE6ECEC),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: completed ? Colors.white : const Color(0xFF2F5E5B),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF1F3F3D),
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFF2F5E5B)
                      : const Color(0xFFE6ECEC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  completed ? Icons.check : Icons.remove,
                  size: 14,
                  color: completed ? Colors.white : const Color(0xFF6B7480),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 16),
      ],
    );
  }

  Widget _buildDayBadge(int day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2F5E5B)),
          const SizedBox(width: 6),
          Text(
            'Dia $day',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F5E5B),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2F5E5B)),
        ],
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, double iconSize = 18, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: const Color(0xFF3B5E5C)),
      ),
    );
  }

  String _formatChapter(_PlanChapterItem item) {
    if (item.chapterStart == item.chapterEnd) {
      return '${item.bookName} ${item.chapterStart}';
    }
    return '${item.bookName} ${item.chapterStart}-${item.chapterEnd}';
  }

  List<int> _daysToShow(int totalDays) {
    final days = <int>[];
    if (_selectedDay >= 1 && _selectedDay <= totalDays) {
      days.add(_selectedDay);
    }
    if (_selectedDay + 1 <= totalDays) {
      days.add(_selectedDay + 1);
    }
    return days;
  }

  List<int> _dayWindow(int totalDays) {
    if (totalDays <= 5) {
      return List<int>.generate(totalDays, (i) => i + 1);
    }
    var start = (_selectedDay - 2).clamp(1, totalDays - 4);
    var end = (start + 4).clamp(1, totalDays);
    if (end - start < 4) {
      start = (end - 4).clamp(1, totalDays);
    }
    return List<int>.generate(end - start + 1, (i) => start + i);
  }

  String? _assetForPlanTitle(String title) {
    final asset = _planAssets[title];
    if (asset != null) return asset;
    return null;
  }

  String? _planIconAsset(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('salmos')) {
      return 'assets/images/reading_plans/icon_03.png';
    }
    if (lower.contains('profetas')) {
      return 'assets/images/reading_plans/icon_05.png';
    }
    if (lower.contains('provérbios') || lower.contains('proverbios')) {
      return 'assets/images/reading_plans/icon_01.png';
    }
    if (lower.contains('evangelho') || lower.contains('evangelhos')) {
      return 'assets/images/reading_plans/icon_02.png';
    }
    if (lower.contains('gênesis') || lower.contains('genesis')) {
      return 'assets/images/reading_plans/icon_04.png';
    }
    return 'assets/images/reading_plans/icon_01.png';
  }
}

class _PlanChapterItem {
  final int day;
  final String bookName;
  final int? bookId;
  final int chapterStart;
  final int chapterEnd;

  _PlanChapterItem({
    required this.day,
    required this.bookName,
    this.bookId,
    required this.chapterStart,
    required this.chapterEnd,
  });
}

class _BookGroup {
  final String name;
  final int? bookId;
  final Set<int> chapters;

  _BookGroup(this.name, this.bookId) : chapters = <int>{};
}

const Map<String, String> _planAssets = {
  'Leitura Bíblica em 1 Ano': 'assets/reading_plans/leitura_anual.json',
  'Evangelhos em 30 Dias': 'assets/reading_plans/evangelhos.json',
  'Salmos em 75 Dias': 'assets/reading_plans/salmos.json',
  'Provérbios em 31 Dias': 'assets/reading_plans/proverbios.json',
  'Atos dos Apóstolos em 28 Dias': 'assets/reading_plans/atos_apostolos.json',
  'Cartas de Paulo em 60 Dias': 'assets/reading_plans/cartas_paulo.json',
  'Pentateuco em 90 Dias': 'assets/reading_plans/pentateuco.json',
  'Profetas Maiores em 45 Dias': 'assets/reading_plans/profetas_maiores.json',
  'Profetas Menores em 30 Dias': 'assets/reading_plans/profetas_menores.json',
  'História de Israel em 40 Dias': 'assets/reading_plans/historias_israel.json',
  'Sabedoria em 45 Dias': 'assets/reading_plans/sabedoria.json',
  'Apocalipse em 10 Dias': 'assets/reading_plans/apocalipse.json',
  'Vida de Jesus em 40 Dias': 'assets/reading_plans/vida_jesus.json',
  'Milagres de Jesus em 21 Dias': 'assets/reading_plans/milagres_jesus.json',
  'Parábolas em 30 Dias': 'assets/reading_plans/parabolas.json',
  'Mulheres da Bíblia em 30 Dias': 'assets/reading_plans/mulheres_biblia.json',
  'Homens da Bíblia em 30 Dias': 'assets/reading_plans/homens_biblia.json',
  'Famílias da Bíblia em 30 Dias': 'assets/reading_plans/familias_biblia.json',
  'Liderança Bíblica em 30 Dias': 'assets/reading_plans/lideranca_biblica.json',
};
