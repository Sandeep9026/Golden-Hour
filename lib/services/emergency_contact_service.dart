import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactService {
  EmergencyContactService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchContacts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final data = await _client
        .from('emergency_contacts')
        .select('id, contact_name, phone, relation, notify_on_sos, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> addContact({
    required String contactName,
    required String phone,
    required String relation,
    required bool notifyOnSos,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await _client.from('emergency_contacts').insert({
      'user_id': userId,
      'contact_name': contactName,
      'phone': phone,
      'relation': relation,
      'notify_on_sos': notifyOnSos,
    });
  }

  Future<void> deleteContact({
    required int id,
  }) async {
    await _client.from('emergency_contacts').delete().eq('id', id);
  }
}
