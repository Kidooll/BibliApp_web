import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<void> favoritar(String devotionalId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_favorite_devotionals').upsert({
      'user_profile_id': userId,
      'devotional_id': devotionalId,
      'favorited_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> desfavoritar(String devotionalId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_favorite_devotionals')
        .delete()
        .match({'user_profile_id': userId, 'devotional_id': devotionalId});
  }

  Future<List<String>> listarFavoritos() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _client
        .from('user_favorite_devotionals')
        .select('devotional_id')
        .eq('user_profile_id', userId);

    return List<String>.from(res.map((e) => e['devotional_id']));
  }

  Future<List<Map<String, dynamic>>> listarNotasDoUsuario() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('bookmarks')
        .select()
        .eq('user_profile_id', userId)
        .eq('bookmark_type', 'note')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> criarOuAtualizarNota({
    required String? id,
    required String noteText,
    required String highlightColor,
    List<int>? verseIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = <String, dynamic>{
      'user_profile_id': userId,
      'bookmark_type': 'note',
      'note_text': noteText,
      'highlight_color': highlightColor.isNotEmpty ? highlightColor : null,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add verse_ids if provided
    if (verseIds != null && verseIds.isNotEmpty) {
      data['verse_ids'] = verseIds;
    }

    // Se for uma atualização, usa o ID existente
    if (id != null && id.isNotEmpty) {
      await _client
          .from('bookmarks')
          .update(data)
          .eq('id', int.tryParse(id) ?? 0);
    } else {
      // Se for uma nova nota, adiciona a data de criação
      data['created_at'] = DateTime.now().toIso8601String();
      await _client.from('bookmarks').insert(data);
    }
  }

  Future<void> deletarNota(String noteId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('bookmarks').delete().match({
      'id': noteId,
      'user_profile_id': userId,
    });
  }
}
