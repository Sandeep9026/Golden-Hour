import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/alert_service.dart';
import '../services/profile_service.dart';
import 'incident_detail_screen.dart';

class DispatcherDashboardScreen extends StatefulWidget {
  const DispatcherDashboardScreen({
    super.key,
    required this.profile,
  });

  final ProfileRecord profile;

  @override
  State<DispatcherDashboardScreen> createState() => _DispatcherDashboardScreenState();
}

class _DispatcherDashboardScreenState extends State<DispatcherDashboardScreen> {
  final AlertService _alertService = AlertService();

  bool _loading = true;
  List<Map<String, dynamic>> _incidents = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final incidents = await _alertService.fetchRecentIncidents();
      if (!mounted) {
        return;
      }
      setState(() {
        _incidents = incidents;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load dispatcher incidents right now.';
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _alertService.updateIncidentStatus(id: id, status: status);
      await _loadIncidents();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incident marked as ${status.toUpperCase()}.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update incident status.')),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _incidents.where((incident) => incident['status'] != 'closed').length;
    final highCount = _incidents.where((incident) => incident['severity'] == 'high').length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIncidents,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0B6E4F)],
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
                                'Dispatcher Command Center',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.profile.fullName} - dispatcher',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.88),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DispatcherStat(title: 'Active', value: '$activeCount'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DispatcherStat(title: 'High Risk', value: '$highCount'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DispatcherStat(title: 'Total', value: '${_incidents.length}'),
                        ),
                      ],
                    ),
                  ],
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
                        'Operations Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This dashboard helps demonstrate dispatcher coordination, incident triage, and case lifecycle management for the project.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Incidents',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!),
                  ),
                )
              else if (_incidents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No incidents have been reported yet.'),
                  ),
                )
              else
                ..._incidents.map((incident) {
                  final status = (incident['status'] as String?) ?? 'reported';
                  final severity = (incident['severity'] as String?) ?? 'medium';
                  final assignedName = incident['assigned_responder_name'] as String?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Incident ${incident['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                _StatusPill(label: severity.toUpperCase(), color: _severityColor(severity)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Location: ${incident['latitude']}, ${incident['longitude']}',
                            ),
                            const SizedBox(height: 6),
                            Text('Status: ${status.toUpperCase()}'),
                            const SizedBox(height: 6),
                            Text('Responder: ${assignedName ?? 'Not assigned'}'),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => IncidentDetailScreen(
                                          incident: incident,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('View Details'),
                                ),
                                OutlinedButton(
                                  onPressed: status == 'reported'
                                      ? () => _updateStatus(incident['id'].toString(), 'acknowledged')
                                      : null,
                                  child: const Text('Acknowledge'),
                                ),
                                FilledButton(
                                  onPressed: status == 'closed'
                                      ? null
                                      : () => _updateStatus(incident['id'].toString(), 'closed'),
                                  child: const Text('Close Case'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFB42318);
      case 'low':
        return const Color(0xFF0B6E4F);
      default:
        return const Color(0xFFD97706);
    }
  }
}

class _DispatcherStat extends StatelessWidget {
  const _DispatcherStat({
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
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
