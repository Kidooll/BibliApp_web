import 'package:supabase_flutter/supabase_flutter.dart';

class ServerTimeService {
  static const String _rpcName = 'get_sp_date';

  static Future<String?> getSaoPauloDate(SupabaseClient client) async {
    try {
      final result = await client.rpc(_rpcName);
      if (result == null) return null;
      return result.toString().split('T').first;
    } catch (_) {
      return null;
    }
  }
}
