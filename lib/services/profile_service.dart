import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRecord {
  const ProfileRecord({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.isTrained,
    this.latitude,
    this.longitude,
    this.vehicleNumber,
  });

  final String id;
  final String fullName;
  final String phone;
  final String role;
  final bool isTrained;
  final double? latitude;
  final double? longitude;
  final String? vehicleNumber;

  factory ProfileRecord.fromMap(Map<String, dynamic> json) {
    return ProfileRecord(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'driver',
      isTrained: json['is_trained'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      vehicleNumber: json['vehicle_number'] as String?,
    );
  }
}

class ProfileService {
  ProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ProfileRecord?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final rows = await _client.from('profiles').select().eq('id', userId).limit(1);
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) {
      return null;
    }

    return ProfileRecord.fromMap(list.first);
  }

  Future<void> upsertCurrentProfile({
    required String fullName,
    required String phone,
    required String role,
    required bool isTrained,
    String? vehicleNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_trained': isTrained,
      'vehicle_number': vehicleNumber,
    });
  }

  Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    await _client.from('profiles').update({
      'latitude': latitude,
      'longitude': longitude,
    }).eq('id', userId);
  }
}
