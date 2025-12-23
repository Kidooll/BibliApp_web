import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../styles/styles.dart';

/// Cores disponíveis para destaque
const List<String> _highlightColors = [
  '#FFF9C4', // amarelo
  '#FFE0E0', // vermelho
  '#C8E6C9', // verde
  '#BBDEFB', // azul
  '#E1BEE7', // roxo
  '#F8BBD0', // rosa
];

/// Gerenciador de cache para destaques
class HighlightCache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static bool _isInitialized = false;

  /// Adiciona ou atualiza um highlight no cache
  static void updateHighlight(String key, Map<String, dynamic> highlight) {
    _cache[key] = Map<String, dynamic>.from(highlight);
  }

  /// Obtém um highlight do cache
  static Map<String, dynamic>? getHighlight(String key) {
    return _cache[key];
  }

  /// Remove um highlight do cache
  static void removeHighlight(String key) {
    _cache.remove(key);
  }

  /// Limpa todo o cache
  static void clear() {
    _cache.clear();
    _isInitialized = false;
  }

  /// Verifica se o cache foi inicializado
  static bool get isInitialized => _isInitialized;

  /// Marca o cache como inicializado
  static void markAsInitialized() {
    _isInitialized = true;
  }
}

/// Widget personalizado para exibir um círculo de progresso
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const CircleProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// Tween para animação de transição de cor
class HighlightColorTween extends Tween<Color?> {
  HighlightColorTween({Color? begin, Color? end})
      : super(begin: begin, end: end);

  @override
  Color? lerp(double t) => Color.lerp(begin, end, t);
}

// Adicione esta função RPC no seu banco de dados Supabase:
/*
create or replace function get_highlights_for_verse(p_verse_id bigint, p_user_profile_id uuid)
returns json as $$
  select json_agg(t) from (
    select * 
    from bookmarks 
    where 
      user_profile_id = p_user_profile_id 
      and bookmark_type = 'highlight'
      and verse_ids @> array[p_verse_id]::bigint[]
  ) t;
$$ language sql;
*/

/// Modal de ações para versículos da Bíblia
class VerseActionsModal extends StatefulWidget {
  final int verseId;
  final String text;
  final String? highlightColor;
  final VoidCallback onRefresh;

  const VerseActionsModal({
    super.key,
    required this.verseId,
    required this.text,
    required this.highlightColor,
    required this.onRefresh,
  });

  @override
  State<VerseActionsModal> createState() => _VerseActionsModalState();
}

