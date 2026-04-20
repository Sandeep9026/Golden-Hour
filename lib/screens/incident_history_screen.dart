import 'package:flutter/material.dart';

import '../services/alert_service.dart';
import 'incident_detail_screen.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final AlertService _alertService = AlertService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _incidents = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final incidents = await _alertService.fetchUserIncidentHistory();
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
        _error = 'Could not load incident history right now.';
      });
    }
  }

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Incident History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incident Timeline',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Review your previously reported accidents, their severity, and current case status.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                  child: Text('You have not reported any incidents yet.'),
                ),
              )
            else
              ..._incidents.map(
                (incident) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        'Incident ${incident['id'].toString().substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Severity: ${incident['severity'].toString().toUpperCase()}'),
                            const SizedBox(height: 4),
                            Text('Status: ${incident['status'].toString().toUpperCase()}'),
                            const SizedBox(height: 4),
                            Text('Created: ${incident['created_at']}'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IncidentDetailScreen(incident: incident),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
