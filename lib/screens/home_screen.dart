import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/accident_detector.dart';
import '../services/alert_service.dart';
import '../services/profile_service.dart';
import 'accident_alert_screen.dart';
import 'about_safety_screen.dart';
import 'emergency_contacts_screen.dart';
import 'incident_history_screen.dart';
import 'notification_center_screen.dart';
import 'settings_screen.dart';
import 'support_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.profile,
  });

  final ProfileRecord profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AccidentDetectorService _detector = AccidentDetectorService();
  final AlertService _alertService = AlertService();
  final MapController _mapController = MapController();

  StreamSubscription<AccidentDetectionResult>? _crashSubscription;
  Position? _currentPosition;
  bool _tracking = false;
  bool _loadingLocation = true;
  bool _autoDial108 = true;
  bool _submittingSos = false;
  String _statusText = 'Fetching location...';
  String? _locationLabel;
  AccidentAlert? _latestAlert;
  List<Map<String, dynamic>> _nearbyAlerts = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _alertService.registerCurrentDevicePresence();
    await _refreshLocation();
    await _loadNearbyAlerts();
  }

  Future<void> _refreshLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final position = await _alertService.currentPosition();
      final place = await _alertService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = position;
        _locationLabel = place;
        _loadingLocation = false;
        _statusText = 'System ready. Crash monitoring is off.';
      });
      await ProfileService().updateCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        14,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingLocation = false;
        _statusText = 'Location unavailable. Check GPS and internet access.';
      });
    }
  }

  Future<void> _loadNearbyAlerts() async {
    final position = _currentPosition;
    if (position == null) {
      return;
    }

    try {
      final alerts = await _alertService.fetchNearbyActiveAlerts(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) {
        setState(() => _nearbyAlerts = alerts);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _nearbyAlerts = const []);
      }
    }
  }

  Future<void> _toggleCrashWatch() async {
    if (_tracking) {
      await _crashSubscription?.cancel();
      setState(() {
        _tracking = false;
        _statusText = 'Crash monitoring has been turned off.';
      });
      return;
    }

    setState(() {
      _tracking = true;
      _statusText = 'Phone sensors are monitoring for accidents...';
    });

    _crashSubscription = _detector.watchForAccident().listen(
      (result) async => _handleDetection(result, triggeredManually: false),
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _tracking = false;
          _statusText = error.toString();
        });
      },
    );
  }

  Future<void> _manualSOS() async {
    final position = _currentPosition ?? await _alertService.currentPosition();
    final result = _detector.buildManualTrigger(position);
    await _handleDetection(result, triggeredManually: true);
  }

  Future<void> _handleDetection(
    AccidentDetectionResult result, {
    required bool triggeredManually,
  }) async {
    setState(() {
      _submittingSos = true;
      _statusText = triggeredManually
          ? 'Submitting manual SOS...'
          : 'Possible crash detected. Generating alert...';
    });

    try {
      final alert = await _alertService.createAccidentAlert(
        detection: result,
        autoDialEnabled: _autoDial108,
      );
      await _alertService.notifyNearbyDrivers(
        latitude: result.latitude,
        longitude: result.longitude,
        severity: result.severity,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submittingSos = false;
        _latestAlert = alert;
        _statusText =
            'Alert created. Nearby responders and drivers have been notified.';
      });

      await _loadNearbyAlerts();

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccidentAlertScreen(alert: alert),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingSos = false;
        _statusText =
            'Could not create the alert. Please check your connection and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send SOS. Please try again.'),
        ),
      );
    }
  }

  void _showStatusDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(_statusText),
              const SizedBox(height: 18),
              const Text(
                'Tip: Use the Big Red Button for the fastest demo flow. Pull down on the screen any time to refresh location and alert data.',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    unawaited(_crashSubscription?.cancel());
    unawaited(_detector.dispose());
    unawaited(_alertService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = LatLng(
      _currentPosition?.latitude ?? 28.6139,
      _currentPosition?.longitude ?? 77.2090,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _refreshLocation();
            await _loadNearbyAlerts();
          },
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB42318), Color(0xFFD95D39), Color(0xFF0B6E4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Text(
                          'Golden Hour Control',
                          style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.profile.fullName} - ${widget.profile.role}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.88),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _locationLabel ?? 'Highway location unavailable',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AboutSafetyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SupportCenterScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EmergencyContactsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.contacts_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationCenterScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const IncidentHistoryScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history_rounded, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeaderStat(
                            title: 'Mode',
                            value: _tracking ? 'Monitoring' : 'Standby',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeaderStat(
                            title: 'Alerts',
                            value: _nearbyAlerts.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeaderStat(
                            title: 'Emergency',
                            value: _autoDial108 ? '108 On' : 'Manual',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.majorproject.goldenhour',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFFB42318),
                              size: 46,
                            ),
                          ),
                          ..._nearbyAlerts.map((alert) {
                            return Marker(
                              point: LatLng(
                                (alert['latitude'] as num).toDouble(),
                                (alert['longitude'] as num).toDouble(),
                              ),
                              width: 64,
                              height: 64,
                              child: const Icon(
                                Icons.warning_rounded,
                                color: Color(0xFFD97706),
                                size: 34,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monitor_heart_rounded,
                              color: Color(0xFFB42318),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_statusText)),
                            IconButton(
                              onPressed: _showStatusDetails,
                              icon: const Icon(Icons.info_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto-call 108'),
                        subtitle: const Text('Trigger emergency calling and GPS logging'),
                        value: _autoDial108,
                        onChanged: (value) => setState(() => _autoDial108 = value),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          widget.profile.role == 'first_aider'
                              ? Icons.medical_services_rounded
                              : Icons.directions_car_filled_rounded,
                        ),
                        title: Text(
                          widget.profile.role == 'first_aider'
                              ? 'Responder Mode Active'
                              : 'Driver Mode Active',
                        ),
                        subtitle: Text(
                          widget.profile.role == 'first_aider'
                              ? 'You can be dispatched to the nearest accident.'
                              : 'You can view nearby accidents and send an SOS.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loadingLocation ? null : _toggleCrashWatch,
                              icon: Icon(_tracking ? Icons.pause_circle : Icons.sensors),
                              label: Text(_tracking ? 'Stop Watch' : 'Start Watch'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _loadingLocation || _submittingSos ? null : _manualSOS,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB42318),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              icon: _submittingSos
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.sos),
                              label: Text(_submittingSos ? 'Sending SOS...' : 'Big Red Button'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Alert',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (_latestAlert == null)
                        const Text('No alert has been generated yet.')
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_latestAlert!.description),
                            const SizedBox(height: 8),
                            Text(
                              'Responder: ${_latestAlert!.assignedResponderName ?? 'Matching pending'}',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MiniStatusChip(
                                  icon: Icons.warning_amber_rounded,
                                  label: _latestAlert!.severity.label,
                                ),
                                const _MiniStatusChip(
                                  icon: Icons.schedule_rounded,
                                  label: 'Recently created',
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Alerts (500m)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (_nearbyAlerts.isEmpty)
                        const Text('There are no active nearby highway alerts right now.')
                      else
                        ..._nearbyAlerts.map(
                          (alert) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Severity: ${alert['severity']}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Distance: ${((alert['distance_meters'] as num?) ?? 0).toStringAsFixed(0)} m',
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB42318)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
