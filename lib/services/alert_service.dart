import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'accident_detector.dart';

class AccidentAlert {
  const AccidentAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.severity,
    required this.createdAt,
    this.assignedResponderName,
  });

  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final AccidentSeverity severity;
  final DateTime createdAt;
  final String? assignedResponderName;
}

class AlertService {
  AlertService({
    SupabaseClient? client,
    GeolocatorPlatform? geolocator,
    http.Client? httpClient,
  })  : _client = client ?? Supabase.instance.client,
        _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _httpClient = httpClient ?? http.Client();

  final SupabaseClient _client;
  final GeolocatorPlatform _geolocator;
  final http.Client _httpClient;
  WebSocketChannel? _channel;
  RealtimeChannel? _realtimeChannel;

  Stream<AccidentAlert> connectToAlertStream(String websocketUrl) {
    _channel?.sink.close();
    _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));

    return _channel!.stream.map((event) {
      final json = jsonDecode(event as String) as Map<String, dynamic>;
      return AccidentAlert(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Nearby accident detected',
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        severity: _severityFromString(json['severity'] as String? ?? 'medium'),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        assignedResponderName: json['assigned_responder_name'] as String?,
      );
    });
  }

  Stream<List<Map<String, dynamic>>> watchNearbyActiveAlerts({
    required double latitude,
    required double longitude,
    double radiusMeters = 500,
  }) async* {
    yield await fetchNearbyActiveAlerts(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    final controller = StreamController<List<Map<String, dynamic>>>();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _client.channel('public:accident_reports_live');
    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'accident_reports',
          callback: (_) async {
            final alerts = await fetchNearbyActiveAlerts(
              latitude: latitude,
              longitude: longitude,
              radiusMeters: radiusMeters,
            );
            if (!controller.isClosed) {
              controller.add(alerts);
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await _realtimeChannel?.unsubscribe();
    };

    yield* controller.stream;
  }

  Future<AccidentAlert> createAccidentAlert({
    required AccidentDetectionResult detection,
    required bool autoDialEnabled,
  }) async {
    final nearestResponder = await _findNearestResponder(
      detection.latitude,
      detection.longitude,
    );

    final insertPayload = {
      'reporter_id': _client.auth.currentUser?.id,
      'latitude': detection.latitude,
      'longitude': detection.longitude,
      'severity': detection.severity.label.toLowerCase(),
      'confidence_score': detection.confidence,
      'g_force': detection.gForce,
      'assigned_responder_id': nearestResponder?['id'],
      'status': 'reported',
      'camera_summary': 'Phone-camera severity estimate placeholder',
    };

    final inserted = await _client
        .from('accident_reports')
        .insert(insertPayload)
        .select('id, created_at')
        .single();

    await _insertIncidentUpdate(
      accidentReportId: inserted['id'].toString(),
      updateType: 'reported',
      message:
          'Accident reported at ${detection.latitude.toStringAsFixed(5)}, ${detection.longitude.toStringAsFixed(5)} with ${detection.severity.label.toLowerCase()} severity.',
    );

    if (autoDialEnabled) {
      await dialEmergency108(
        latitude: detection.latitude,
        longitude: detection.longitude,
        severity: detection.severity,
      );
    }

    return AccidentAlert(
      id: inserted['id'].toString(),
      title: 'Emergency alert generated',
      description:
          'Nearby responders have been notified. The 108 call flow has been triggered${nearestResponder == null ? ', and responder matching is still pending.' : '.'}',
      latitude: detection.latitude,
      longitude: detection.longitude,
      distanceMeters: 0,
      severity: detection.severity,
      createdAt: DateTime.parse(inserted['created_at'] as String),
      assignedResponderName: nearestResponder?['full_name'] as String?,
    );
  }

  Future<List<Map<String, dynamic>>> fetchNearbyActiveAlerts({
    required double latitude,
    required double longitude,
    double radiusMeters = 500,
  }) async {
    final data = await _client.rpc(
      'nearby_accident_alerts',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_meters': radiusMeters,
      },
    );

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> fetchRecentIncidents() async {
    final data = await _client
        .from('accident_reports')
        .select('id, latitude, longitude, severity, status, created_at, assigned_responder_id, profiles!accident_reports_assigned_responder_id_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(20);

    final rows = List<Map<String, dynamic>>.from(data as List);
    return rows.map((row) {
      final responder = row['profiles'] as Map<String, dynamic>?;
      return {
        ...row,
        'assigned_responder_name': responder?['full_name'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchUserIncidentHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final data = await _client
        .from('accident_reports')
        .select('id, latitude, longitude, severity, status, created_at')
        .eq('reporter_id', userId)
        .order('created_at', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> fetchIncidentUpdates({
    required String accidentReportId,
  }) async {
    final data = await _client
        .from('incident_updates')
        .select('id, update_type, message, created_at')
        .eq('accident_report_id', accidentReportId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> updateIncidentStatus({
    required String id,
    required String status,
  }) async {
    await _client.from('accident_reports').update({
      'status': status,
    }).eq('id', id);

    await _insertIncidentUpdate(
      accidentReportId: id,
      updateType: status == 'closed' ? 'closed' : 'acknowledged',
      message: 'Incident status updated to ${status.toUpperCase()}.',
    );
  }

  Future<void> addIncidentNote({
    required String accidentReportId,
    required String message,
  }) async {
    await _insertIncidentUpdate(
      accidentReportId: accidentReportId,
      updateType: 'note',
      message: message,
    );
  }

  Future<void> dialEmergency108({
    required double latitude,
    required double longitude,
    required AccidentSeverity severity,
  }) async {
    final message =
        'Highway accident detected at https://maps.google.com/?q=$latitude,$longitude with ${severity.label} severity.';
    await _sendEmergencyLog(message);

    final uri = Uri(scheme: 'tel', path: '108');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> notifyNearbyDrivers({
    required double latitude,
    required double longitude,
    required AccidentSeverity severity,
  }) async {
    await _client.from('driver_notifications').insert({
      'user_id': _client.auth.currentUser?.id,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.label.toLowerCase(),
      'message': 'Accident detected within 500 meters. Park safely and assist if possible.',
    });
  }

  Future<List<Map<String, dynamic>>> fetchMyNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final data = await _client
        .from('driver_notifications')
        .select('id, message, severity, latitude, longitude, read_at, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> markNotificationRead({
    required int id,
  }) async {
    await _client.from('driver_notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> registerCurrentDevicePresence() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'web';

    await _client.from('device_registrations').insert({
      'user_id': userId,
      'platform': platform,
      'device_name': kIsWeb ? 'Browser session' : describeEnum(defaultTargetPlatform),
      'app_version': 'phase-3',
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> _findNearestResponder(
    double latitude,
    double longitude,
  ) async {
    final responders = await _client.rpc(
      'nearest_first_aider',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
      },
    );

    final list = List<Map<String, dynamic>>.from(responders as List);
    return list.isEmpty ? null : list.first;
  }

  Future<String> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
      },
    );

    final response = await _httpClient.get(
      uri,
      headers: {'User-Agent': 'golden-hour-major-project'},
    );
    if (response.statusCode != 200) {
      return 'Unknown highway location';
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return payload['display_name'] as String? ?? 'Unknown highway location';
  }

  AccidentSeverity _severityFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':
        return AccidentSeverity.high;
      case 'low':
        return AccidentSeverity.low;
      default:
        return AccidentSeverity.medium;
    }
  }

  Future<void> _sendEmergencyLog(String message) async {
    await _client.from('emergency_call_logs').insert({
      'message': message,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> _insertIncidentUpdate({
    required String accidentReportId,
    required String updateType,
    required String message,
  }) async {
    await _client.from('incident_updates').insert({
      'accident_report_id': accidentReportId,
      'update_type': updateType,
      'message': message,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<Position> currentPosition() => _geolocator.getCurrentPosition();

  Future<void> dispose() async {
    await _channel?.sink.close();
    await _realtimeChannel?.unsubscribe();
    _httpClient.close();
  }
}
