import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettingsRecord {
  const UserSettingsRecord({
    required this.alertsEnabled,
    required this.autoCallEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.preferredRadiusMeters,
    required this.onboardingCompleted,
    required this.safetyDisclaimerAccepted,
  });

  final bool alertsEnabled;
  final bool autoCallEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int preferredRadiusMeters;
  final bool onboardingCompleted;
  final bool safetyDisclaimerAccepted;

  factory UserSettingsRecord.fromMap(Map<String, dynamic> json) {
    return UserSettingsRecord(
      alertsEnabled: json['alerts_enabled'] as bool? ?? true,
      autoCallEnabled: json['auto_call_enabled'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      preferredRadiusMeters: (json['preferred_radius_meters'] as num?)?.toInt() ?? 500,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      safetyDisclaimerAccepted: json['safety_disclaimer_accepted'] as bool? ?? false,
    );
  }
}

class SettingsService {
  SettingsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserSettingsRecord> fetchCurrentSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const UserSettingsRecord(
        alertsEnabled: true,
        autoCallEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        preferredRadiusMeters: 500,
        onboardingCompleted: false,
        safetyDisclaimerAccepted: false,
      );
    }

    final rows = await _client.from('user_settings').select().eq('user_id', userId).limit(1);
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) {
      await _client.from('user_settings').upsert({'user_id': userId});
      return const UserSettingsRecord(
        alertsEnabled: true,
        autoCallEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        preferredRadiusMeters: 500,
        onboardingCompleted: false,
        safetyDisclaimerAccepted: false,
      );
    }
    return UserSettingsRecord.fromMap(list.first);
  }

  Future<void> saveCurrentSettings({
    required bool alertsEnabled,
    required bool autoCallEnabled,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required int preferredRadiusMeters,
    bool? onboardingCompleted,
    bool? safetyDisclaimerAccepted,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await _client.from('user_settings').upsert({
      'user_id': userId,
      'alerts_enabled': alertsEnabled,
      'auto_call_enabled': autoCallEnabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'preferred_radius_meters': preferredRadiusMeters,
      'onboarding_completed': onboardingCompleted,
      'safety_disclaimer_accepted': safetyDisclaimerAccepted,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> registerCurrentDevice({
    required String platform,
    required String deviceName,
    String? pushToken,
    String? appVersion,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    await _client.from('device_registrations').insert({
      'user_id': userId,
      'platform': platform,
      'device_name': deviceName,
      'push_token': pushToken,
      'app_version': appVersion,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }
}
