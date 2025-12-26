import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/services/server_time_service.dart';

class DevotionalAccessService {
  final SupabaseClient _supabase;

  DevotionalAccessService(this._supabase);

  Future<bool> canAccessDevotional({
    required int devotionalId,
    required DateTime publishedDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final serverDate = await ServerTimeService.getSaoPauloDate(_supabase);
    if (serverDate == null) return false;

    final publishedDateStr = _formatDate(publishedDate);
    if (publishedDateStr == serverDate) return true;
    if (publishedDateStr.compareTo(serverDate) > 0) return false;

    try {
      final res = await _supabase
          .from('read_devotionals')
          .select('id')
          .eq('user_profile_id', user.id)
          .eq('devotional_id', devotionalId)
          .eq('read_date', publishedDateStr)
          .limit(1)
          .timeout(const Duration(seconds: 8));
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
