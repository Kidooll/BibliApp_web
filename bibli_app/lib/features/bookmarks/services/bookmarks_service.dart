import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';

/// Serviço para gerenciar favoritos/destaques/notas (tabela `bookmarks`).
class BookmarksService {
  final SupabaseClient _supabase;

  BookmarksService(this._supabase);

  /// Adiciona ou remove highlight de versículo. Se já existe, remove; senão insere com cor.
  Future<bool> toggleHighlight({
    required int verseId,
    String? colorHex,
  }) async {
    // Usa um amarelo claro padrão se não vier cor específica.
    final effectiveColor = colorHex?.trim().isNotEmpty == true ? colorHex : '#FFF9C4';
    try {
      LogService.debug(
        'toggleHighlight verseId=$verseId color=$effectiveColor',
        'BookmarksService',
      );
      final user = _supabase.auth.currentUser;
      if (user == null) {
        LogService.warning('toggleHighlight sem usuário logado', 'BookmarksService');
        return false;
      }

      final existing = await _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_profile_id', user.id)
          .eq('bookmark_type', 'highlight')
          .eq('verse_id', verseId)
          .maybeSingle();

      if (existing != null) {
        LogService.debug(
          'Highlight existente encontrado, removendo id=${existing['id']}',
          'BookmarksService',
        );
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('id', existing['id'] as int);
        return true;
      }

      LogService.debug('Inserindo highlight novo', 'BookmarksService');
      await _supabase.from('bookmarks').upsert(
        {
          'bookmark_type': 'highlight',
          'verse_id': verseId,
          'highlight_color': effectiveColor,
          'user_profile_id': user.id,
        },
        onConflict: 'user_profile_id,bookmark_type,verse_id',
      );
      try {
        await WeeklyChallengesService(_supabase).incrementByType('favorite');
      } catch (e, stack) {
        LogService.error('Erro ao registrar desafio semanal (favorite)', e, stack, 'BookmarksService');
      }
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao alternar highlight', e, stack, 'BookmarksService');
      return false;
    }
  }

  /// Define explicitamente um highlight (sempre insere/atualiza).
  Future<bool> setHighlight({
    required int verseId,
    required String colorHex,
  }) async {
    final effectiveColor = colorHex.trim().isNotEmpty ? colorHex : '#FFF9C4';
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        LogService.warning('setHighlight sem usuário logado', 'BookmarksService');
        return false;
      }
      await _supabase.from('bookmarks').upsert(
        {
          'bookmark_type': 'highlight',
          'verse_id': verseId,
          'highlight_color': effectiveColor,
          'user_profile_id': user.id,
        },
        onConflict: 'user_profile_id,bookmark_type,verse_id',
      );
      try {
        await WeeklyChallengesService(_supabase).incrementByType('favorite');
      } catch (e, stack) {
        LogService.error('Erro ao registrar desafio semanal (favorite)', e, stack, 'BookmarksService');
      }
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao definir highlight', e, stack, 'BookmarksService');
      return false;
    }
  }

  /// Remove um highlight específico (se existir).
  Future<bool> removeHighlight(int verseId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        LogService.warning('removeHighlight sem usuário logado', 'BookmarksService');
        return false;
      }
      await _supabase
          .from('bookmarks')
          .delete()
          .eq('user_profile_id', user.id)
          .eq('bookmark_type', 'highlight')
          .eq('verse_id', verseId);
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao remover highlight', e, stack, 'BookmarksService');
      return false;
    }
  }

  /// Cria ou atualiza uma nota para um versículo.
  Future<bool> upsertNote({
    int? verseId,
    required String noteText,
  }) async {
    if (noteText.trim().isEmpty) return false;
    try {
      LogService.debug(
        'upsertNote verseId=$verseId len=${noteText.length}',
        'BookmarksService',
      );
      final user = _supabase.auth.currentUser;
      if (user == null) {
        LogService.warning('upsertNote sem usuário logado', 'BookmarksService');
        return false;
      }

      // Se não foi informado verseId, apenas insere nota solta (sem vínculo).
      if (verseId == null) {
        LogService.debug('Inserindo nota sem verse_id', 'BookmarksService');
        await _supabase.from('bookmarks').insert({
          'bookmark_type': 'note',
          'note_text': noteText.trim(),
          'user_profile_id': user.id,
        });
        return true;
      }

      final existing = await _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_profile_id', user.id)
          .eq('bookmark_type', 'note')
          .eq('verse_id', verseId)
          .maybeSingle();

      if (existing != null) {
        LogService.debug('Nota existente encontrada id=${existing['id']}', 'BookmarksService');
        await _supabase.from('bookmarks').update({
          'note_text': noteText.trim(),
        }).eq('id', existing['id'] as int);
      } else {
        LogService.debug('Inserindo nota nova', 'BookmarksService');
        await _supabase.from('bookmarks').upsert(
          {
            'bookmark_type': 'note',
            'verse_id': verseId,
            'note_text': noteText.trim(),
            'user_profile_id': user.id,
          },
          onConflict: 'user_profile_id,bookmark_type,verse_id',
        );
      }
      try {
        await WeeklyChallengesService(_supabase).incrementByType('note');
      } catch (e, stack) {
        LogService.error('Erro ao registrar desafio semanal (note)', e, stack, 'BookmarksService');
      }
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao salvar nota', e, stack, 'BookmarksService');
      return false;
    }
  }

  /// Favorita ou desfavorita um devocional.
  Future<bool> toggleDevotionalFavorite(int devotionalId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final existing = await _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_profile_id', user.id)
          .eq('bookmark_type', 'devotional')
          .eq('devotional_id', devotionalId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('id', existing['id'] as int);
        return true;
      }

      await _supabase.from('bookmarks').insert({
        'bookmark_type': 'devotional',
        'devotional_id': devotionalId,
        'user_profile_id': user.id,
      });
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao favoritar devocional', e, stack, 'BookmarksService');
      return false;
    }
  }

  /// Lista bookmarks do usuário filtrando por tipo, com paginação opcional.
  Future<List<Map<String, dynamic>>> listBookmarks({
    String? type,
    int? limit,
    int? offset,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      PostgrestFilterBuilder<List<Map<String, dynamic>>> filter = _supabase
          .from('bookmarks')
          .select(
            '''
            id, bookmark_type, verse_id, devotional_id, note_text, highlight_color, created_at,
            verses(id, verse_number, chapter_number, book_id, books(name)),
            devotionals(id, title)
            ''',
          )
          .eq('user_profile_id', user.id);

      if (type != null) {
        filter = filter.eq('bookmark_type', type);
      }

      PostgrestTransformBuilder<List<Map<String, dynamic>>> query =
          filter.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final res = await query;
      return List<Map<String, dynamic>>.from(res);
    } catch (e, stack) {
      LogService.error('Erro ao listar bookmarks', e, stack, 'BookmarksService');
      return [];
    }
  }

  /// Remove um bookmark por id (do usuário atual).
  Future<bool> deleteBookmark(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('bookmarks')
          .delete()
          .eq('id', id)
          .eq('user_profile_id', user.id);
      return true;
    } catch (e, stack) {
      LogService.error('Erro ao deletar bookmark', e, stack, 'BookmarksService');
      return false;
    }
  }
}
