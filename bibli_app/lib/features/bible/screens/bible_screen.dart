import 'package:flutter/material.dart';
import 'package:bibli_app/features/bible/services/bible_service.dart';
import 'package:bibli_app/features/bible/screens/chapters_screen.dart';
import 'package:bibli_app/features/missions/services/missions_service.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleService _service = BibleService();
  late MissionsService _missionsService;
  late WeeklyChallengesService _weeklyService;

  String _translation = 'NVIPT';
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  // UI: abas e busca
  bool _showOldTestament = true; // true=AT, false=NT
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _missionsService = MissionsService(Supabase.instance.client);
    _weeklyService = WeeklyChallengesService(Supabase.instance.client);
    _loadBooks();
    _registerBibleMission();
  }

  Future<void> _registerBibleMission() async {
    try {
      await _missionsService.completeMissionByCode('open_bible');
      await _weeklyService.incrementByType('reading', step: 1);
    } catch (_) {
      // Silenciar para não quebrar a UI de leitura
    }
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    final books = await _service.getBooks(_translation);
    setState(() {
      _books = books;
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
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        (user?.userMetadata?['name'] ?? user?.email ?? 'Usuário').toString();
    final initials = _getInitials(displayName);
    final avatarUrl =
        (user?.userMetadata?['avatar_url'] ??
                user?.userMetadata?['picture'] ??
                '')
            .toString();

    return SafeArea(
      child: Container(
        color: const Color(0xFFF8F6F2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0E0E0),
                    backgroundImage: avatarUrl.trim().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.trim().isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bíblia',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF2F2F2),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: DropdownButton<String>(
                      value: _translation,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NVIPT', child: Text('NVI PT')),
                        DropdownMenuItem(value: 'NAA', child: Text('NAA')),
                        DropdownMenuItem(value: 'NTLH', child: Text('NTLH')),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _translation = v);
                        await _loadBooks();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Abas AT/NT
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showOldTestament = true),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _showOldTestament
                                ? const Color(0xFF1F5C57)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Antigo Testamento',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: _showOldTestament
                                  ? Colors.white
                                  : const Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showOldTestament = false),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: !_showOldTestament
                                ? const Color(0xFF1F5C57)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Novo Testamento',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: !_showOldTestament
                                  ? Colors.white
                                  : const Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Busca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Digite o nome do livro',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w700,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),

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
      ),
    );
  }

  Widget _buildContent() {
    final books = _filteredBooks();
    if (books.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum livro encontrado',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF6B7480),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final name = (book['name'] ?? '').toString();
        final id = (book['id'] as num).toInt();
        final chapters = (book['chapters'] as num).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChaptersScreen(
                    service: _service,
                    translation: _translation,
                    bookId: id,
                    bookName: name,
                    chapterCount: chapters,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    final initials = '$first$last';
    return initials.isNotEmpty ? initials : 'U';
  }
}
