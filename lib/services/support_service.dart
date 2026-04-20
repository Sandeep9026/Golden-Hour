import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  SupportService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitRequest({
    required String category,
    required String subject,
    required String message,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await _client.from('support_requests').insert({
      'user_id': userId,
      'category': category,
      'subject': subject,
      'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final data = await _client
        .from('support_requests')
        .select('id, category, subject, message, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }
}