/// Estado do modal de ações de versículo
class _VerseActionsModalState extends State<VerseActionsModal>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _currentHighlightColor;
  String?
      _lastSelectedColor; // Stores the previous highlight color for error recovery
  late final AnimationController _colorController;
  late final ColorTween _colorTween;

  // Chave para o cache do usuário atual
  String? get _cacheKey => _supabase.auth.currentUser?.id;

  // Chave única para o cache deste versículo
  String? get _verseCacheKey =>
      _cacheKey != null ? '${_cacheKey}_${widget.verseId}' : null;

  // Verifica se há um highlight ativo
  bool get _hasHighlight =>
      _currentHighlightColor != null && _currentHighlightColor!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentHighlightColor = widget.highlightColor;

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addStatusListener(_handleAnimationStatus);

    _colorTween = ColorTween();
    // Initialize animation
    _colorTween.animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _initializeHighlightState();
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildHighlightColors(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Inicializa o estado do highlight
  void _initializeHighlightState() {
    if (_verseCacheKey == null) return;

    _loadHighlightFromCache();
    _loadHighlightFromDatabase();
  }

  /// Carrega o highlight do cache
  void _loadHighlightFromCache() {
    if (_verseCacheKey == null) return;

    final cachedHighlight = HighlightCache.getHighlight(_verseCacheKey!);
    if (cachedHighlight != null && mounted) {
      setState(() {
        _currentHighlightColor = cachedHighlight['highlight_color'] as String?;
      });
    }
  }

  /// Carrega o highlight do banco de dados
  Future<void> _loadHighlightFromDatabase() async {
    if (_verseCacheKey == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase.rpc('get_highlights_for_verse', params: {
        'p_verse_id': widget.verseId,
        'p_user_profile_id': user.id
      }).maybeSingle();

      if (response != null) {
        final highlight = response;
        final highlightColor = highlight['highlight_color'] as String?;

        if (highlightColor != null && mounted) {
          setState(() {
            _currentHighlightColor = highlightColor;
            _colorController.value = 1.0;
          });

          // Atualiza o cache local
          HighlightCache.updateHighlight(_verseCacheKey!, highlight);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar highlight: $e');
    }
  }

  /// Atualiza o tween da cor para animação
  void _updateColorTween() {
    _colorTween.begin = _colorTween.end;
    _colorTween.end = _currentHighlightColor != null
        ? Color(int.parse(_currentHighlightColor!.substring(1, 7), radix: 16) +
            0xFF000000)
        : Colors.transparent;

    // Update the animation with the new tween values
    _colorTween.animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  /// Handles animation status changes
  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _colorController.value = 1.0;
      });
    }
  }

  /// Constrói o cabeçalho do modal
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ações do Versículo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Constrói a paleta de cores para destaque
  Widget _buildHighlightColors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destacar com cor',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _highlightColors.map((color) {
            final isSelected = _currentHighlightColor == color;
            return GestureDetector(
              onTap: () => _setHighlight(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(
                      int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).primaryColor, width: 2)
                      : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Constrói os botões de ação
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.share,
          label: 'Compartilhar',
          onPressed: _shareVerse,
        ),
        _buildActionButton(
          icon: Icons.copy,
          label: 'Copiar',
          onPressed: _copyToClipboard,
        ),
        if (_hasHighlight)
          _buildActionButton(
            icon: Icons.clear,
            label: 'Remover',
            onPressed: _removeHighlight,
          ),
      ],
    );
  }

  /// Constrói um botão de ação
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _removeHighlight() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final scaffold = ScaffoldMessenger.of(context);

      // Remove do cache local imediatamente
      if (_verseCacheKey != null) {
        HighlightCache.removeHighlight(_verseCacheKey!);
      }

      // Atualiza a UI
      if (mounted) {
        setState(() {
          _currentHighlightColor = null;
          _colorController.value = 0.0;
        });
      }

      // Remove do banco de dados
      await _performDatabaseUpdate('', user.id, null);

      // Atualiza a lista de versículos
      if (mounted) {
        widget.onRefresh();
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Destaque removido'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao remover destaque: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setHighlight(String hex) async {
    if (_isLoading) return;
    _isLoading = true;

    // Salva o estado anterior para possível rollback
    final previousColor = _currentHighlightColor;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final scaffold = ScaffoldMessenger.of(context);

      // Se clicou na mesma cor, remove o highlight
      if (hex == _currentHighlightColor) {
        await _removeHighlight();
        return;
      }

      // Atualiza a UI imediatamente
      if (mounted) {
        setState(() {
          _currentHighlightColor = hex;
          _colorController.value = 1.0;
        });
      }

      // Executa operações de rede em segundo plano sem bloquear a UI
      _processHighlightUpdate(hex, user.id, scaffold).catchError((e) {
        // Se der erro, reverte a cor
        if (mounted) {
          setState(() {
            _currentHighlightColor = previousColor;
            _lastSelectedColor = previousColor;
            _colorController.value = 1.0;
          });
          _showError('Erro ao destacar versículo: $e');
        }
      });
    } catch (e) {
      // Em caso de erro, reverte para a cor anterior
      if (mounted) {
        setState(() {
          _currentHighlightColor = previousColor;
          _colorController.value = 1.0;
        });
        _showError('Erro ao destacar versículo: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performDatabaseUpdate(
      String hex, String userId, dynamic existingHighlightId) async {
    try {
      // Se existe um highlight, atualiza. Senão, cria um novo.
      if (existingHighlightId != null) {
        await _supabase.from('bookmarks').update({
          'highlight_color': hex,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingHighlightId);
      } else {
        await _supabase.from('bookmarks').insert({
          'user_profile_id': userId,
          'verse_ids': [widget.verseId],
          'bookmark_type': 'highlight',
          'highlight_color': hex,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar banco de dados: $e');
      rethrow; // Propaga o erro para ser tratado pelo chamador
    }
  }

  /// Processa a atualização do destaque
  Future<void> _processHighlightUpdate(
      String hex, String userId, ScaffoldMessengerState scaffold) async {
    if (_verseCacheKey == null) return;

    final now = DateTime.now().toIso8601String();

    try {
      // Verifica se já existe um highlight para este versículo
      final existingHighlight = HighlightCache.getHighlight(_verseCacheKey!);
      final existingHighlightId = existingHighlight?['id'] as int?;

      // Atualiza o cache local imediatamente para feedback visual
      if (mounted) {
        final updatedHighlight = {
          'id': existingHighlightId,
          'user_profile_id': userId,
          'verse_ids': [widget.verseId],
          'bookmark_type': 'highlight',
          'highlight_color': hex,
          'created_at': existingHighlight?['created_at'] ?? now,
          'updated_at': now,
        };

        setState(() {
          _currentHighlightColor = hex;
          _colorController.value = 1.0;
        });

        // Atualiza o cache
        HighlightCache.updateHighlight(_verseCacheKey!, updatedHighlight);
      }

      // Executa a operação no banco de dados em segundo plano
      await _performDatabaseUpdate(hex, userId, existingHighlightId);

      // Atualiza a UI
      if (mounted) {
        widget.onRefresh();
        scaffold.showSnackBar(
          SnackBar(
            content:
                Text(hex.isEmpty ? 'Destaque removido' : 'Versículo destacado'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao processar destaque: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;

    final scaffold = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Texto copiado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareVerse() async {
    await Share.share(widget.text);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
