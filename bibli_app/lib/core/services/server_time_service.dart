import 'package:supabase_flutter/supabase_flutter.dart';

class ServerTimeService {
  static const String _rpcName = 'get_sp_date';
  static const Duration _defaultTimeout = Duration(seconds: 5);

  static Future<String?> getSaoPauloDate(
    SupabaseClient client, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final result = await client.rpc(_rpcName).timeout(timeout);
      if (result == null) return null;
      return result.toString().split('T').first;
    } catch (_) {
      return null;
    }
  }
}
